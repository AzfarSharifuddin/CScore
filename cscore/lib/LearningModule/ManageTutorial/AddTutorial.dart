// AddTutorial.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart'; // optional - heavy native plugin

/// AddTutorialPage
/// Put this file in lib/LearningModule/ManageTutorial/AddTutorial.dart
///
/// NOTE: Add the packages in pubspec.yaml. If you don't want video compression,
/// remove the video_compress package and related code blocks (they are protected
/// and will gracefully fallback).

class AddTutorialPage extends StatefulWidget {
  const AddTutorialPage({super.key});

  @override
  State<AddTutorialPage> createState() => _AddTutorialPageState();
}

class _AddTutorialPageState extends State<AddTutorialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subtopicCtrl = TextEditingController();

  bool _useUrl = false;
  String? _urlValue;

  // picked file
  PlatformFile? _pickedFile;
  File? _pickedLocalFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // size limit (5 MB)
  static const int maxBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtopicCtrl.dispose();
    VideoCompress.cancelCompression(); // safe to call even if not used
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: false,
      // allow any type (you said allow all)
      type: FileType.any,
    );

    if (res == null) return;

    setState(() {
      _pickedFile = res.files.single;
      _pickedLocalFile = _pickedFile!.path != null
          ? File(_pickedFile!.path!)
          : null;
    });
  }

  String _detectFileType(String? name, String? url) {
    final ext = (name ?? url ?? '').split('.').isNotEmpty
        ? (name ?? url ?? '').split('.').last.toLowerCase()
        : '';
    if (['pdf'].contains(ext)) return 'pdf';
    if (['mp4', 'mov', 'mkv', 'webm', 'avi'].contains(ext)) return 'video';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['doc', 'docx'].contains(ext)) return 'doc';
    // fallback to mime check
    final mimeFromName = lookupMimeType(name ?? url ?? '');
    if (mimeFromName != null && mimeFromName.startsWith('video/'))
      return 'video';
    if (mimeFromName != null && mimeFromName == 'application/pdf') return 'pdf';
    return ext.isNotEmpty ? ext : 'file';
  }

  Future<Uint8List?> _compressImageFile(File input, {int quality = 85}) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        input.path,
        quality: quality,
        keepExif: false,
      );
      return result == null ? null : Uint8List.fromList(result);
    } catch (e) {
      return null;
    }
  }

  /// Try to compress video using video_compress library. Returns compressed file path or null.
  Future<File?> _compressVideoFile(File input) async {
    try {
      // initialize plugin (no-op if already)
      await VideoCompress.setLogLevel(0);
      final info = await VideoCompress.compressVideo(
        input.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (info == null || info.path == null) return null;
      return File(info.path!);
    } catch (e) {
      // compression failed — fallback
      return null;
    }
  }

  Future<String> _uploadBytesToSupabase({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final client = Supabase.instance.client;
    final storage = client.storage.from('tutorial_files');
    final res = await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
      // note: uploadBinary doesn't provide progress - we'll show spinner
    );
    // build public URL - using Supabase storage public URL format
    final url = client.storage.from('tutorial_files').getPublicUrl(path);
    return url;
  }

  Future<String> _uploadFilePathToSupabase({
    required String path,
    required File file,
    required String contentType,
    required void Function(double) onProgress,
  }) async {
    final client = Supabase.instance.client;
    final http = Dio();

    // Use Signed URL approach: create upload from storage via REST PUT
    // Simpler: call storage.upload with file bytes (but SDK may not support progress)
    // We'll call storage.upload using the SDK (uploading bytes) for simplicity.
    final bytes = await file.readAsBytes();
    // show progress as finished
    onProgress(0.5);
    final url = await _uploadBytesToSupabase(
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
    onProgress(1);
    return url;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final subtopic = _subtopicCtrl.text.trim();
    if (subtopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subtopic (folder)')),
      );
      return;
    }

    // if using URL:
    if (_useUrl) {
      if ((_urlValue ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste a file URL')),
        );
        return;
      }

      final fileUrl = _urlValue!;
      final type = _detectFileType(null, fileUrl);

      setState(() => _isUploading = true);
      try {
        // Write Firestore doc under tutorials/{subtopic}/files
        final collectionRef = FirebaseFirestore.instance
            .collection('tutorials')
            .doc(subtopic)
            .collection('files');

        await collectionRef.add({
          'fileName': title,
          'description': desc,
          'fileType': type,
          'fileUrl': fileUrl,
          'teacherName': 'System', // replace with actual teacher name logic
          'uploadedBy': 'teacher', // replace if needed
          'modifiedDate': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tutorial added using URL')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Failed to add tutorial: $e')));
      } finally {
        setState(() => _isUploading = false);
      }
      return;
    }

    // else: upload file flow
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a file to upload')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      File? sourceFile = _pickedLocalFile;
      // If no local path (web?), try to write bytes to temp
      if (sourceFile == null && _pickedFile!.bytes != null) {
        final tmp = await getTemporaryDirectory();
        final fp = File('${tmp.path}/${_pickedFile!.name}');
        await fp.writeAsBytes(_pickedFile!.bytes!);
        sourceFile = fp;
      }

      if (sourceFile == null) {
        throw Exception('Could not access the picked file');
      }

      int fileBytes = await sourceFile.length();

      String ext = p
          .extension(sourceFile.path)
          .replaceFirst('.', '')
          .toLowerCase();
      final type = _detectFileType(sourceFile.path, null);
      Uint8List? uploadBytes;
      File? uploadFile;

      // If file is already <= limit, we can upload directly
      if (fileBytes <= maxBytes) {
        uploadFile = sourceFile;
      } else {
        // Attempt compression depending on type
        if (type == 'video') {
          // Try video compression (best effort)
          final compressed = await _compressVideoFile(sourceFile);
          if (compressed != null) {
            final compressedSize = await compressed.length();
            if (compressedSize <= maxBytes) {
              uploadFile = compressed;
            } else {
              // give user option: still upload (not allowed by requirement) or fail
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Video still larger than 5MB after compression. Use URL or reduce file size.',
                  ),
                ),
              );
              setState(() => _isUploading = false);
              return;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not compress video. Use URL or a smaller file.',
                ),
              ),
            );
            setState(() => _isUploading = false);
            return;
          }
        } else {
          // try compress image if image-like
          final mime = lookupMimeType(sourceFile.path) ?? '';
          if (mime.startsWith('image/')) {
            final imgBytes = await _compressImageFile(sourceFile, quality: 80);
            if (imgBytes != null && imgBytes.lengthInBytes <= maxBytes) {
              uploadBytes = imgBytes;
            } else if (imgBytes != null && imgBytes.lengthInBytes > maxBytes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Image still larger than 5MB after compression. Use URL or reduce file size.',
                  ),
                ),
              );
              setState(() => _isUploading = false);
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Image compression failed. Use URL or smaller image.',
                  ),
                ),
              );
              setState(() => _isUploading = false);
              return;
            }
          } else {
            // For other file types - we don't have a reliable client-side compressor for arbitrary binary files.
            // Inform user to use URL or smaller file.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'File exceeds 5MB. Please use URL or a smaller file.',
                ),
              ),
            );
            setState(() => _isUploading = false);
            return;
          }
        }
      }

      // Build upload path in supabase: subtopic/filename_timestamp.ext to avoid collisions
      final fileNameSafe = _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim().replaceAll(RegExp(r'[^\w\.-]'), '_')
          : p.basename(sourceFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extOut = p.extension(sourceFile.path).toLowerCase();
      final remotePath = '${subtopic.trim()}/${fileNameSafe}_$timestamp$extOut';

      // contentType
      final contentType =
          lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

      // Upload
      String publicUrl;
      if (uploadBytes != null) {
        // upload bytes
        setState(() => _uploadProgress = 0.2);
        publicUrl = await _uploadBytesToSupabase(
          path: remotePath,
          bytes: uploadBytes,
          contentType: contentType,
        );
        setState(() => _uploadProgress = 1.0);
      } else if (uploadFile != null) {
        // upload file path (may use SDK)
        setState(() => _uploadProgress = 0.1);
        publicUrl = await _uploadFilePathToSupabase(
          path: remotePath,
          file: uploadFile,
          contentType: contentType,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      } else {
        throw Exception('No upload bytes/file prepared');
      }

      // Write Firestore document
      final collectionRef = FirebaseFirestore.instance
          .collection('tutorials')
          .doc(subtopic)
          .collection('files');

      await collectionRef.add({
        'fileName': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'fileType': type,
        'fileUrl': publicUrl,
        'teacherName': 'System',
        'uploadedBy': 'teacher',
        'modifiedDate': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ File uploaded and tutorial added')),
      );

      // done
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('upload error: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Upload failed: $e')));
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Widget _buildFileCard() {
    if (_pickedFile == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: const Text('Pick file from device'),
        onPressed: _pickFile,
      );
    }

    final name = _pickedFile!.name;
    final sizeKb = ((_pickedFile!.size ?? 0) / 1024).toStringAsFixed(1);

    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(name),
      subtitle: Text('$sizeKb KB'),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _pickedFile = null;
            _pickedLocalFile = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tutorial'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Subtopic (this becomes the document id / folder)
              TextFormField(
                controller: _subtopicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subtopic (folder)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a subtopic' : null,
              ),
              const SizedBox(height: 12),

              // Toggle: URL or Upload
              Row(
                children: [
                  const Text('Upload via URL'),
                  Switch(
                    value: _useUrl,
                    onChanged: (v) => setState(() {
                      _useUrl = v;
                      _pickedFile = null;
                      _urlValue = null;
                    }),
                  ),
                  const Spacer(),
                  Text(_useUrl ? 'Using URL' : 'Using local file'),
                ],
              ),
              const SizedBox(height: 8),

              if (_useUrl)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'File URL',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _urlValue = v.trim(),
                  validator: (v) {
                    if (_useUrl && (v == null || v.trim().isEmpty))
                      return 'Please paste a file URL';
                    return null;
                  },
                )
              else
                _buildFileCard(),

              const SizedBox(height: 18),

              // Upload progress and button
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Uploading... please wait'),
                  ],
                ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _submit,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  _useUrl ? 'Add tutorial (URL)' : 'Upload file & Add tutorial',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
