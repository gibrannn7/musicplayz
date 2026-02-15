import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../core/audio_handler.dart';

final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.queue.stream;
});
