import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Playz', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: libraryAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found on device'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16), // Simplified padding
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongTile(
                song: song,
                onTap: () async {
                  final handler = ref.read(audioHandlerProvider);
                  final mediaItems = songs.map((s) => MediaItem(
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
