import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import '../widgets/premium_modal.dart';
import '../models/playlist_model.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Tembus ke Aura
      body: CustomScrollView(
        slivers: [
          // HEADER KACA (GLASSMORPHISM)
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
            title: const Text('Your Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreatePlaylistDialog(context, ref),
              ),
            ],
          ),

          // KONTEN GRID
          playlists.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('No playlists created yet', style: TextStyle(color: Colors.grey))),
                )
              : SliverPadding(
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
                        final playlist = playlists[index];
                        return GestureDetector(
                          onTap: () => _showPlaylistSongs(context, ref, playlist),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: playlist.coverImagePath != null && File(playlist.coverImagePath!).existsSync()
                                    ? FileImage(File(playlist.coverImagePath!)) as ImageProvider
                                    : const AssetImage('assets/images/default_playlist.jpg'),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${playlist.songs.length} songs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _showPlaylistOptions(context, ref, playlist),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: playlists.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showPremiumModal(
      context,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change Playlist Cover'),
            onTap: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                final appDir = await getApplicationDocumentsDirectory();
                final fileName = 'playlist_${playlist.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
                ref.read(playlistProvider.notifier).updatePlaylistCover(playlist.id, savedImage.path);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Playlist', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Tutup bottom sheet opsi
              _showDeleteConfirmationDialog(context, ref, playlist); // Tampilkan Dialog Konfirmasi
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // DIALOG KONFIRMASI HAPUS PLAYLIST
  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref.read(playlistProvider.notifier).deletePlaylist(playlist.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playlist deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showPremiumModal(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create New Playlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Playlist Name',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      ref.read(playlistProvider.notifier).createPlaylist(controller.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSongs(BuildContext context, WidgetRef ref, PlaylistModel playlist) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlistId: playlist.id)));
  }
}

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final playlist = playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => PlaylistModel(id: '', name: 'Not Found', songs: [], createdAt: DateTime.now()),
    );

    return Scaffold(
      backgroundColor: Colors.transparent, // Membiarkan Aura Tembus
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
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
                    playlist.name,
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
                    child: playlist.coverImagePath != null && File(playlist.coverImagePath!).existsSync()
                        ? Image.file(File(playlist.coverImagePath!), fit: BoxFit.cover)
                        : Image.asset('assets/images/default_playlist.jpg', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text('${playlist.songs.length} songs', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          ),

          playlist.songs.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('This playlist is empty', style: TextStyle(color: Colors.grey))),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = playlist.songs[index];
                        
                        // MENAMBAHKAN FITUR SWIPE TO DISMISS UNTUK HAPUS LAGU DARI PLAYLIST
                        return Dismissible(
                          key: ValueKey('playlist_${playlist.id}_${song.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ref.read(playlistProvider.notifier).removeSongFromPlaylist(playlist.id, song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Song removed from playlist')),
                            );
                          },
                          child: SongTile(
                            song: song,
                            onTap: () async {
                              final handler = ref.read(audioHandlerProvider);
                              final mediaItems = playlist.songs.map((s) => s.toMediaItem()).toList();
                              
                              await handler.updateQueue(mediaItems);
                              await handler.skipToQueueItem(index);
                              await handler.play();
                            },
                          ),
                        );
                      },
                      childCount: playlist.songs.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}