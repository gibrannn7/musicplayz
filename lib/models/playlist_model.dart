import 'package:hive/hive.dart';
import 'song_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) final List<LocalSongModel> songs;
  @HiveField(3) String? coverImagePath;
  @HiveField(4) DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songs,
    this.coverImagePath,
    required this.createdAt,
  });
}