import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class LikedScreen extends ConsumerWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Songs'),
      ),
      body: likedSongs.isEmpty
          ? const Center(child: Text('No liked songs yet'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: likedSongs.length,
              itemBuilder: (context, index) {
                final song = likedSongs[index];
                return SongTile(
                  song: song,
                  onTap: () async {
                    final handler = ref.read(audioHandlerProvider);
                    final mediaItems = likedSongs.map((s) => MediaItem(
                      id: s.uri,
                      title: s.title,
                      artist: s.artist,
                      duration: Duration(milliseconds: s.duration),
                      extras: {'id': s.id},
                    )).toList();
                    
                    await handler.updateQueue(mediaItems);
                    await handler.skipToQueueItem(index);
                    await handler.play();
                  },
                );
              },
            ),
    );
  }
}
