import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_state_provider.dart';
import '../core/audio_handler.dart';
import '../screens/now_playing_screen.dart';
import '../services/storage_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  // Animasi Transisi Halus (Slide-Up) layaknya Spotify
  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // Muncul dari bawah
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350), // Kecepatan Transisi
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(currentMediaItemProvider);
    final playbackStateAsync = ref.watch(playbackStateProvider);

    return mediaItemAsync.when(
      data: (mediaItem) {
        if (mediaItem == null) return const SizedBox.shrink();

        final playbackState = playbackStateAsync.value;
        final isPlaying = playbackState?.playing ?? false;

        final songId = mediaItem.extras?['id'] ?? '0';
        final metadata = StorageService.getSongMetadata(songId);
        final customCoverPath = metadata?.customCoverPath;

        // Memaksa Artwork presisi dan tidak miring/penyok
        Widget artworkWidget;
        if (customCoverPath != null && File(customCoverPath).existsSync()) {
          artworkWidget = Image.file(
            File(customCoverPath),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          );
        } else {
          artworkWidget = QueryArtworkWidget(
            id: int.parse(songId),
            type: ArtworkType.AUDIO,
            artworkWidth: 48,
            artworkHeight: 48,
            artworkFit: BoxFit.cover, // Kunci utama agar tidak miring
            nullArtworkWidget: Container(
              width: 48,
              height: 48,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.music_note, color: Colors.grey[500]),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openNowPlaying(context),
          // Deteksi usapan ke atas (Swipe Up)
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              _openNowPlaying(context);
            }
          },
          child: Container(
            height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: artworkWidget,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGIKA TEKS CERDAS (MARQUEE ATAU DIAM)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
                          
                          // Kalkulasi lebar teks vs lebar layar
                          final span = TextSpan(text: mediaItem.title, style: textStyle);
                          final tp = TextPainter(text: span, maxLines: 1, textDirection: TextDirection.ltr);
                          tp.layout(maxWidth: double.infinity);

                          // Jika teks lebih panjang dari sisa ruang layar, aktifkan animasi jalan
                          if (tp.width > constraints.maxWidth) {
                            return SizedBox(
                              height: 20,
                              child: Marquee(
                                text: mediaItem.title,
                                style: textStyle,
                                scrollAxis: Axis.horizontal,
                                blankSpace: 30.0, // Jeda yang cukup agar tidak terkesan aneh
                                velocity: 30.0,
                                pauseAfterRound: const Duration(seconds: 2),
                                startPadding: 0.0,
                                accelerationDuration: const Duration(seconds: 1),
                                accelerationCurve: Curves.linear,
                                decelerationDuration: const Duration(milliseconds: 500),
                                decelerationCurve: Curves.easeOut,
                              ),
                            );
                          } else {
                            // Jika teks pendek, diam saja!
                            return Text(
                              mediaItem.title,
                              style: textStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mediaItem.artist ?? 'Unknown Artist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                  onPressed: () {
                    final handler = ref.read(audioHandlerProvider);
                    if (isPlaying) {
                      handler.pause();
                    } else {
                      handler.play();
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}