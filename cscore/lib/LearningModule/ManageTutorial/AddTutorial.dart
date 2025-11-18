import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  static const int maxBytes = 20 * 1024 * 1024;

  @override
  void dispose() {
    VideoCompress.cancelCompression();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------
  // Fetch existing subtopics for dropdown
  // --------------------------------------------------------------
  Future<List<String>> _fetchSubtopics() async {
    final snap = await FirebaseFirestore.instance.collection("tutorial").get();

    return snap.docs.map((e) => e.id).toList();
  }

  // --------------------------------------------------------------
  // PICK FILE
  // --------------------------------------------------------------
  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (res == null) return;

    _pickedFile = res.files.single;
    _localFile = File(_pickedFile!.path!);

    setState(() {});
  }

  // --------------------------------------------------------------
  // FILE TYPE DETECTION
  // --------------------------------------------------------------
  String detectType(String name) {
    final ext = name.split('.').last.toLowerCase();

    if (['pdf'].contains(ext)) return 'pdf';
    if (['mp4', 'mov', 'mkv', 'avi', 'webm'].contains(ext)) return 'video';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    return ext;
  }

  // --------------------------------------------------------------
  // IMAGE COMPRESSION
  // --------------------------------------------------------------
  Future<Uint8List?> compressImage(File file) async {
    return await FlutterImageCompress.compressWithFile(file.path, quality: 75);
  }

  // --------------------------------------------------------------
  // VIDEO COMPRESSION
  // --------------------------------------------------------------
  Future<File?> compressVideo(File file) async {
    try {
      final compressed = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
      );
      return compressed?.file;
    } catch (e) {
      return null;
    }
  }

  // --------------------------------------------------------------
  // FIREBASE STORAGE UPLOAD
  // --------------------------------------------------------------
  Future<String> uploadToFirebaseStorage(
    String subtopic,
    String rawName,
    Uint8List data,
    String contentType,
  ) async {
    final safeName = rawName.replaceAll(RegExp(r'[^\w\.-]'), "_");
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final ext = p.extension(rawName);
    final path = "tutorial_files/$subtopic/${safeName}_$timestamp$ext";

    final ref = FirebaseStorage.instance.ref(path);

    final uploadTask = ref.putData(
      data,
      SettableMetadata(contentType: contentType),
    );

    uploadTask.snapshotEvents.listen((event) {
      setState(() {
        _progress = event.bytesTransferred / event.totalBytes;
      });
    });

    final snap = await uploadTask;
    final url = await snap.ref.getDownloadURL();
    return url;
  }

  // --------------------------------------------------------------
  // UPLOAD BUTTON PRESSED
  // --------------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSubtopic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select a subtopic")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must be logged in")));
      return;
    }

    // Check role
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists || doc["role"] != "Teacher") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only teachers are allowed to upload materials"),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileUrl = "";
      String fileType = "unknown";

      // ----------------------------- URL UPLOAD -----------------------------
      if (_useUrl) {
        if (_urlValue == null || _urlValue!.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Please enter a URL")));
          return;
        }

        fileUrl = _urlValue!;
        fileType = detectType(fileUrl);
      }
      // ----------------------------- FILE UPLOAD -----------------------------
      else {
        if (_pickedFile == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Pick a file first")));
          return;
        }

        final fileName = _pickedFile!.name;
        fileType = detectType(fileName); // <--- Real file extension

        Uint8List? uploadBytes;
        File? finalFile = _localFile!;
        int size = finalFile.lengthSync();

        if (size > maxBytes) {
          if (["mp4", "mov", "mkv", "avi", "webm"].contains(fileType)) {
            final compressedFile = await compressVideo(finalFile);
            if (compressedFile == null ||
                compressedFile.lengthSync() > maxBytes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Video too large even after compression"),
                ),
              );
              return;
            }
            finalFile = compressedFile;
          } else {
            final imgData = await compressImage(finalFile);
            if (imgData == null || imgData.lengthInBytes > maxBytes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Image too large even after compression"),
                ),
              );
              return;
            }
            uploadBytes = imgData;
          }
        }

        uploadBytes ??= await finalFile.readAsBytes();

        final contentType =
            lookupMimeType(fileName) ?? "application/octet-stream";

        fileUrl = await uploadToFirebaseStorage(
          selectedSubtopic!,
          fileName,
          uploadBytes,
          contentType,
        );
      }

      // ----------------------------- SAVE FIRESTORE -----------------------------
      await FirebaseFirestore.instance
          .collection("tutorial")
          .doc(selectedSubtopic)
          .collection("files")
          .add({
            "fileName": _titleCtrl.text.trim(),
            "description": _descCtrl.text.trim(),
            "fileType": fileType,
            "fileUrl": fileUrl,
            "uploadedBy": user.uid,
            "teacherName": doc["name"],
            "modifiedDate": FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload successful!")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --------------------------------------------------------------
  // UI
  // --------------------------------------------------------------
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
                  // ---------------- Title ----------------
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Enter a title" : null,
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Description ----------------
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Subtopic Dropdown ----------------
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Subtopic",
                      border: OutlineInputBorder(),
                    ),
                    items: subtopics
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    value: selectedSubtopic,
                    onChanged: (v) => setState(() => selectedSubtopic = v),
                    validator: (v) => v == null ? "Select a subtopic" : null,
                  ),
                  const SizedBox(height: 15),

                  // ---------------- Switch (URL/File) ----------------
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
                      _useUrl ? "Add (URL)" : "Upload & Add Tutorial",
                    ),
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
