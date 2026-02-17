import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song_model.dart';
import 'premium_modal.dart';
import '../screens/metadata_editor_sheet.dart';

class SongTile extends StatelessWidget {
  final LocalSongModel song;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildArtwork(),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(song.duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildArtwork() {
    if (song.customCoverPath != null && File(song.customCoverPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(song.customCoverPath!),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }
    return QueryArtworkWidget(
      id: int.parse(song.id),
      type: ArtworkType.AUDIO,
      nullArtworkWidget: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.grey),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showPremiumModal(
      context,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Song Info & Cover'),
            onTap: () {
              Navigator.pop(context);
              showPremiumModal(
                context,
                child: MetadataEditorSheet(song: song),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}