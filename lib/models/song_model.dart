import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class LocalSongModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String uri;

  @HiveField(4)
  final int duration;

  @HiveField(5)
  bool isLiked;

  LocalSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.duration,
    this.isLiked = false,
  });
}
