import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutorialmodel.dart';
import 'tutorialfileviewer.dart';

class ViewTutorialPage extends StatelessWidget {
  const ViewTutorialPage({super.key});

  // ---- DATA LAYER ----
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
              final fileName = (data['fileName'] ?? data['filename'] ?? '')
                  .toString();
              final rawType = (data['fileType'] ?? '').toString();
              final fileType = (rawType == 'mp4') ? 'video' : rawType;
              final fileUrl = (data['fileUrl'] ?? '').toString();
              final teacherName = (data['teacherName'] ?? '').toString();
              final description = (data['description'] ?? '').toString();

              return TutorialFile(
                fileName: fileName,
                fileType: fileType,
                fileUrl: fileUrl,
                teacherName: teacherName,
                uploadedBy: teacherName,
                description: description,
                thumbnailUrl: '',
              );
            }).toList();

            tutorials.add(Tutorial(subtopic: subtopic, files: files));
          }

          return tutorials;
        });
  }

  // ---- THEMING ----
  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'doc':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _accentColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red.shade600;
      case 'video':
        return Colors.blue.shade600;
      case 'doc':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'View Tutorials',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.blueAccent.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Let’s Learn Something New Today!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Explore tutorials prepared by your teachers below',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: StreamBuilder<List<Tutorial>>(
              stream: getTutorialsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final tutorials = snapshot.data!;
                if (tutorials.isEmpty) {
                  return const Center(child: Text('No tutorials available.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tutorials.length,
                  itemBuilder: (context, index) {
                    final group = tutorials[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        iconColor: Colors.teal,
                        collapsedIconColor: Colors.teal,
                        title: Text(
                          group.subtopic,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: const Icon(
                          Icons.folder_rounded,
                          size: 32,
                          color: Colors.teal,
                        ),
                        children: group.files.map((file) {
                          final color = _accentColor(file.fileType);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TutorialFileViewer(file: file),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  // Icon badge
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _fileIcon(file.fileType),
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // Title + subtitle
                                  Expanded(
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
                                          "By ${file.teacherName}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
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
