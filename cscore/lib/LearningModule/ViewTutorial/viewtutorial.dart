import 'package:flutter/material.dart';
import 'tutorialmodel.dart';
import 'tutorialfileviewer.dart';

class ViewTutorialPage extends StatelessWidget {
  const ViewTutorialPage({super.key});

  List<Tutorial> getMockTutorials() {
    return [
      Tutorial(
        subtopic: 'HTML',
        files: [
          TutorialFile(
            fileName: 'Pengenalan HTML.pdf',
            fileType: 'pdf',
            fileUrl: 'assets/mock_tutorials/sample_tutorial.pdf',
            teacherName: 'Cikgu Aisyah',
            description:
                'Pengenalan struktur asas HTML, termasuk tag, elemen dan atribut penting untuk laman web pertama anda.',
            thumbnailUrl: 'https://i.imgur.com/x9aQkCz.png',
          ),
          TutorialFile(
            fileName: 'HTML Basics.mp4',
            fileType: 'video',
            fileUrl: 'assets/mock_tutorials/sample_video.mp4',
            teacherName: 'Encik Farid',
            description:
                'Video interaktif untuk memahami asas HTML dengan contoh visual menarik.',
            thumbnailUrl: 'https://i.imgur.com/fn9fYKH.png',
          ),
        ],
      ),
      Tutorial(
        subtopic: 'CSS',
        files: [
          TutorialFile(
            fileName: 'CSS Styling.mp4',
            fileType: 'video',
            fileUrl: 'https://example.com/css_styling.mp4',
            teacherName: 'Pn. Siti',
            description:
                'Pelajari cara menggayakan laman web anda menggunakan warna, saiz dan layout CSS.',
            thumbnailUrl: 'https://i.imgur.com/fn9fYKH.png',
          ),
          TutorialFile(
            fileName: 'CSS Responsive Design.pdf',
            fileType: 'pdf',
            fileUrl: 'https://link.springer.com/content/pdf/10.1007/s12369-025-01299-2.pdf',
            teacherName: 'Encik Farid',
            description:
                'Panduan lengkap untuk menjadikan laman web anda responsif pada semua peranti.',
            thumbnailUrl: 'https://i.imgur.com/x9aQkCz.png',
          ),
        ],
      ),
      Tutorial(
        subtopic: 'JavaScript',
        files: [
          TutorialFile(
            fileName: 'JS Functions.mp4',
            fileType: 'video',
            fileUrl: 'https://example.com/js_functions.mp4',
            teacherName: 'Encik Farid',
            description:
                'Pengenalan kepada fungsi JavaScript dengan contoh dinamik dan animasi mudah.',
            thumbnailUrl: 'https://i.imgur.com/fn9fYKH.png',
          ),
          TutorialFile(
            fileName: 'JS Variables.pdf',
            fileType: 'pdf',
            fileUrl: 'https://example.com/js_variables.pdf',
            teacherName: 'Cikgu Aisyah',
            description:
                'Dokumen PDF interaktif yang menerangkan konsep pemboleh ubah dalam JavaScript.',
            thumbnailUrl: 'https://i.imgur.com/x9aQkCz.png',
          ),
        ],
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final tutorials = getMockTutorials();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'View Tutorials',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // 🌈 Motivational header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.blueAccent.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
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
                      fontWeight: FontWeight.bold),
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

          // 📚 Tutorials List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tutorials.length,
              itemBuilder: (context, index) {
                final tutorial = tutorials[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 5,
                  shadowColor: Colors.tealAccent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        tutorial.subtopic,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: const Icon(Icons.folder_open_rounded,
                          color: Colors.teal, size: 30),
                      childrenPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      children: tutorial.files.map((file) {
                        final color = _fileColor(file.fileType);
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
                                horizontal: 12, vertical: 4),
                            leading: Hero(
                              tag: file.fileName,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  file.thumbnailUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.insert_drive_file,
                                          color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
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
                            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.grey, size: 18),
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
            ),
          ),
        ],
      ),
    );
  }
}
