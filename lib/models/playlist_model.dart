import 'package:hive/hive.dart';
import 'song_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<LocalSongModel> songs;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songs,
  });
}
