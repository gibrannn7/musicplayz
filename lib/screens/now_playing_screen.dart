import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:lottie/lottie.dart'; // IMPORT LOTTIE DITAMBAHKAN
import '../providers/audio_state_provider.dart';
import '../providers/queue_provider.dart';
import '../core/audio_handler.dart';
import '../providers/playlist_provider.dart';
import '../models/song_model.dart';
import '../services/storage_service.dart';
import 'dart:math' as math;

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  int _queueRenderLimit = 20;
  bool _showLikeAnimation = false; // STATE UNTUK TRIGGER LOTTIE

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      setState(() {
        _queueRenderLimit += 20;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);
    final progressAsync = ref.watch(progressProvider);
    final likedSongs = ref.watch(likedSongsProvider);
    final queueAsync = ref.watch(queueProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.09,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                  Navigator.pop(context);
                }
              },
              child: SafeArea(
                bottom: false,
                child: mediaItemAsync.when(
                  data: (mediaItem) {
                    if (mediaItem == null) return const Center(child: Text('Nothing playing'));

                    final playbackState = playbackStateAsync.value;
                    final isPlaying = playbackState?.playing ?? false;
                    final isLiked = likedSongs.any((s) => s.uri == mediaItem.id);
                    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
                    final shuffleMode = playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;

                    final songId = mediaItem.extras?['id'] ?? '0';
                    final metadata = StorageService.getSongMetadata(songId);
                    final customCoverPath = metadata?.customCoverPath;

                    Widget artworkWidget;
                    if (customCoverPath != null && File(customCoverPath).existsSync()) {
                      artworkWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(customCoverPath),
                          width: 320,
                          height: 320,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      artworkWidget = QueryArtworkWidget(
                        id: int.parse(songId),
                        type: ArtworkType.AUDIO,
                        artworkWidth: 320,
                        artworkHeight: 320,
                        artworkBorder: BorderRadius.circular(20),
                        nullArtworkWidget: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.music_note, size: 100, color: Colors.grey[400]),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text('Now Playing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 48), 
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // PERUBAHAN: MEMBUNGKUS ARTWORK DENGAN STACK UNTUK LOTTIE OVERLAY
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      artworkWidget,
                                      if (_showLikeAnimation)
                                        IgnorePointer(
                                          child: Lottie.asset(
                                            'assets/animations/love.json',
                                            width: 250,
                                            height: 250,
                                            repeat: false,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      mediaItem.title,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mediaItem.artist ?? 'Unknown Artist',
                                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),

                                ProgressBar(
                                  progress: progressAsync.value ?? Duration.zero,
                                  total: mediaItem.duration ?? Duration.zero,
                                  baseBarColor: Colors.grey[300],
                                  progressBarColor: Theme.of(context).colorScheme.primary,
                                  thumbColor: Theme.of(context).colorScheme.primary,
                                  onSeek: (duration) {
                                    ref.read(audioHandlerProvider).seek(duration);
                                  },
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.shuffle,
                                        color: shuffleMode == AudioServiceShuffleMode.all
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        final enable = shuffleMode == AudioServiceShuffleMode.none;
                                        ref.read(audioHandlerProvider).setShuffleMode(
                                          enable ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous, size: 40),
                                      onPressed: () => ref.read(audioHandlerProvider).skipToPrevious(),
                                    ),
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: IconButton(
                                        icon: Icon(
                                          isPlaying ? Icons.pause : Icons.play_arrow,
                                          size: 40,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                        onPressed: () {
                                          if (isPlaying) {
                                            ref.read(audioHandlerProvider).pause();
                                          } else {
                                            ref.read(audioHandlerProvider).play();
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next, size: 40),
                                      onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        repeatMode == AudioServiceRepeatMode.one
                                            ? Icons.repeat_one
                                            : Icons.repeat,
                                        color: repeatMode != AudioServiceRepeatMode.none
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        final handler = ref.read(audioHandlerProvider);
                                        if (repeatMode == AudioServiceRepeatMode.none) {
                                          handler.setRepeatMode(AudioServiceRepeatMode.all);
                                        } else if (repeatMode == AudioServiceRepeatMode.all) {
                                          handler.setRepeatMode(AudioServiceRepeatMode.one);
                                        } else {
                                          handler.setRepeatMode(AudioServiceRepeatMode.none);
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.playlist_add),
                                      onPressed: () => _showPlaylistPicker(context, ref, mediaItem),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.timer_outlined),
                                      onPressed: () => _showSleepTimer(context, ref),
                                    ),
                                    // PERUBAHAN: LOGIKA TRIGGER ANIMASI LOTTIE SAAT DISUKAI
                                    IconButton(
                                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                                      color: isLiked ? Colors.red : Colors.grey,
                                      onPressed: () {
                                        if (!isLiked) {
                                          setState(() {
                                            _showLikeAnimation = true;
                                          });
                                          // Menghilangkan animasi setelah 2 detik (sesuai durasi wajar lottie)
                                          Future.delayed(const Duration(milliseconds: 2000), () {
                                            if (mounted) {
                                              setState(() {
                                                _showLikeAnimation = false;
                                              });
                                            }
                                          });
                                        }
                                        final song = LocalSongModel(
                                          id: mediaItem.extras?['id'] ?? '0',
                                          title: mediaItem.title,
                                          artist: mediaItem.artist ?? 'Unknown Artist',
                                          uri: mediaItem.id,
                                          duration: mediaItem.duration?.inMilliseconds ?? 0,
                                        );
                                        ref.read(likedSongsProvider.notifier).toggleLike(song);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ),

          // QUEUE BOTTOM SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.09,
            minChildSize: 0.09,
            maxChildSize: 0.85,
            snap: true,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                            ),
                            const SizedBox(height: 8),
                            const Text('Up Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      
                      queueAsync.when(
                        data: (queue) {
                          if (queue.isEmpty) {
                            return const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: Text('Queue is empty')),
                            );
                          }
                          final currentItem = ref.watch(currentMediaItemProvider).value;
                          final limit = math.min(queue.length, _queueRenderLimit);

                          return SliverPadding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
                            sliver: SliverReorderableList(
                              itemCount: limit,
                              onReorder: (oldIndex, newIndex) {
                                ref.read(audioHandlerProvider).customAction('reorder', {
                                  'oldIndex': oldIndex,
                                  'newIndex': newIndex,
                                });
                              },
                              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                return Material(
                                  elevation: 10,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  child: child,
                                );
                              },
                              itemBuilder: (context, index) {
                                final item = queue[index];
                                final isCurrent = currentItem?.id == item.id;
                                final itemKey = ValueKey('${item.id}_$index');

                                return ReorderableDelayedDragStartListener(
                                  key: itemKey,
                                  index: index,
                                  child: Dismissible(
                                    key: ValueKey('dismiss_${item.id}_$index'),
                                    direction: DismissDirection.horizontal,
                                    onDismissed: (_) {
                                      ref.read(audioHandlerProvider).removeQueueItemAt(index);
                                    },
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    child: ListTile(
                                      leading: isCurrent
                                          ? Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary)
                                          : Text('${index + 1}', style: const TextStyle(color: Colors.grey)),
                                      title: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                                        ),
                                      ),
                                      subtitle: Text(item.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      trailing: ReorderableDragStartListener(
                                        index: index,
                                        child: const Icon(Icons.drag_handle, size: 28, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        ref.read(audioHandlerProvider).skipToQueueItem(index);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                        error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSleepTimer(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _timerOption(context, ref, '15 Minutes', const Duration(minutes: 15)),
            _timerOption(context, ref, '30 Minutes', const Duration(minutes: 30)),
            _timerOption(context, ref, '45 Minutes', const Duration(minutes: 45)),
            _timerOption(context, ref, '1 Hour', const Duration(hours: 1)),
            _timerOption(context, ref, '2 Hours', const Duration(hours: 2)),
            ListTile(
              leading: const Icon(Icons.timer_off),
              title: const Text('Cancel Timer', style: TextStyle(color: Colors.red)),
              onTap: () {
                final handler = ref.read(audioHandlerProvider) as MyAudioHandler;
                handler.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _timerOption(BuildContext context, WidgetRef ref, String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: Text(label),
      onTap: () {
        final handler = ref.read(audioHandlerProvider) as MyAudioHandler;
        handler.setSleepTimer(duration);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sleep timer set for $label')),
        );
      },
    );
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref, MediaItem mediaItem) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final playlists = ref.watch(playlistProvider);
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: playlists.isEmpty 
                  ? const Center(child: Text('No playlists available. Create one first!'))
                  : ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.playlist_add_check),
                          title: Text(playlist.name),
                          onTap: () {
                            final song = LocalSongModel(
                              id: mediaItem.extras?['id'] ?? '0',
                              title: mediaItem.title,
                              artist: mediaItem.artist ?? 'Unknown Artist',
                              uri: mediaItem.id,
                              duration: mediaItem.duration?.inMilliseconds ?? 0,
                            );
                            ref.read(playlistProvider.notifier).addSongToPlaylist(playlist.id, song);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added to ${playlist.name}')),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}