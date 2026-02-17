import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: albumsAsync.when(
        data: (albums) {
          if (albums.isEmpty) {
            return const Center(child: Text('No albums found', style: TextStyle(color: Colors.grey)));
          }
          return CustomScrollView(
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
                title: const Text('Albums', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16).copyWith(bottom: 140),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final album = albums[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: QueryArtworkWidget(
                                    id: album.id,
                                    type: ArtworkType.ALBUM,
                                    artworkFit: BoxFit.cover,
                                    nullArtworkWidget: Container(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.album, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      album.album,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      album.artist ?? 'Unknown',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: albums.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class AlbumDetailScreen extends ConsumerWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumSongsAsync = ref.watch(albumSongsProvider(album.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: albumSongsAsync.when(
        data: (songs) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                      title: Text(
                        album.album,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      background: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.transparent],
                            stops: [0.5, 1.0],
                          ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                        },
                        blendMode: BlendMode.dstIn,
                        child: QueryArtworkWidget(
                          id: album.id,
                          type: ArtworkType.ALBUM,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.album, size: 100, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (songs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No playable songs in this album', style: TextStyle(color: Colors.grey))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SongTile(
                          song: songs[index],
                          onTap: () async {
                            final handler = ref.read(audioHandlerProvider);
                            final mediaItems = songs.map((s) => s.toMediaItem()).toList();
                            await handler.updateQueue(mediaItems);
                            await handler.skipToQueueItem(index);
                            await handler.play();
                          },
                        );
                      },
                      childCount: songs.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}