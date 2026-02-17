import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/permission_handler.dart';
import '../models/song_model.dart';
import '../services/storage_service.dart';

enum SongSortType { az, dateAdded }

final sortTypeProvider = StateProvider<SongSortType>((ref) => SongSortType.az);
final audioQueryProvider = Provider((ref) => OnAudioQuery());

class LibraryNotifier extends StateNotifier<AsyncValue<List<LocalSongModel>>> {
  final Ref ref;
  LibraryNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    state = const AsyncValue.loading();
    try {
      final hasPermission = await AppPermissionHandler.requestStoragePermission();
      if (!hasPermission) {
        state = const AsyncValue.data([]);
        return;
      }

      final query = ref.read(audioQueryProvider);
      final rawSongs = await query.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final mappedSongs = rawSongs.map((song) {
        final metadata = StorageService.getSongMetadata(song.id.toString());
        return LocalSongModel(
          id: song.id.toString(),
          title: metadata?.customTitle ?? song.title,
          artist: metadata?.customArtist ?? (song.artist ?? 'Unknown Artist'),
          uri: song.uri!,
          duration: song.duration ?? 0,
          isLiked: StorageService.isLiked(song.id.toString()),
          playCount: metadata?.playCount ?? 0,
          lastPlayed: metadata?.lastPlayed,
          customCoverPath: metadata?.customCoverPath,
          dateAdded: song.dateAdded ?? 0,
        );
      }).toList();

      state = AsyncValue.data(mappedSongs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, AsyncValue<List<LocalSongModel>>>((ref) {
  return LibraryNotifier(ref);
});

final mostPlayedProvider = Provider<List<LocalSongModel>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final filtered = library.where((s) => s.playCount > 0).toList();
  filtered.sort((a, b) => b.playCount.compareTo(a.playCount));
  return filtered.take(10).toList(); 
});

final recentlyPlayedProvider = Provider<List<LocalSongModel>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final filtered = library.where((s) => s.lastPlayed != null).toList();
  filtered.sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
  return filtered.take(10).toList(); 
});

// TASK 1: HISTORY DIBATASI MAKSIMAL 50
final fullHistoryProvider = Provider<List<LocalSongModel>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final filtered = library.where((s) => s.lastPlayed != null).toList();
  filtered.sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
  return filtered.take(50).toList(); 
});

final top50Provider = Provider<List<LocalSongModel>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final filtered = library.where((s) => s.playCount > 0).toList();
  filtered.sort((a, b) => b.playCount.compareTo(a.playCount));
  return filtered.take(50).toList();
});

final artistsProvider = Provider<List<String>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final artists = library.map((s) => s.artist).where((a) => a != '<unknown>' && a.trim().isNotEmpty).toSet().toList();
  artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return artists;
});

final artistSongsProvider = Provider.family<List<LocalSongModel>, String>((ref, artistName) {
  final library = ref.watch(libraryProvider).value ?? [];
  return library.where((s) => s.artist == artistName).toList();
});

final albumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final query = ref.read(audioQueryProvider);
  return await query.queryAlbums();
});

// TASK 1: PERBAIKAN MATCHER ALBUM AGAR TIDAK KOSONG
final albumSongsProvider = FutureProvider.family<List<LocalSongModel>, int>((ref, albumId) async {
  final query = ref.read(audioQueryProvider);
  final rawSongs = await query.queryAudiosFrom(AudiosFromType.ALBUM, albumId);
  final library = ref.read(libraryProvider).value ?? [];

  return rawSongs.map((rs) {
    try {
      // Fallback pencocokan yang lebih kuat: Jika ID OS berbeda, cocokkan berdasarkan Judul
      return library.firstWhere(
        (ls) => ls.id == rs.id.toString() || ls.title == rs.title
      );
    } catch (e) {
      return null;
    }
  }).whereType<LocalSongModel>().toList();
});

final filteredLibraryProvider = Provider<List<LocalSongModel>>((ref) {
  final library = ref.watch(libraryProvider).value ?? [];
  final sortType = ref.watch(sortTypeProvider);
  
  final list = List<LocalSongModel>.from(library);
  if (sortType == SongSortType.az) {
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  } else if (sortType == SongSortType.dateAdded) {
    list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }
  return list;
});