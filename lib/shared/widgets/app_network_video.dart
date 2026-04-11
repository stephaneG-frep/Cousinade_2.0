import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AppNetworkVideo extends StatefulWidget {
  const AppNetworkVideo({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.enableFullscreen = false,
  });

  final String url;
  final String? thumbnailUrl;
  final bool enableFullscreen;

  @override
  State<AppNetworkVideo> createState() => _AppNetworkVideoState();
}

class _AppNetworkVideoState extends State<AppNetworkVideo> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppNetworkVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _isReady = false;
      _hasError = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenVideoPage(
          url: widget.url,
          thumbnailUrl: widget.thumbnailUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback();
    }

    if (!_isReady || _controller == null) {
      return Stack(
        alignment: Alignment.center,
        children: [_buildFallback(), const CircularProgressIndicator()],
      );
    }

    final controller = _controller!;
    final ratio = controller.value.aspectRatio == 0
        ? 16 / 9
        : controller.value.aspectRatio;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: ratio, child: VideoPlayer(controller)),
          if (!controller.value.isPlaying)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          if (widget.enableFullscreen)
            Positioned(
              left: 8,
              bottom: 8,
              child: InkWell(
                onTap: _openFullscreen,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    if ((widget.thumbnailUrl ?? '').isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          widget.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackBox(),
        ),
      );
    }
    return _fallbackBox();
  }

  Widget _fallbackBox() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.videocam_off_outlined),
    );
  }
}

class _FullscreenVideoPage extends StatelessWidget {
  const _FullscreenVideoPage({required this.url, this.thumbnailUrl});

  final String url;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AppNetworkVideo(
            url: url,
            thumbnailUrl: thumbnailUrl,
            enableFullscreen: false,
          ),
        ),
      ),
    );
  }
}
