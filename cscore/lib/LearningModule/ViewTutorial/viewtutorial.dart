import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tutorialmodel.dart';
import 'tutorialfileviewer.dart';

class ViewTutorialPage extends StatelessWidget {
  const ViewTutorialPage({super.key});

  // ---- DATA LAYER (no UI changes) ----
  Stream<List<Tutorial>> getTutorialsStream() {
    return FirebaseFirestore.instance.collection('tutorials').snapshots().asyncMap((
      snapshot,
    ) async {
      try {
        debugPrint('🔥 tutorials docs: ${snapshot.docs.length}');
        final List<Tutorial> tutorials = [];

        for (final doc in snapshot.docs) {
          final subtopic = (doc.data()['subtopic'] ?? '').toString();
          debugPrint('➡️ subtopic doc "${doc.id}" -> subtopic="$subtopic"');

          // Fetch files under this subtopic (one-time read is fine)
          final filesSnap = await doc.reference.collection('files').get();
          debugPrint(
            '   📄 files count for "$subtopic": ${filesSnap.docs.length}',
          );

          final files = filesSnap.docs.map((fileDoc) {
            final data = fileDoc.data();

            // Fallbacks + normalization so mismatched field names don’t break the stream
            final fileName = (data['fileName'] ?? data['filename'] ?? '')
                .toString();
            final rawType = (data['fileType'] ?? '').toString();
            final fileType = (rawType == 'mp4')
                ? 'video'
                : rawType; // normalize
            final fileUrl = (data['fileUrl'] ?? '').toString();
            final teacherName = (data['teacherName'] ?? '').toString();
            final uploadedBy = (data['uploadedBy'] ?? '').toString();
            final description = (data['description'] ?? '').toString();

            debugPrint(
              '      • file "${fileDoc.id}": name="$fileName", type="$fileType"',
            );

            return TutorialFile(
              fileName: fileName,
              fileType: fileType,
              fileUrl: fileUrl,
              teacherName: teacherName,
              uploadedBy: uploadedBy, // stored for permissions; not displayed
              description: description,
              thumbnailUrl: '', // not used
            );
          }).toList();

          tutorials.add(Tutorial(subtopic: subtopic, files: files));
        }

        debugPrint('✅ built tutorials list: ${tutorials.length} groups');
        return tutorials;
      } catch (e, st) {
        debugPrint('❌ getTutorialsStream error: $e\n$st');
        // Propagate so StreamBuilder shows hasError
        throw e;
      }
    });
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'video':
        return Icons.video_library_rounded;
      case 'doc':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.redAccent.shade100;
      case 'video':
        return Colors.blueAccent.shade100;
      case 'doc':
        return Colors.greenAccent.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  // ---- UI (unchanged) ----
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.blueAccent.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Tutorial>>(
              stream: getTutorialsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Show the real error so we can see permission/field issues fast
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading tutorials:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tutorials = snapshot.data ?? [];
                if (tutorials.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tutorials available yet.',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tutorials.length,
                  itemBuilder: (context, index) {
                    final tutorial = tutorials[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 5,
                      shadowColor: Colors.tealAccent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            tutorial.subtopic,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: const Icon(
                            Icons.folder_open_rounded,
                            color: Colors.teal,
                            size: 30,
                          ),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          children: tutorial.files.map((file) {
                            final color = _fileColor(file.fileType);
                            final icon = _fileIcon(file.fileType);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  icon,
                                  size: 48,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  file.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'By ${file.teacherName}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TutorialFileViewer(file: file),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
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
