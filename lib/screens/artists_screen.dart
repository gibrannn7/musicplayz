import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider);

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
            title: const Text('Artists', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          artists.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('No artists found', style: TextStyle(color: Colors.grey))),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artist = artists[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          title: Text(artist, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistDetailScreen(artistName: artist)));
                          },
                        );
                      },
                      childCount: artists.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class ArtistDetailScreen extends ConsumerWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistSongs = ref.watch(artistSongsProvider(artistName));

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
            title: Text(artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SongTile(
                    song: artistSongs[index],
                    onTap: () async {
                      final handler = ref.read(audioHandlerProvider);
                      final mediaItems = artistSongs.map((s) => s.toMediaItem()).toList();
                      await handler.updateQueue(mediaItems);
                      await handler.skipToQueueItem(index);
                      await handler.play();
                    },
                  );
                },
                childCount: artistSongs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}