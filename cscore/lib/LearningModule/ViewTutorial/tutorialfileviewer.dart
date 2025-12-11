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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'viewpptxonline.dart';
import 'full_pdf_viewer_page.dart';
import 'tutorialmodel.dart';
import 'videoFullScreen.dart';

class TutorialFileViewer extends StatefulWidget {
  final TutorialFile file;
  final String subtopic; // <-- subtopic for Firestore path

  const TutorialFileViewer({
    super.key,
    required this.file,
    required this.subtopic,
  });

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
  ChewieController? _chewie;
  PdfController? _pdf;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewie?.dispose();
    _pdf?.dispose();
    super.dispose();
  }

  String _formatTs(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    return DateFormat('dd MMM yyyy • hh:mm a').format(ts.toDate());
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _smoothSeek(Duration position) async {
    if (_videoController == null) return;

    bool wasPlaying = _videoController!.value.isPlaying;

    // Pause first to prevent stutter
    await _videoController!.pause();

    // Perform seek
    await _videoController!.seekTo(position);

    // Give decoder time to reload audio buffer
    await Future.delayed(const Duration(milliseconds: 100));

    // Resume if previously playing
    if (wasPlaying) {
      await _videoController!.play();
    }

    if (mounted) setState(() {});
  }

  // --------------------------------------------------------
  // MAIN INIT
  // --------------------------------------------------------
  Future<void> _initializeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final saved = File('${dir.path}/${widget.file.fileName}');
    final meta = File('${dir.path}/${widget.file.fileName}.meta');

    if (await saved.exists() && await meta.exists()) {
      final stored = await meta.readAsString();
      final server =
          widget.file.modifiedDate?.millisecondsSinceEpoch.toString() ?? '';
      if (stored == server) {
        isDownloaded = true;
        localFilePath = saved.path;
      }
    }

    _pathForViewer = localFilePath ?? widget.file.fileUrl;
    _isAsset = _pathForViewer.startsWith('assets/');

    final t = widget.file.fileType.toLowerCase();

    if (t == 'video') await _setupVideo();
    if (t == 'pdf') await _setupPdf();

    setState(() {});
  }

  // --------------------------------------------------------
  // VIDEO SETUP
  // --------------------------------------------------------
  Future<void> _setupVideo() async {
    _videoController?.dispose();
    _videoController = null;

    final path = _pathForViewer;

    if (_isAsset) {
      _videoController = VideoPlayerController.asset(path);
    } else if (isDownloaded) {
      _videoController = VideoPlayerController.file(File(path));
    } else {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
    }

    await _videoController!.initialize();

    // Wait until metadata loads (fixes duration = 0 bug)
    while (_videoController!.value.duration.inMilliseconds == 0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Update UI on every frame
    _videoController!.addListener(() {
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  // --------------------------------------------------------
  // PDF
  // --------------------------------------------------------
  Future<void> _setupPdf() async {
    if (isDownloaded) {
      _pdf = PdfController(document: PdfDocument.openFile(_pathForViewer));
    } else {
      final d = await Dio().get(
        widget.file.fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      _pdf = PdfController(document: PdfDocument.openData(d.data));
    }
  }

  // --------------------------------------------------------
  // DOWNLOAD LOGIC
  // --------------------------------------------------------
  Future<void> _downloadFile() async {
    setState(() => isDownloading = true);

    final dir = await getApplicationDocumentsDirectory();
    final save = '${dir.path}/${widget.file.fileName}';
    final meta = '${dir.path}/${widget.file.fileName}.meta';

    try {
      await Dio().download(
        widget.file.fileUrl,
        save,
        onReceiveProgress: (r, t) {
          setState(() => downloadProgress = t > 0 ? r / t : 0);
        },
      );

      await File(meta).writeAsString(
        widget.file.modifiedDate?.millisecondsSinceEpoch.toString() ?? '',
      );

      isDownloaded = true;
      localFilePath = save;
      _pathForViewer = save;

      if (widget.file.fileType == 'video') {
        await _setupVideo();
      }

      setState(() => isDownloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Downloaded")));
    } catch (e) {
      setState(() => isDownloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --------------------------------------------------------
  // SAFE DELETE (ONLY THIS FILE)
  // --------------------------------------------------------
  Future<void> _deleteFile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != widget.file.uploadedBy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not allowed to delete this file.")),
        );
        return;
      }

      // 1) DELETE FILES FROM STORAGE
      if (widget.file.fileUrl.isNotEmpty) {
        try {
          // Processed version
          final processedRef = FirebaseStorage.instance.refFromURL(widget.file.fileUrl);
          final processedPath = processedRef.fullPath;
          await processedRef.delete();

          // Delete original video if processed
          if (processedPath.endsWith("_processed.mp4")) {
            final originalPath = processedPath.replaceFirst("_processed.mp4", ".mp4");
            final originalRef = FirebaseStorage.instance.ref(originalPath);
            try {
              await originalRef.delete();
            } catch (e) {
              debugPrint("Original video delete skipped: $e");
            }
          }
        } catch (e) {
          debugPrint("Storage deletion error: $e");
        }
      }

      // 2) DELETE THE DOCUMENT
      final snap = await FirebaseFirestore.instance
          .collection('tutorial')
          .doc(widget.subtopic)
          .collection('files')
          .where('fileUrl', isEqualTo: widget.file.fileUrl)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutorial deleted successfully!')),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  // --------------------------------------------------------
  // PPT PREVIEW (unchanged)
  // --------------------------------------------------------
  Widget _buildPptPreview() {
    return FutureBuilder<bool>(
      future: _hasInternet(),
      builder: (c, s) {
        final online = s.data == true;

        if (online) {
          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(
              Uri.parse(
                'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.file.fileUrl)}',
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
                  "No Internet",
                  style: TextStyle(color: Colors.orange.shade800),
                ),
                Text(
                  "Use Offline button",
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------
  // PREVIEW BUILDER (unchanged UI)
  // --------------------------------------------------------
  Widget _buildPreview() {
    final t = widget.file.fileType.toLowerCase();

    if (t == 'video') {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // VIDEO DISPLAY
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio == 0
                ? 16 / 9
                : _videoController!.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VideoPlayer(_videoController!),
            ),
          ),

          const SizedBox(height: 10),

          // PROGRESS BAR + SCRUBBING
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black26,
            ),
          ),

          const SizedBox(height: 10),

          // CONTROLS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, size: 32),
                onPressed: () async {
                  final pos = _videoController!.value.position;
                  await _smoothSeek(pos - const Duration(seconds: 10));
                },
              ),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 40,
                ),
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, size: 32),
                onPressed: () async {
                  final pos = _videoController!.value.position;
                  await _smoothSeek(pos + const Duration(seconds: 10));
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 32),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VideoFullScreen(controller: _videoController!),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      );
    }

    if (t == 'pdf') {
      if (_pdf == null) return const Center(child: CircularProgressIndicator());
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: PdfView(
            controller: _pdf!,
            pageSnapping: false,
            scrollDirection: Axis.horizontal,
          ),
        ),
      );
    }

    if (t == 'ppt' || t == 'pptx') return _buildPptPreview();

    return const SizedBox.shrink();
  }

  // --------------------------------------------------------
  // UI (original + delete icon)
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    final t = f.fileType.toLowerCase();

    final c = t == 'pdf'
        ? Colors.red.shade600
        : (t == 'ppt' || t == 'pptx')
            ? Colors.orange.shade600
            : Colors.blue.shade600;

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: c,
        title: Text(f.fileName, style: const TextStyle(color: Colors.white)),
      ),
      floatingActionButton: currentUser != null && currentUser.uid == f.uploadedBy
          ? FloatingActionButton(
              backgroundColor: Colors.red.shade600,
              child: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Delete File?"),
                    content: const Text(
                      "Are you sure you want to delete this tutorial?",
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deleteFile();
                }
              },
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(),
            const SizedBox(height: 20),
            Text(
              f.fileName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // uploader + date
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Uploaded by: ${f.teacherName}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTs(f.modifiedDate),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(f.description),
            ),

            const SizedBox(height: 28),

            // PDF open button
            if (t == 'pdf')
              ElevatedButton.icon(
                style: _btn(c),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  "Open Full PDF Viewer",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullPdfViewerPage(
                        fileName: f.fileName,
                        filePathOrUrl: _pathForViewer,
                        isAsset: _isAsset,
                      ),
                    ),
                  );
                },
              ),

            // PPT
           if (t == 'ppt' || t == 'pptx')
            Column(
              children: [
                // View Online Button (only if internet is available)
                FutureBuilder<bool>(
                  future: _hasInternet(),
                  builder: (context, snapshot) {
                    final hasInternet = snapshot.data ?? false;
                    if (!hasInternet) return const SizedBox.shrink();

                    return ElevatedButton.icon(
                      style: _btn(c),
                      icon: const Icon(Icons.slideshow, color: Colors.white),
                      label: const Text("View Online",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewOnlinePage(fileUrl: widget.file.fileUrl),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Open Offline PPT (only if already downloaded)
                if (isDownloaded)
                  ElevatedButton.icon(
                    style: _btn(c),
                    icon: const Icon(Icons.offline_pin, color: Colors.white),
                    label: const Text(
                      "Open Offline PPT",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => OpenFilex.open(_pathForViewer),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Download
            isDownloading
                ? LinearProgressIndicator(value: downloadProgress)
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDownloaded ? Colors.green : c,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: Icon(
                      isDownloaded ? Icons.check : Icons.download,
                      color: Colors.white,
                    ),
                    label: Text(
                      isDownloaded
                          ? "File Saved (Offline)"
                          : "Download for Offline Use",
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: isDownloaded ? null : _downloadFile,
                  ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _btn(Color c) {
    return ElevatedButton.styleFrom(
      backgroundColor: c,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
