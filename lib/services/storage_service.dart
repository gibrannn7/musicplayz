import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class StorageService {
  static const String likedSongsBoxName = 'liked_songs';
  static const String playlistsBoxName = 'playlists';
  static const String metadataBoxName = 'song_metadata';

  static Box<LocalSongModel> get _likedSongsBox => Hive.box<LocalSongModel>(likedSongsBoxName);
  static Box<PlaylistModel> get _playlistsBox => Hive.box<PlaylistModel>(playlistsBoxName);
  static Box<LocalSongModel> get _metadataBox => Hive.box<LocalSongModel>(metadataBoxName);

  // BARIS BARU: Stream untuk mendengarkan perubahan Hive secara Live
  static Stream<BoxEvent> watchLikedSongs() => _likedSongsBox.watch();

  static LocalSongModel? getSongMetadata(String id) {
    return _metadataBox.get(id);
  }

  static Future<void> saveSongMetadata(LocalSongModel song) async {
    await _metadataBox.put(song.id, song);
  }

  static Future<void> recordPlay(LocalSongModel song) async {
    final existingData = _metadataBox.get(song.id);
    if (existingData != null) {
      existingData.playCount += 1;
      existingData.lastPlayed = DateTime.now();
      await existingData.save();
    } else {
      song.playCount = 1;
      song.lastPlayed = DateTime.now();
      await _metadataBox.put(song.id, song);
    }
  }

  static List<LocalSongModel> getLikedSongs() => _likedSongsBox.values.toList();

  static Future<void> toggleLike(LocalSongModel song) async {
    if (isLiked(song.id)) {
      await _likedSongsBox.delete(song.id);
      song.isLiked = false;
    } else {
      song.isLiked = true;
      await _likedSongsBox.put(song.id, song);
    }
  }

  static bool isLiked(String songId) => _likedSongsBox.containsKey(songId);

  static List<PlaylistModel> getPlaylists() => _playlistsBox.values.toList();

  static Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final playlist = PlaylistModel(id: id, name: name, songs: [], createdAt: DateTime.now());
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

  static Future<void> updatePlaylistCover(String id, String imagePath) async {
    final playlist = _playlistsBox.get(id);
    if (playlist != null) {
      playlist.coverImagePath = imagePath;
      await playlist.save();
    }
  }
}