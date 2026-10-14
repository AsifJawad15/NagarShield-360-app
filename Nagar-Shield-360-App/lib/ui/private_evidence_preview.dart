import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../nagar_repository.dart';

class PrivateEvidencePreview extends StatelessWidget {
  const PrivateEvidencePreview({
    super.key,
    required this.repository,
    required this.storageKey,
    required this.label,
    required this.bangla,
  });
  final NagarRepository repository;
  final String storageKey;
  final String label;
  final bool bangla;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: repository.signedMediaUrl(storageKey),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text('$label: ${snapshot.error}');
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 110,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final url = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (storageKey.endsWith('.svg'))
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: SvgPicture.network(url, fit: BoxFit.cover),
              ),
            )
          else if (storageKey.endsWith('.webm') || storageKey.endsWith('.mp4'))
            _EvidenceVideo(url: url, bangla: bangla)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, error, _) => Text(error.toString()),
              ),
            ),
        ],
      );
    },
  );
}

class _EvidenceVideo extends StatefulWidget {
  const _EvidenceVideo({required this.url, required this.bangla});
  final String url;
  final bool bangla;

  @override
  State<_EvidenceVideo> createState() => _EvidenceVideoState();
}

class _EvidenceVideoState extends State<_EvidenceVideo> {
  late final VideoPlayerController controller;
  late final Future<void> ready;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    ready = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text('${snapshot.error}');
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          TextButton.icon(
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              setState(() {});
            },
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(
              controller.value.isPlaying
                  ? (widget.bangla ? 'থামান' : 'Pause')
                  : (widget.bangla ? 'চালান' : 'Play'),
            ),
          ),
        ],
      );
    },
  );
}
