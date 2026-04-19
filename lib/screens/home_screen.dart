import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // IMPORT BARU: UNTUK GETARAN (HAPTIC FEEDBACK)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import '../models/song_model.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'top_songs_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _draggingLetter; 
  final List<String> _alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".split('');

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter, List<LocalSongModel> songs) {
    int index = -1;
    if (letter == '#') {
      index = songs.indexWhere((s) => s.title.isNotEmpty && !RegExp(r'[a-zA-Z]').hasMatch(s.title[0]));
    } else {
      index = songs.indexWhere((s) => s.title.toUpperCase().startsWith(letter));
    }

    if (index != -1) {
      final recentlyPlayed = ref.read(recentlyPlayedProvider);
      final mostPlayed = ref.read(mostPlayedProvider);
      
      double startY = 110.0 + 54.0; 
      if (recentlyPlayed.isNotEmpty) startY += 190.0;
      if (mostPlayed.isNotEmpty) startY += 212.0;

      // ListTile tinggi standarnya sekitar 72px
      final offset = startY + (index * 72.0); 
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    }
  }

  void _updateDraggingLetter(double dy, double maxHeight, List<LocalSongModel> songs) {
    int index = (dy / maxHeight * _alphabets.length).clamp(0, _alphabets.length - 1).toInt();
    final letter = _alphabets[index];
    
    if (_draggingLetter != letter) {
      // BEST PRACTICE: Memberikan getaran halus setiap jari berpindah huruf!
      HapticFeedback.selectionClick(); 
      
      setState(() {
        _draggingLetter = letter;
      });
      _scrollToLetter(letter, songs);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 110, 
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: FlexibleSpaceBar(
                            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                            title: const Text(
                              'MusicPlayz', 
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)
                            ),
                            background: Container(color: Theme.of(context).colorScheme.surface.withOpacity(0.4)),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    
                    if (recentlyPlayed.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildHorizontalSection(
                            context, ref, 'Recently Played', recentlyPlayed, 
                            isSquare: false,
                            onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                          ),
                        ),
                      ),
                    
                    if (mostPlayed.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildHorizontalSection(
                          context, ref, 'Most Played', mostPlayed, 
                          isSquare: true,
                          onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopSongsScreen())),
                        ),
                      ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('All Songs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            
                            PopupMenuButton<SongSortType>(
                              initialValue: currentSort,
                              icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95),
                              position: PopupMenuPosition.under,
                              onSelected: (val) => ref.read(sortTypeProvider.notifier).state = val,
                              itemBuilder: (context) => [
                                _buildPopupItem(context, SongSortType.az, 'A to Z', currentSort),
                                _buildPopupItem(context, SongSortType.newest, 'Newest', currentSort),
                                _buildPopupItem(context, SongSortType.oldest, 'Oldest', currentSort),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: 140, 
                        // Jika mode AZ, kurangi padding kanan seukuran scroller (30px) + sedikit gap (2px)
                        right: currentSort == SongSortType.az ? 32 : 0 
                      ),
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

                // WIDGET A-Z SCROLLER YANG DIPERBESAR DAN ANTI OVERFLOW
                if (currentSort == SongSortType.az)
                  AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      double offset = 0.0;
                      if (_scrollController.hasClients) {
                        offset = _scrollController.offset;
                      }

                      double startY = 110.0 + 54.0; 
                      if (recentlyPlayed.isNotEmpty) startY += 190.0;
                      if (mostPlayed.isNotEmpty) startY += 212.0;

                      double pinnedY = MediaQuery.of(context).size.height * 0.18; // Naik sedikit agar pas di tengah
                      double topPosition = (startY - offset) > pinnedY ? (startY - offset) : pinnedY;

                      return Positioned(
                        right: 2, // Mepet kanan
                        top: topPosition,
                        height: 480, // TINGGI DIPERBESAR untuk mencegah Bottom Overflow
                        child: child!,
                      );
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onVerticalDragStart: (details) => _updateDraggingLetter(details.localPosition.dy, constraints.maxHeight, filteredLibrary),
                          onVerticalDragUpdate: (details) => _updateDraggingLetter(details.localPosition.dy, constraints.maxHeight, filteredLibrary),
                          onVerticalDragEnd: (_) => setState(() => _draggingLetter = null),
                          onTapCancel: () => setState(() => _draggingLetter = null),
                          child: Container(
                            width: 30, // LEBAR DIPERBESAR (sebelumnya 24) agar lebih mudah disentuh
                            color: Colors.transparent, 
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _alphabets.map((letter) {
                                final isSelected = _draggingLetter == letter;
                                return Text(
                                  letter, 
                                  style: TextStyle(
                                    // FONT DIPERBESAR
                                    fontSize: isSelected ? 15 : 11, 
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, 
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.8)
                                  )
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }
                    ),
                  ),

                // BUBBLE OVERLAY
                if (_draggingLetter != null)
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _draggingLetter!,
                        style: TextStyle(
                          fontSize: 40, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.primary
                        ),
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

  PopupMenuItem<SongSortType> _buildPopupItem(BuildContext context, SongSortType value, String label, SongSortType current) {
    final isSelected = current == value;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return PopupMenuItem(
      value: value,
      child: Text(
        label, 
        style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
      ),
    );
  }

  Widget _buildHorizontalSection(BuildContext context, WidgetRef ref, String title, List<LocalSongModel> items, {required bool isSquare, VoidCallback? onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final song = items[index];
              return GestureDetector(
                onTap: () => _playList(ref, items, index),
                child: Container(
                  width: isSquare ? 110 : 200,
                  margin: const EdgeInsets.only(right: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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