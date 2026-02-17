import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../models/song_model.dart';

final audioHandlerProvider = Provider<AudioHandler>((ref) => throw UnimplementedError());

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  Timer? _sleepTimer;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen(_broadcastState);
    
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        final item = queue.value[index];
        mediaItem.add(item);
        
        // RECORD PLAY STATS
        final songId = item.extras?['id']?.toString();
        if (songId != null) {
          final song = LocalSongModel(
            id: songId,
            title: item.title,
            artist: item.artist ?? 'Unknown',
            uri: item.id,
            duration: item.duration?.inMilliseconds ?? 0,
          );
          StorageService.recordPlay(song);
        }
      }
    });

    _player.loopModeStream.listen((loopMode) {
      final repeatMode = const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[loopMode]!;
      playbackState.add(playbackState.value.copyWith(
        repeatMode: repeatMode,
        updatePosition: _player.position, // FIX BUG: Update posisi realtime
      ));
    });

    _player.shuffleModeEnabledStream.listen((enabled) {
      final shuffleMode = enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
      playbackState.add(playbackState.value.copyWith(
        shuffleMode: shuffleMode,
        updatePosition: _player.position, // FIX BUG: Update posisi realtime
      ));
    });

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
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await _player.setShuffleModeEnabled(false);
    } else {
      await _player.setShuffleModeEnabled(true);
      await _player.shuffle();
    }
  }

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

  // MENGEMBALIKAN FITUR DRAG AND DROP QUEUE YANG TERLEWAT
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'reorder' && extras != null) {
      final oldIndex = extras['oldIndex'] as int;
      var newIndex = extras['newIndex'] as int;

      if (oldIndex < newIndex) {
        newIndex -= 1; 
      }
      if (oldIndex == newIndex) return;

      await _playlist.move(oldIndex, newIndex);
      
      final currentQueue = List<MediaItem>.from(queue.value);
      final item = currentQueue.removeAt(oldIndex);
      currentQueue.insert(newIndex, item);
      queue.add(currentQueue);
    }
    return super.customAction(name, extras);
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
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
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