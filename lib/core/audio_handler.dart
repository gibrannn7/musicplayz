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
      _broadcastState(_player.playbackEvent); 
    });

    _player.shuffleModeEnabledStream.listen((enabled) {
      _broadcastState(_player.playbackEvent); 
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
    
    mediaItem.add(queue.value[index]);
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name.startsWith('shuffle')) {
      final enable = !_player.shuffleModeEnabled;
      await setShuffleMode(enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
    } else if (name.startsWith('repeat')) {
      final current = _player.loopMode;
      if (current == LoopMode.off) {
        await setRepeatMode(AudioServiceRepeatMode.all);
      } else if (current == LoopMode.all) {
        await setRepeatMode(AudioServiceRepeatMode.one);
      } else {
        await setRepeatMode(AudioServiceRepeatMode.none);
      }
    } else if (name.startsWith('like')) {
      // LOGIKA UNTUK LIKE/UNLIKE DARI LOCKSCREEN
      final currentMedia = mediaItem.value;
      if (currentMedia != null) {
        final songId = currentMedia.extras?['id']?.toString();
        if (songId != null) {
          final song = LocalSongModel(
            id: songId,
            title: currentMedia.title,
            artist: currentMedia.artist ?? 'Unknown',
            uri: currentMedia.id,
            duration: currentMedia.duration?.inMilliseconds ?? 0,
          );
          await StorageService.toggleLike(song);
          _broadcastState(_player.playbackEvent); // Memaksa update icon notifikasi
        }
      }
    } else if (name == 'reorder' && extras != null) {
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
    final loopMode = _player.loopMode;
    final shuffleModeEnabled = _player.shuffleModeEnabled;

    final songId = mediaItem.value?.extras?['id']?.toString() ?? '';
    final isLiked = StorageService.isLiked(songId); // Mengecek status Hive Database

    final likeControl = MediaControl.custom(
      androidIcon: isLiked ? 'drawable/ic_favorite_on' : 'drawable/ic_favorite_off',
      label: 'Like',
      name: isLiked ? 'like_on' : 'like_off', // Cache Busting untuk Android
    );

    final shuffleIcon = shuffleModeEnabled ? 'drawable/ic_shuffle_on' : 'drawable/ic_shuffle_off';
    final repeatIcon = loopMode == LoopMode.one 
        ? 'drawable/ic_repeat_one_on' 
        : loopMode == LoopMode.all 
            ? 'drawable/ic_repeat_on' 
            : 'drawable/ic_repeat_off';

    final shuffleControl = MediaControl.custom(
      androidIcon: shuffleIcon,
      label: 'Shuffle',
      name: shuffleModeEnabled ? 'shuffle_on' : 'shuffle_off',
    );

    final repeatControl = MediaControl.custom(
      androidIcon: repeatIcon,
      label: 'Repeat',
      name: loopMode == LoopMode.one 
          ? 'repeat_one' 
          : loopMode == LoopMode.all 
              ? 'repeat_all' 
              : 'repeat_off',
    );

    playbackState.add(playbackState.value.copyWith(
      controls: [
        likeControl, // MENAMBAHKAN TOMBOL LIKE DI PALING KIRI
        MediaControl.skipToPrevious, 
        if (_player.playing) MediaControl.pause else MediaControl.play, 
        MediaControl.skipToNext, 
        repeatControl, 
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setShuffleMode,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [1, 2, 3], // Index [1,2,3] = Prev, Play/Pause, Next untuk Compact View
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
      
      shuffleMode: shuffleModeEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: loopMode == LoopMode.one 
          ? AudioServiceRepeatMode.one 
          : loopMode == LoopMode.all 
              ? AudioServiceRepeatMode.all 
              : AudioServiceRepeatMode.none,
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