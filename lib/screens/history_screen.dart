import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historySongs = ref.watch(fullHistoryProvider);

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
            title: const Text('Listening History', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          historySongs.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text('No listening history yet', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SongTile(
                          song: historySongs[index],
                          onTap: () async {
                            final handler = ref.read(audioHandlerProvider);
                            final mediaItems = historySongs.map((s) => s.toMediaItem()).toList();
                            await handler.updateQueue(mediaItems);
                            await handler.skipToQueueItem(index);
                            await handler.play();
                          },
                        );
                      },
                      childCount: historySongs.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}