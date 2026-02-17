import 'dart:io';
import 'package:hive/hive.dart';
import 'package:audio_service/audio_service.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class LocalSongModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String title;
  @HiveField(2) String artist;
  @HiveField(3) final String uri;
  @HiveField(4) final int duration;
  @HiveField(5) bool isLiked;
  @HiveField(6) int playCount;
  @HiveField(7) DateTime? lastPlayed;
  @HiveField(8) String? customTitle;
  @HiveField(9) String? customArtist;
  @HiveField(10) String? customCoverPath;
  @HiveField(11) final int dateAdded;

  LocalSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.duration,
    this.isLiked = false,
    this.playCount = 0,
    this.lastPlayed,
    this.customTitle,
    this.customArtist,
    this.customCoverPath,
    this.dateAdded = 0,
  });

  MediaItem toMediaItem() {
    Uri? artUri;
    if (customCoverPath != null && File(customCoverPath!).existsSync()) {
      artUri = Uri.file(customCoverPath!);
    } else {
      artUri = Uri.parse('asset:///assets/images/Vinyl_record.jpg');
    }

    return MediaItem(
      id: uri,
      title: customTitle ?? title,
      artist: customArtist ?? artist,
      duration: Duration(milliseconds: duration),
      artUri: artUri,
      extras: {'id': id},
    );
  }
}