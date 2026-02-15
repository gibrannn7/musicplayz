import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) => throw UnimplementedError());

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  Timer? _sleepTimer;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Listen to playback state and broadcast to audio_service
    _player.playbackEventStream.listen(_broadcastState);
    
    // Listen to current index changes
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Set the playlist source
    await _player.setAudioSource(_playlist);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    final sources = items.map(_createAudioSource).toList();
    await _playlist.addAll(sources);
    final newQueue = [...queue.value, ...items];
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    await _playlist.add(_createAudioSource(item));
    queue.add([...queue.value, item]);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
    final newQueue = [...queue.value]..removeAt(index);
    queue.add(newQueue);
  }

  @override
  Future<void> updateQueue(List<MediaItem> items) async {
    await _playlist.clear();
    await _playlist.addAll(items.map(_createAudioSource).toList());
    queue.add(items);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  AudioSource _createAudioSource(MediaItem item) {
    return AudioSource.uri(
      Uri.parse(item.id),
      tag: item,
    );
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  // Sleep Timer Logic
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      pause();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }
}
