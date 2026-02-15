// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalSongModelAdapter extends TypeAdapter<LocalSongModel> {
  @override
  final int typeId = 0;

  @override
  LocalSongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalSongModel(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      uri: fields[3] as String,
      duration: fields[4] as int,
      isLiked: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalSongModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.uri)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.isLiked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalSongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
