import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import '../models/song_model.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'top_songs_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final mostPlayed = ref.watch(mostPlayedProvider);
    final filteredLibrary = ref.watch(filteredLibraryProvider);
    final currentSort = ref.watch(sortTypeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: libraryAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found on device'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(libraryProvider.notifier).loadLibrary();
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
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
                  title: Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 30, errorBuilder: (c, e, s) => const Icon(Icons.music_note)),
                      const SizedBox(width: 12),
                      const Text('MusicPlayz', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                      },
                    ),
                  ],
                ),
                
                if (recentlyPlayed.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildHorizontalSection(
                        context, 
                        ref, 
                        'Recently Played', 
                        recentlyPlayed, 
                        isSquare: false,
                        onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      ),
                    ),
                  ),
                if (mostPlayed.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHorizontalSection(
                      context, 
                      ref, 
                      'Most Played', 
                      mostPlayed, 
                      isSquare: true,
                      onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopSongsScreen())),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('All Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        PopupMenuButton<SongSortType>(
                          initialValue: currentSort,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95),
                          elevation: 8,
                          position: PopupMenuPosition.under,
                          onSelected: (val) => ref.read(sortTypeProvider.notifier).state = val,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: SongSortType.az,
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, color: currentSort == SongSortType.az ? Theme.of(context).colorScheme.primary : Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(
                                    'A to Z', 
                                    style: TextStyle(
                                      color: currentSort == SongSortType.az ? Theme.of(context).colorScheme.primary : null, 
                                      fontWeight: currentSort == SongSortType.az ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: SongSortType.dateAdded,
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: currentSort == SongSortType.dateAdded ? Theme.of(context).colorScheme.primary : Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Newest Added', 
                                    style: TextStyle(
                                      color: currentSort == SongSortType.dateAdded ? Theme.of(context).colorScheme.primary : null, 
                                      fontWeight: currentSort == SongSortType.dateAdded ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(currentSort == SongSortType.az ? Icons.sort_by_alpha : Icons.access_time, size: 18),
                                const SizedBox(width: 8),
                                Text(currentSort == SongSortType.az ? 'A-Z' : 'Newest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SongTile(
                          song: filteredLibrary[index],
                          onTap: () => _playList(ref, filteredLibrary, index),
                        );
                      },
                      childCount: filteredLibrary.length,
                    ),
                  ),
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

  Widget _buildHorizontalSection(BuildContext context, WidgetRef ref, String title, List<LocalSongModel> items, {required bool isSquare, VoidCallback? onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text('See All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
            ],
          ),
        ),
        SizedBox(
          height: isSquare ? 150 : 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final song = items[index];
              return GestureDetector(
                onTap: () => _playList(ref, items, index),
                child: Container(
                  width: isSquare ? 110 : 200,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(isSquare ? 'assets/images/Abstract_dark_bg.jpg' : 'assets/images/Vinyl_record.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _playList(WidgetRef ref, List<LocalSongModel> playlist, int initialIndex) async {
    final handler = ref.read(audioHandlerProvider);
    final mediaItems = playlist.map((s) => s.toMediaItem()).toList();
    
    await handler.updateQueue(mediaItems);
    await handler.skipToQueueItem(initialIndex);
    await handler.play();
  }
}