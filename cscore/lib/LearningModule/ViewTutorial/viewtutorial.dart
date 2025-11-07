import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pdfx/pdfx.dart';

import 'tutorialmodel.dart';
import 'tutorialfileviewer.dart';

class ViewTutorialPage extends StatelessWidget {
  const ViewTutorialPage({super.key});

  // ------------------ DATA ------------------
  Stream<List<Tutorial>> getTutorialsStream() {
    return FirebaseFirestore.instance
        .collection('tutorials')
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Tutorial> tutorials = [];
          for (final doc in snapshot.docs) {
            final subtopic = (doc.data()['subtopic'] ?? '').toString();
            final filesSnap = await doc.reference.collection('files').get();

            final files = filesSnap.docs.map((fileDoc) {
              final data = fileDoc.data();
              final rawType = (data['fileType'] ?? '').toString();
              final fileType = rawType == 'mp4' ? 'video' : rawType;

              return TutorialFile(
                fileName: (data['fileName'] ?? '').toString(),
                fileType: fileType,
                fileUrl: (data['fileUrl'] ?? '').toString(),
                teacherName: (data['teacherName'] ?? '').toString(),
                uploadedBy: (data['uploadedBy'] ?? '').toString(),
                description: (data['description'] ?? '').toString(),
                thumbnailUrl: '',
              );
            }).toList();

            tutorials.add(Tutorial(subtopic: subtopic, files: files));
          }
          return tutorials;
        });
  }

  // ------------------ THEME HELPERS ------------------
  Color _accent(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red.shade600;
      case 'video':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  // ------------------ THUMBNAILS (CACHED, 24h, PREFER LOCAL) ------------------
  Future<File?> _getThumbnail(TutorialFile file) async {
    final docsDir = await getApplicationDocumentsDirectory();

    // path where viewer saves offline files
    final localPath = '${docsDir.path}/${file.fileName}';
    final localFile = File(localPath);
    final bool hasLocal = await localFile.exists();

    // thumbnails cache dir
    final thumbDir = Directory('${docsDir.path}/thumbnails');
    if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

    // sanitize filename for cache key
    final safeName = file.fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final thumbPath = '${thumbDir.path}/$safeName.jpg';
    final thumbFile = File(thumbPath);

    // 1) Use cached thumbnail if fresh (<24h)
    if (thumbFile.existsSync()) {
      final age = DateTime.now().difference(await thumbFile.lastModified());
      if (age.inHours < 24) return thumbFile;
    }

    // 2) Generate new thumbnail (prefer local if available)
    try {
      if (file.fileType == 'video') {
        // If local exists, generate from local path; else pass the URL
        final source = hasLocal ? localPath : file.fileUrl;

        final path = await VideoThumbnail.thumbnailFile(
          video: source,
          thumbnailPath: thumbPath,
          timeMs: 1000, // 1-second frame to avoid black thumbs
          imageFormat: ImageFormat.JPEG,
          quality: 85,
        );
        return path != null ? File(path) : null;
      } else if (file.fileType == 'pdf') {
        Uint8List pdfBytes;

        if (hasLocal) {
          // Open and render from local file (fast, offline)
          final PdfDocument pdf = await PdfDocument.openFile(localPath);
          final PdfPage page = await pdf.getPage(1);
          final PdfPageImage? pageImage = await page.render(
            width: 600,
            height: 800,
          );
          await page.close();
          if (pageImage == null || pageImage.bytes == null) return null;
          await thumbFile.writeAsBytes(pageImage.bytes!, flush: true);
          return thumbFile;
        } else {
          // Download bytes then render (network)
          final res = await Dio().get<List<int>>(
            file.fileUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          pdfBytes = Uint8List.fromList(res.data ?? <int>[]);
          final PdfDocument pdf = await PdfDocument.openData(pdfBytes);
          final PdfPage page = await pdf.getPage(1);
          final PdfPageImage? pageImage = await page.render(
            width: 600,
            height: 800,
          );
          await page.close();
          if (pageImage == null || pageImage.bytes == null) return null;
          await thumbFile.writeAsBytes(pageImage.bytes!, flush: true);
          return thumbFile;
        }
      }
    } catch (_) {
      // Fail silently and let UI show a colored placeholder
      return null;
    }

    return null;
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('View Tutorials'),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "💡 Let's Learn Something New Today!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Explore tutorials prepared by your teachers below',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<Tutorial>>(
              stream: getTutorialsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading tutorials:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tutorials = snapshot.data!;
                if (tutorials.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tutorials available yet.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tutorials.length,
                  itemBuilder: (context, i) {
                    final group = tutorials[i];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          group.subtopic,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: const Icon(
                          Icons.folder_rounded,
                          size: 34,
                          color: Colors.teal,
                        ),
                        iconColor: Colors.teal,
                        collapsedIconColor: Colors.teal,
                        childrenPadding: const EdgeInsets.all(12),
                        children: group.files.map((file) {
                          final accent = _accent(file.fileType);
                          return FutureBuilder<File?>(
                            future: _getThumbnail(file),
                            builder: (context, snap) {
                              final thumb = snap.data;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TutorialFileViewer(file: file),
                                    ),
                                  );
                                },
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  opacity:
                                      (thumb != null ||
                                          snap.connectionState ==
                                              ConnectionState.done)
                                      ? 1
                                      : 0.6,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Thumbnail banner
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          child: thumb != null
                                              ? Image.file(
                                                  thumb,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  height: 150,
                                                  width: double.infinity,
                                                  color: accent.withOpacity(
                                                    .25,
                                                  ),
                                                  child: Icon(
                                                    file.fileType == 'video'
                                                        ? Icons
                                                              .play_circle_fill_rounded
                                                        : Icons
                                                              .picture_as_pdf_rounded,
                                                    color: accent,
                                                    size: 60,
                                                  ),
                                                ),
                                        ),
                                        // Title & teacher
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                file.fileName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                'By ${file.teacherName}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
