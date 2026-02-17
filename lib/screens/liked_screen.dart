import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';

class LikedScreen extends ConsumerWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                ),
              ),
            ),
            title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          likedSongs.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No liked songs yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = likedSongs[index];
                        return Dismissible(
                          key: ValueKey('liked_${song.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ref.read(likedSongsProvider.notifier).toggleLike(song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from Liked Songs')),
                            );
                          },
                          child: SongTile(
                            song: song,
                            onTap: () async {
                              final handler = ref.read(audioHandlerProvider);
                              final mediaItems = likedSongs.map((s) => s.toMediaItem()).toList();
                              
                              await handler.updateQueue(mediaItems);
                              await handler.skipToQueueItem(index);
                              await handler.play();
                            },
                          ),
                        );
                      },
                      childCount: likedSongs.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}