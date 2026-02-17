import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/song_model.dart';
import '../services/storage_service.dart';
import '../providers/library_provider.dart';

class MetadataEditorSheet extends ConsumerStatefulWidget {
  final LocalSongModel song;

  const MetadataEditorSheet({super.key, required this.song});

  @override
  ConsumerState<MetadataEditorSheet> createState() => _MetadataEditorSheetState();
}

class _MetadataEditorSheetState extends ConsumerState<MetadataEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.customTitle ?? widget.song.title);
    _artistController = TextEditingController(text: widget.song.customArtist ?? widget.song.artist);
    _selectedImagePath = widget.song.customCoverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _selectedImagePath = savedImage.path;
      });
    }
  }

  Future<void> _saveMetadata() async {
    final updatedSong = LocalSongModel(
      id: widget.song.id,
      title: widget.song.title,
      artist: widget.song.artist, 
      uri: widget.song.uri,
      duration: widget.song.duration,
      isLiked: widget.song.isLiked,
      playCount: widget.song.playCount,
      lastPlayed: widget.song.lastPlayed,
      customTitle: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      customArtist: _artistController.text.trim().isNotEmpty ? _artistController.text.trim() : null,
      customCoverPath: _selectedImagePath,
      dateAdded: widget.song.dateAdded,
    );

    await StorageService.saveSongMetadata(updatedSong);
    ref.read(libraryProvider.notifier).loadLibrary();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song info updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView memungkinkan isi form untuk di-scroll ketika tertutup keyboard
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit Song Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                image: _selectedImagePath != null && File(_selectedImagePath!).existsSync()
                    ? DecorationImage(image: FileImage(File(_selectedImagePath!)), fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: _selectedImagePath == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Change Cover', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Song Title',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _artistController,
            decoration: InputDecoration(
              labelText: 'Artist Name',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _saveMetadata,
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}