import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class PresetMedia extends StatefulWidget {
  const PresetMedia({
    super.key,
    required this.id,
    required this.isVideo,
    required this.bangla,
  });
  final String id;
  final bool isVideo;
  final bool bangla;
  @override
  State<PresetMedia> createState() => _PresetMediaState();
}

class _PresetMediaState extends State<PresetMedia> {
  VideoPlayerController? controller;
  String? playbackError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PresetMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.isVideo != widget.isVideo) {
      _load();
    }
  }

  Future<void> _load() async {
    final previous = controller;
    controller = null;
    await previous?.dispose();
    playbackError = null;
    if (!widget.isVideo || defaultTargetPlatform == TargetPlatform.iOS) {
      if (mounted) setState(() {});
      return;
    }
    final next = VideoPlayerController.asset(
      'assets/presets/${widget.id}.webm',
    );
    try {
      await next.initialize();
      await next.setLooping(true);
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() => controller = next);
    } catch (_) {
      await next.dispose();
      if (mounted) setState(() => playbackError = 'Playback unavailable');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      SvgPicture.asset('assets/presets/${widget.id}.svg', fit: BoxFit.fill),
      if (controller?.value.isInitialized == true) VideoPlayer(controller!),
      if (widget.isVideo)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: controller == null
                ? Chip(
                    label: Text(
                      playbackError ??
                          (widget.bangla ? 'ভিডিওর নমুনা ছবি' : 'Video poster'),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: () {
                      controller!.value.isPlaying
                          ? controller!.pause()
                          : controller!.play();
                      setState(() {});
                    },
                    icon: Icon(
                      controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(controller!.value.isPlaying ? 'Pause' : 'Play'),
                  ),
          ),
        ),
    ],
  );
}
