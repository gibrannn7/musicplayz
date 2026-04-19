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
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: _buildArtwork(),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(song.duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            color: Colors.grey.shade400,
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildArtwork() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: (song.customCoverPath != null && File(song.customCoverPath!).existsSync())
            ? Image.file(
                File(song.customCoverPath!),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                // BEST PRACTICE: Mencegah RAM bocor saat meload image resolusi tinggi
                cacheWidth: 150, 
              )
            : QueryArtworkWidget(
                id: int.parse(song.id),
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                // OPTIMASI: QueryArtworkWidget sudah membatasi size, tapi kita pastikan kualitasnya 'Low/Medium' untuk list
                artworkQuality: FilterQuality.low,
                nullArtworkWidget: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
              ),
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