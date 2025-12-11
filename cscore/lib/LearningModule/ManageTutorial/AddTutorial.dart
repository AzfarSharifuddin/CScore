import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class AddTutorialPage extends StatefulWidget {
  const AddTutorialPage({super.key});

  @override
  State<AddTutorialPage> createState() => _AddTutorialPageState();
}

class _AddTutorialPageState extends State<AddTutorialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? selectedSubtopic;

  bool _useUrl = false;
  String? _urlValue;

  PlatformFile? _pickedFile;
  File? _localFile;

  bool _isUploading = false;
  double _progress = 0.0;

  // 20 MB limit
  static const int maxBytes = 20 * 1024 * 1024;

  @override
  void dispose() {
    VideoCompress.cancelCompression();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<String>> _fetchSubtopics() async {
    final snap = await FirebaseFirestore.instance.collection("tutorial").get();
    return snap.docs.map((e) => e.id).toList();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result == null) return;

    _pickedFile = result.files.single;
    _localFile = File(_pickedFile!.path!);
    setState(() {});
  }

  String _detectType(String name) {
    final ext = name.split('.').last.toLowerCase();

    if (['mp4', 'mov', 'mkv', 'avi', 'webm'].contains(ext)) return 'video';
    if (['pdf'].contains(ext)) return 'pdf';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    return ext;
  }

  Future<Uint8List?> _compressImage(File file) {
    return FlutterImageCompress.compressWithFile(file.path, quality: 75);
  }

  Future<File?> _compressVideo(File file) async {
    try {
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
      );
      return compressed?.file;
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // STORAGE UPLOAD
  // ---------------------------------------------------------------------------

  /// Uploads raw file bytes to Storage under a canonical name.
  /// For video:  tutorial_files/<subtopic>/video_<ts>.mp4
  /// For others: tutorial_files/<subtopic>/file_<ts>.<ext>
  Future<String> _uploadToStorage({
    required String subtopic,
    required Uint8List data,
    required String contentType,
    required bool isVideo,
    required String originalName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    late final String baseName;
    if (isVideo) {
      baseName = "video_$timestamp.mp4";
    } else {
      final ext = p.extension(originalName).toLowerCase();
      final safeExt = ext.isEmpty ? ".bin" : ext;
      baseName = "file_$timestamp$safeExt";
    }

    final storagePath = "tutorial_files/$subtopic/$baseName";
    final ref = FirebaseStorage.instance.ref(storagePath);

    final uploadTask = ref.putData(
      data,
      SettableMetadata(contentType: contentType),
    );

    uploadTask.snapshotEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _progress = event.totalBytes == 0
            ? 0
            : event.bytesTransferred / event.totalBytes;
      });
    });

    final snap = await uploadTask;

    // Return the *storage path* (not URL) so we can derive processed name
    return snap.ref.fullPath; // e.g. tutorial_files/CSS/video_123456789.mp4
  }

  /// Waits until Cloud Function writes `<baseName>__processed.mp4`
  /// and returns the *download URL* of that processed video.
  Future<String> _waitForProcessedVideo(String originalStoragePath) async {
    // originalStoragePath: tutorial_files/CSS/video_123456789.mp4
    final dir = p.dirname(originalStoragePath); // tutorial_files/CSS
    final base = p.basename(originalStoragePath); // video_123456789.mp4

    // This must match your Cloud Function naming:
    // processed = base.replaceFirst('.mp4', '__processed.mp4');
    final processedBase = base.replaceFirst(".mp4", "_processed.mp4");
    final processedPath = "$dir/$processedBase";

    final processedRef = FirebaseStorage.instance.ref(processedPath);

    // Poll up to ~60 seconds (30 x 2s)
    for (int i = 0; i < 150; i++) {
      try {
        return await processedRef.getDownloadURL();
      } catch (_) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception("Processed video not found after waiting.");
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSubtopic == null) {
      _showSnack("Select a subtopic");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("You must be logged in");
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection("user").doc(user.uid).get();

    if (!userDoc.exists || userDoc["role"] != "Teacher") {
      _showSnack("Only teachers can upload");
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileUrl = "";
      String fileType = "unknown";

      // ---------------------------------------------------------- URL MODE
      if (_useUrl) {
        if (_urlValue == null || _urlValue!.isEmpty) {
          _showSnack("Enter URL");
          return;
        }

        fileUrl = _urlValue!;
        fileType = _detectType(fileUrl);
      }

      // ---------------------------------------------------------- FILE MODE
      else {
        if (_pickedFile == null || _localFile == null) {
          _showSnack("Pick a file");
          return;
        }

        final fileName = _pickedFile!.name;
        fileType = _detectType(fileName);

        Uint8List? bytes;
        File file = _localFile!;
        int size = file.lengthSync();

        // Compress if needed
        if (size > maxBytes) {
          if (fileType == "video") {
            final compressed = await _compressVideo(file);
            if (compressed == null || compressed.lengthSync() > maxBytes) {
              throw Exception("Video too large after compression.");
            }
            file = compressed;
          } else {
            bytes = await _compressImage(file);
            if (bytes == null || bytes.lengthInBytes > maxBytes) {
              throw Exception("Image too large after compression.");
            }
          }
        }

        bytes ??= await file.readAsBytes();

        final isVideo = fileType == "video";
        final contentType = isVideo
            ? "video/mp4"
            : (lookupMimeType(fileName) ?? "application/octet-stream");

        // 1. Upload raw file, get its storage path
        final storagePath = await _uploadToStorage(
          subtopic: selectedSubtopic!,
          data: bytes,
          contentType: contentType,
          isVideo: isVideo,
          originalName: fileName,
        );

        // 2. If video → wait for processed version, else use raw URL
        if (isVideo) {
          fileUrl = await _waitForProcessedVideo(storagePath);
        } else {
          fileUrl =
              await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
        }
      }

      // ---------------------------------------------------------- Save to Firestore
      await FirebaseFirestore.instance
          .collection("tutorial")
          .doc(selectedSubtopic)
          .collection("files")
          .add({
        "fileName": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "fileType": fileType,
        "fileUrl": fileUrl, // processed URL for videos
        "uploadedBy": user.uid,
        "teacherName": userDoc["name"],
        "modifiedDate": FieldValue.serverTimestamp(),
      });

      _showSnack("Upload successful");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack("Upload failed: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI (UNCHANGED)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Tutorial"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder(
        future: _fetchSubtopics(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subtopics = snap.data as List<String>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Subtopic",
                      border: OutlineInputBorder(),
                    ),
                    items: subtopics
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    value: selectedSubtopic,
                    onChanged: (v) => setState(() => selectedSubtopic = v),
                    validator: (v) => v == null ? "Select a subtopic" : null,
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text("Upload via URL"),
                    value: _useUrl,
                    onChanged: (v) => setState(() => _useUrl = v),
                  ),
                  if (_useUrl)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "File URL",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => _urlValue = v,
                    )
                  else
                    Column(
                      children: [
                        _pickedFile == null
                            ? ElevatedButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text("Pick File"),
                              )
                            : ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(_pickedFile!.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() {
                                    _pickedFile = null;
                                    _localFile = null;
                                  }),
                                ),
                              ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _progress),
                        const SizedBox(height: 10),
                        const Text("Uploading..."),
                      ],
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _submit,
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                        _useUrl ? "Add (URL)" : "Upload & Add Tutorial"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
