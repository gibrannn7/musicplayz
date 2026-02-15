import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import 'package:audio_service/audio_service.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? const Center(child: Text('No playlists created yet'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songs.length} songs'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(playlistProvider.notifier).deletePlaylist(playlist.id),
                  ),
                  onTap: () => _showPlaylistSongs(context, ref, playlist),
                );
              },
            ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(playlistProvider.notifier).createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSongs(BuildContext context, WidgetRef ref, dynamic playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(playlist.name)),
          body: playlist.songs.isEmpty
              ? const Center(child: Text('This playlist is empty'))
              : ListView.builder(
                  itemCount: playlist.songs.length,
                  itemBuilder: (context, index) {
                    final song = playlist.songs[index];
                    return SongTile(
                      song: song,
                      onTap: () async {
                        final handler = ref.read(audioHandlerProvider);
                        final mediaItems = playlist.songs.map<MediaItem>((s) => MediaItem(
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
                ),
        ),
      ),
    );
  }
}
