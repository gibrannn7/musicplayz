import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/permission_handler.dart';
import '../models/song_model.dart';
import '../services/storage_service.dart';

final audioQueryProvider = Provider((ref) => OnAudioQuery());

final libraryProvider = FutureProvider<List<LocalSongModel>>((ref) async {
  final hasPermission = await AppPermissionHandler.requestStoragePermission();
  if (!hasPermission) return [];

  final query = ref.read(audioQueryProvider);
  final songs = await query.querySongs(
    sortType: null,
    orderType: OrderType.ASC_OR_SMALLER,
    uriType: UriType.EXTERNAL,
    ignoreCase: true,
  );

  return songs.map((song) {
    return LocalSongModel(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      uri: song.uri!,
      duration: song.duration ?? 0,
      isLiked: StorageService.isLiked(song.id.toString()),
    );
  }).toList();
});
