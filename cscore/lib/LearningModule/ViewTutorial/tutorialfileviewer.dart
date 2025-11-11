import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:pdfx/pdfx.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  // ---- Connectivity helper that works for both old & new connectivity_plus
  Future<bool> _hasInternet() async {
    final dynamic result = await Connectivity().checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  Future<void> _initializeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = File('${dir.path}/${widget.file.fileName}');
    final meta = File('${dir.path}/${widget.file.fileName}.meta');

    // Validate against modifiedDate (forces re-download when teacher updates)
    if (await saved.exists() && await meta.exists()) {
      final storedModified = await meta.readAsString();
      final serverModified =
          widget.file.modifiedDate?.millisecondsSinceEpoch.toString() ?? '';
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

    // VIDEO SETUP (inline)
    if (widget.file.fileType.toLowerCase() == 'video') {
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

    // PDF SETUP (inline)
    if (widget.file.fileType.toLowerCase() == 'pdf') {
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
          setState(() => downloadProgress = total > 0 ? received / total : 0.0);
        },
      );

      // Store modifiedDate for future comparison
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

  // PPT/PPTX preview: WebView when online, friendly card when offline
  Widget _buildPptPreview() {
    return FutureBuilder<bool>(
      future: _hasInternet(),
      builder: (context, snapshot) {
        final online = snapshot.data == true;

        if (online) {
          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(
              Uri.parse(
                'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(widget.file.fileUrl)}',
              ),
            );

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: WebViewWidget(controller: controller),
            ),
          );
        }

        // Offline message card (clean)
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.slideshow_rounded,
                  size: 56,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 10),
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Use the offline button below',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final type = widget.file.fileType.toLowerCase();

    if (type == 'video') {
      if (_chewieController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    if (type == 'pdf') {
      if (_pdfController == null) {
        return const Center(child: CircularProgressIndicator());
      }
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

    if (type == 'ppt' || type == 'pptx') {
      return _buildPptPreview();
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final type = file.fileType.toLowerCase();

    final appBarColor = type == 'pdf'
        ? Colors.red.shade600
        : (type == 'ppt' || type == 'pptx')
        ? Colors.orange.shade600
        : Colors.blue.shade600;

    final actionColor = appBarColor;

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

            // Overflow-safe info row
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Uploaded by: ${file.teacherName}',
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

            // ----- OPEN BUTTONS -----
            if (type == 'pdf')
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
                  'Open Full PDF Viewer',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            if (type == 'ppt' || type == 'pptx') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isDownloaded
                    ? () => OpenFilex.open(_pathForViewer)
                    : () async {
                        final online = await _hasInternet();
                        if (!online) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '❌ No internet connection. Use the offline button below.',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.slideshow_rounded, color: Colors.white),
                label: Text(
                  isDownloaded ? 'Open Offline PPT' : 'View Online',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ----- DOWNLOAD BUTTON (all types) -----
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
                          ? 'File Saved (Open Offline)'
                          : 'Download for Offline Use',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
