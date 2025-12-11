import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoFullScreen extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoFullScreen({super.key, required this.controller});

  @override
  State<VideoFullScreen> createState() => _VideoFullScreenState();
}

class _VideoFullScreenState extends State<VideoFullScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.play();
  }

  @override
  void dispose() {
    widget.controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoProgressIndicator(
          widget.controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
              onPressed: () {
                final pos = widget.controller.value.position;
                widget.controller.seekTo(pos - const Duration(seconds: 10));
              },
            ),
            IconButton(
              icon: Icon(
                widget.controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () {
                if (widget.controller.value.isPlaying) {
                  widget.controller.pause();
                } else {
                  widget.controller.play();
                }
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
              onPressed: () {
                final pos = widget.controller.value.position;
                widget.controller.seekTo(pos + const Duration(seconds: 10));
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
