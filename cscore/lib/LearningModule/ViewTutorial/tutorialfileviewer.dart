import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart'; 
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Import the necessary files
import 'full_pdf_viewer_page.dart';
import 'tutorialmodel.dart'; 

class TutorialFileViewer extends StatefulWidget {
  final TutorialFile file;
  const TutorialFileViewer({super.key, required this.file});

  @override
  State<TutorialFileViewer> createState() => _TutorialFileViewerState();
}

class _TutorialFileViewerState extends State<TutorialFileViewer> {
  // --- File/Download State ---
  bool isDownloaded = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? localFilePath;

  // --- PDF Navigation State (The key fields for the fix) ---
  // We use these fields to pass the necessary info to FullPdfViewerPage
  String _pathForViewer = '';
  bool _isAsset = false;

  // --- Video Controllers ---
  // PDF Controller is now REMOVED to prevent caching/disposal issues.
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  @override
  void dispose() {
    // Only dispose the video controllers
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.file.fileName}');
    if (await file.exists()) {
      isDownloaded = true;
      localFilePath = file.path;
    }

    // Determine the final path and if it's an asset or not
    final path = localFilePath ?? widget.file.fileUrl;
    _isAsset = path.startsWith('assets/');
    _pathForViewer = path; // Save the path to pass on navigation

    // ❌ REMOVED: All PDF controller initialization logic. FullPdfViewerPage handles this now.

    // 🎬 Video setup (Only relevant if it's a video file)
    if (widget.file.fileType == 'video') {
      _videoController = _isAsset
          ? VideoPlayerController.asset(path)
          : isDownloaded
              ? VideoPlayerController.file(File(path))
              : VideoPlayerController.networkUrl(Uri.parse(path));

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.teal,
          handleColor: Colors.white,
          backgroundColor: Colors.grey.shade400,
          bufferedColor: Colors.teal.shade100,
        ),
        additionalOptions: (context) => [
          OptionItem(
            onTap: (_) async {
              final current = _videoController!.value.position;
              await _videoController!.seekTo(
                current - const Duration(seconds: 10),
              );
            },
            iconData: Icons.replay_10,
            title: 'Rewind 10s',
          ),
          OptionItem(
            onTap: (_) async {
              final current = _videoController!.value.position;
              await _videoController!.seekTo(
                current + const Duration(seconds: 10),
              );
            },
            iconData: Icons.forward_10,
            title: 'Forward 10s',
          ),
        ],
      );
    }

    setState(() {});
  }

  Future<void> _downloadFile() async {
    setState(() => isDownloading = true);

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${widget.file.fileName}';

    try {
      await Dio().download(
        widget.file.fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => downloadProgress = received / total);
          }
        },
      );

      setState(() {
        isDownloaded = true;
        isDownloading = false;
        localFilePath = savePath;
        _pathForViewer = savePath; // Update the path for navigation
        _isAsset = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ File saved for offline use!')),
      );
    } catch (e) {
      setState(() => isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to download file: $e')),
      );
    }
  }

  Widget _buildFileViewer() {
    // 🎬 VIDEO VIEWER (Only Video remains embedded)
    if (widget.file.fileType == 'video') {
      if (_chewieController == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final color = Colors.teal.shade100;
    final isPdf = file.fileType == 'pdf';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          file.fileName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: color,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        // Retain the physics fix for general use
        physics: const AlwaysScrollableScrollPhysics(),
        
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🖼️ Thumbnail
            Hero(
              tag: file.fileName,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  file.thumbnailUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 📝 Description section
            Text(
              file.description ?? "No description available for this material.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            _buildFileViewer(), // Shows video or PDF placeholder

            // 🚀 NEW BUTTON: Open full PDF viewer
            if (isPdf)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _pathForViewer.isEmpty 
                    ? null // Disable if path hasn't been determined yet
                    : () {
                    // ✅ THE FIX: Navigate and pass the file DATA, not the controller object!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullPdfViewerPage(
                          fileName: file.fileName,
                          filePathOrUrl: _pathForViewer, // The file path or URL
                          isAsset: _isAsset, // Is it an asset or network/local file?
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Open Full PDF Viewer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Uploaded by: ${file.teacherName}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 16),

            // ⬇️ Download button logic (unchanged)
            if (isDownloading)
              Column(
                children: [
                  const Text("Downloading..."),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: downloadProgress),
                ],
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDownloaded ? Colors.green : Colors.teal.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                icon: Icon(
                  isDownloaded
                      ? Icons.download_done
                      : Icons.download_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isDownloaded
                      ? 'File Downloaded (Open Offline)'
                      : 'Download for Offline Use',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                onPressed: (isDownloaded || !isPdf) ? null : _downloadFile,
              ),

            const SizedBox(height: 20),

            // 📂 Open file if downloaded (unchanged)
            if (isDownloaded && localFilePath != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  OpenFilex.open(localFilePath!);
                },
                icon: const Icon(Icons.folder_open, color: Colors.white),
                label: const Text(
                  'Open Offline File',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}