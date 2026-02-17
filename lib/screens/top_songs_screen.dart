import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';

class TopSongsScreen extends ConsumerWidget {
  const TopSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topSongs = ref.watch(top50Provider);

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
            title: const Text('Top 50 Most Played', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          topSongs.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text('No top songs yet', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = topSongs[index];
                        return Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: index < 3 ? Theme.of(context).colorScheme.primary : Colors.grey
                                ),
                              ),
                            ),
                            Expanded(
                              child: SongTile(
                                song: song,
                                onTap: () async {
                                  final handler = ref.read(audioHandlerProvider);
                                  final mediaItems = topSongs.map((s) => s.toMediaItem()).toList();
                                  await handler.updateQueue(mediaItems);
                                  await handler.skipToQueueItem(index);
                                  await handler.play();
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: topSongs.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}