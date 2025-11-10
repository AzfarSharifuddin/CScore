import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:pdfx/pdfx.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'full_pdf_viewer_page.dart';
import 'tutorialmodel.dart';

class TutorialFileViewer extends StatefulWidget {
  final TutorialFile file;
  const TutorialFileViewer({super.key, required this.file});

  @override
  State<TutorialFileViewer> createState() => _TutorialFileViewerState();
}

class _TutorialFileViewerState extends State<TutorialFileViewer> {
  bool isDownloaded = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? localFilePath;

  String _pathForViewer = '';
  bool _isAsset = false;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    final local = ts.toDate().toLocal();
    return DateFormat('dd MMM yyyy • hh:mm a').format(local);
  }

  Future<void> _initializeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = File('${dir.path}/${widget.file.fileName}');
    final meta = File('${dir.path}/${widget.file.fileName}.meta');

    // Check stored file + stored modifiedDate
    if (await saved.exists() && await meta.exists()) {
      final storedModified = await meta.readAsString();
      final serverModified =
          widget.file.modifiedDate?.millisecondsSinceEpoch.toString() ?? '';

      // ✅ If teacher updated, require re-download
      if (storedModified == serverModified) {
        isDownloaded = true;
        localFilePath = saved.path;
      } else {
        isDownloaded = false;
      }
    }

    final path = localFilePath ?? widget.file.fileUrl;
    _pathForViewer = path;
    _isAsset = path.startsWith('assets/');

    // VIDEO SETUP
    if (widget.file.fileType == 'video') {
      if (_isAsset) {
        _videoController = VideoPlayerController.asset(path);
      } else if (isDownloaded) {
        _videoController = VideoPlayerController.file(File(path));
      } else {
        _videoController = VideoPlayerController.network(path);
      }

      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
      );
    }

    // PDF SETUP
    if (widget.file.fileType == 'pdf') {
      if (isDownloaded) {
        _pdfController = PdfController(
          document: PdfDocument.openFile(_pathForViewer),
        );
      } else {
        final response = await Dio().get(
          widget.file.fileUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        _pdfController = PdfController(
          document: PdfDocument.openData(response.data),
        );
      }
    }

    setState(() {});
  }

  Future<void> _downloadFile() async {
    setState(() => isDownloading = true);

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${widget.file.fileName}';
    final metaPath = '${dir.path}/${widget.file.fileName}.meta';

    try {
      await Dio().download(
        widget.file.fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          setState(() => downloadProgress = received / total);
        },
      );

      // ✅ Store modifiedDate for future comparison
      final serverModified =
          widget.file.modifiedDate?.millisecondsSinceEpoch.toString() ?? '';
      await File(metaPath).writeAsString(serverModified, flush: true);

      setState(() {
        isDownloading = false;
        isDownloaded = true;
        localFilePath = savePath;
        _pathForViewer = savePath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ File downloaded for offline use!')),
      );
    } catch (e) {
      setState(() => isDownloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error downloading file: $e')));
    }
  }

  Widget _buildPreview() {
    if (widget.file.fileType == 'video') {
      if (_chewieController == null)
        return const Center(child: CircularProgressIndicator());
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    if (widget.file.fileType == 'pdf') {
      if (_pdfController == null)
        return const Center(child: CircularProgressIndicator());
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: PdfView(
            controller: _pdfController!,
            pageSnapping: false,
            scrollDirection: Axis.horizontal,
          ),
        ),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;

    final appBarColor = file.fileType == 'pdf'
        ? Colors.red.shade600
        : Colors.blue.shade600;

    final actionColor = file.fileType == 'pdf'
        ? Colors.red.shade600
        : Colors.blue.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(file.fileName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(),
            const SizedBox(height: 20),

            Text(
              file.fileName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            // Overflow-safe text row
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "Uploaded by: ${file.teacherName}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatTs(file.modifiedDate),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                file.description,
                style: const TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 28),

            // Open PDF button
            if (file.fileType == 'pdf')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullPdfViewerPage(
                        fileName: file.fileName,
                        filePathOrUrl: _pathForViewer,
                        isAsset: _isAsset,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  "Open Full PDF Viewer",
                  style: TextStyle(color: Colors.white),
                ),
              ),

            const SizedBox(height: 12),

            // Download / Re-download button
            isDownloading
                ? LinearProgressIndicator(value: downloadProgress)
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDownloaded
                          ? Colors.green.shade600
                          : actionColor,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isDownloaded ? null : _downloadFile,
                    icon: Icon(
                      isDownloaded ? Icons.download_done : Icons.download,
                      color: Colors.white,
                    ),
                    label: Text(
                      isDownloaded
                          ? "File Saved (Open Offline)"
                          : "Download for Offline Use",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
