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

  String _formatTimeAgo(Timestamp? ts) {
    if (ts == null) return "Unknown";
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
  }

  bool _isNew(Timestamp? ts) {
    if (ts == null) return false;
    return DateTime.now().difference(ts.toDate()).inDays <= 3;
  }

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
              final fileType = rawType == 'mp4'
                  ? 'video'
                  : (rawType == 'pptx' || rawType == 'ppt')
                  ? 'ppt'
                  : rawType;

              return TutorialFile(
                fileName: (data['fileName'] ?? '').toString(),
                fileType: fileType,
                fileUrl: (data['fileUrl'] ?? '').toString(),
                teacherName: (data['teacherName'] ?? '').toString(),
                uploadedBy: (data['uploadedBy'] ?? '').toString(),
                description: (data['description'] ?? '').toString(),
                thumbnailUrl: '',
                modifiedDate: data['modifiedDate'],
              );
            }).toList();

            files.sort((a, b) {
              final at = a.modifiedDate?.toDate() ?? DateTime(2000);
              final bt = b.modifiedDate?.toDate() ?? DateTime(2000);
              return bt.compareTo(at);
            });

            tutorials.add(Tutorial(subtopic: subtopic, files: files));
          }
          return tutorials;
        });
  }

  Color _accent(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red.shade600;
      case 'video':
        return Colors.blue.shade600;
      case 'ppt':
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  Future<File?> _getThumbnail(TutorialFile file) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final localPath = '${docsDir.path}/${file.fileName}';
    final localFile = File(localPath);
    final hasLocal = await localFile.exists();

    final thumbDir = Directory('${docsDir.path}/thumbnails');
    if (!thumbDir.existsSync()) thumbDir.createSync(recursive: true);

    final safe = file.fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final thumbPath = '${thumbDir.path}/$safe.jpg';
    final thumbFile = File(thumbPath);

    if (thumbFile.existsSync()) {
      final age = DateTime.now().difference(await thumbFile.lastModified());
      if (age.inHours < 24) return thumbFile;
    }

    try {
      if (file.fileType == 'video') {
        final src = hasLocal ? localPath : file.fileUrl;
        final path = await VideoThumbnail.thumbnailFile(
          video: src,
          thumbnailPath: thumbPath,
          timeMs: 1000,
          imageFormat: ImageFormat.JPEG,
          quality: 85,
        );
        return path != null ? File(path) : null;
      } else if (file.fileType == 'pdf') {
        Uint8List bytes;

        if (hasLocal) {
          final pdf = await PdfDocument.openFile(localPath);
          final page = await pdf.getPage(1);
          final img = await page.render(width: 600, height: 800);
          await page.close();
          if (img?.bytes == null) return null;
          await thumbFile.writeAsBytes(img!.bytes!, flush: true);
          return thumbFile;
        } else {
          final res = await Dio().get<List<int>>(
            file.fileUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          bytes = Uint8List.fromList(res.data ?? []);
          final pdf = await PdfDocument.openData(bytes);
          final page = await pdf.getPage(1);
          final img = await page.render(width: 600, height: 800);
          await page.close();
          if (img?.bytes == null) return null;
          await thumbFile.writeAsBytes(img!.bytes!, flush: true);
          return thumbFile;
        }
      }
    } catch (_) {}
    return null;
  }

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
      body: StreamBuilder<List<Tutorial>>(
        stream: getTutorialsStream(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final tutorials = snap.data!;
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
                      builder: (context, th) {
                        final thumb = th.data;
                        final ago = _formatTimeAgo(file.modifiedDate);

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TutorialFileViewer(file: file),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: accent.withOpacity(
                                .25,
                              ), // ✅ Card color by type
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
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
                                              color: accent.withOpacity(.25),
                                              child: Icon(
                                                file.fileType == 'video'
                                                    ? Icons
                                                          .play_circle_fill_rounded
                                                    : file.fileType == 'pdf'
                                                    ? Icons
                                                          .picture_as_pdf_rounded
                                                    : Icons
                                                          .slideshow_rounded, // ✅ PowerPoint-style icon
                                                color: accent,
                                                size: 60,
                                              ),
                                            ),
                                    ),
                                    if (_isNew(file.modifiedDate))
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            "NEW",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
                                        "By ${file.teacherName} • Updated $ago",
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
    );
  }
}
