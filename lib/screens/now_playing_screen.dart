import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_state_provider.dart';
import '../core/audio_handler.dart';
import '../providers/playlist_provider.dart';
import '../models/song_model.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);
    final progressAsync = ref.watch(progressProvider);
    final likedSongs = ref.watch(likedSongsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: mediaItemAsync.when(
        data: (mediaItem) {
          if (mediaItem == null) return const Center(child: Text('Nothing playing'));

          final playbackState = playbackStateAsync.value;
          final isPlaying = playbackState?.playing ?? false;
          final isLiked = likedSongs.any((s) => s.uri == mediaItem.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Album Art
                Center(
                  child: QueryArtworkWidget(
                    id: int.parse(mediaItem.extras?['id'] ?? '0'),
                    type: ArtworkType.AUDIO,
                    artworkWidth: 300,
                    artworkHeight: 300,
                    artworkBorder: BorderRadius.circular(20),
                    nullArtworkWidget: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.music_note, size: 100, color: Colors.grey[400]),
                    ),
                  ),
                ),

                // Title and Artist
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
                    ),
                  ],
                ),

                // Progress Bar
                ProgressBar(
                  progress: progressAsync.value ?? Duration.zero,
                  total: mediaItem.duration ?? Duration.zero,
                  onSeek: (duration) {
                    ref.read(audioHandlerProvider).seek(duration);
                  },
                ),

                // Main Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {}, // Implement shuffle logic
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
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
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: () => ref.read(audioHandlerProvider).skipToNext(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () {}, // Implement repeat logic
                    ),
                  ],
                ),

                // Bottom Buttons
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
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                      color: isLiked ? Colors.red : null,
                      onPressed: () {
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showSleepTimer(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            const ListTile(title: Text('Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold))),
            _timerOption(context, ref, '15 Minutes', const Duration(minutes: 15)),
            _timerOption(context, ref, '30 Minutes', const Duration(minutes: 30)),
            _timerOption(context, ref, '45 Minutes', const Duration(minutes: 45)),
            _timerOption(context, ref, '1 Hour', const Duration(hours: 1)),
            _timerOption(context, ref, '2 Hours', const Duration(hours: 2)),
            ListTile(
              title: const Text('Cancel Timer'),
              onTap: () {
                final handler = ref.read(audioHandlerProvider) as MyAudioHandler;
                handler.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _timerOption(BuildContext context, WidgetRef ref, String label, Duration duration) {
    return ListTile(
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
    // Basic placeholder for playlist picker
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final playlists = ref.watch(playlistProvider);
        return Column(
          children: [
            const ListTile(title: Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
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
