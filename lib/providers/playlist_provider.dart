import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/storage_service.dart';

class LikedSongsNotifier extends StateNotifier<List<LocalSongModel>> {
  LikedSongsNotifier() : super(StorageService.getLikedSongs());

  Future<void> toggleLike(LocalSongModel song) async {
    await StorageService.toggleLike(song);
    state = StorageService.getLikedSongs();
  }
}

final likedSongsProvider = StateNotifierProvider<LikedSongsNotifier, List<LocalSongModel>>((ref) {
  return LikedSongsNotifier();
});

class PlaylistNotifier extends StateNotifier<List<PlaylistModel>> {
  PlaylistNotifier() : super(StorageService.getPlaylists());

  Future<void> createPlaylist(String name) async {
    await StorageService.createPlaylist(name);
    state = StorageService.getPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await StorageService.deletePlaylist(id);
    state = StorageService.getPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, LocalSongModel song) async {
    await StorageService.addSongToPlaylist(playlistId, song);
    state = StorageService.getPlaylists();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await StorageService.removeSongFromPlaylist(playlistId, songId);
    state = StorageService.getPlaylists();
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<PlaylistModel>>((ref) {
  return PlaylistNotifier();
});
