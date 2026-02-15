import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class StorageService {
  static const String likedSongsBoxName = 'liked_songs';
  static const String playlistsBoxName = 'playlists';

  static Box<LocalSongModel> get _likedSongsBox => Hive.box<LocalSongModel>(likedSongsBoxName);
  static Box<PlaylistModel> get _playlistsBox => Hive.box<PlaylistModel>(playlistsBoxName);

  // Liked Songs
  static List<LocalSongModel> getLikedSongs() {
    return _likedSongsBox.values.toList();
  }

  static Future<void> toggleLike(LocalSongModel song) async {
    if (isLiked(song.id)) {
      await _likedSongsBox.delete(song.id);
      song.isLiked = false;
    } else {
      song.isLiked = true;
      await _likedSongsBox.put(song.id, song);
    }
  }

  static bool isLiked(String songId) {
    return _likedSongsBox.containsKey(songId);
  }

  // Playlists
  static List<PlaylistModel> getPlaylists() {
    return _playlistsBox.values.toList();
  }

  static Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final playlist = PlaylistModel(id: id, name: name, songs: []);
    await _playlistsBox.put(id, playlist);
  }

  static Future<void> deletePlaylist(String id) async {
    await _playlistsBox.delete(id);
  }

  static Future<void> addSongToPlaylist(String playlistId, LocalSongModel song) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.add(song);
        await playlist.save();
      }
    }
  }

  static Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      playlist.songs.removeWhere((s) => s.id == songId);
      await playlist.save();
    }
  }
}
