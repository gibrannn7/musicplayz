import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../core/audio_handler.dart';
import '../models/song_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(filteredLibraryProvider);
    
    final searchResults = _searchQuery.isEmpty 
        ? <LocalSongModel>[] 
        : library.where((song) {
            return song.title.toLowerCase().contains(_searchQuery) || 
                   song.artist.toLowerCase().contains(_searchQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search songs or artists...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? const Center(child: Text('Type to start searching', style: TextStyle(color: Colors.grey)))
          : searchResults.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return SongTile(
                      song: searchResults[index],
                      onTap: () async {
                        final handler = ref.read(audioHandlerProvider);
                        final mediaItems = searchResults.map((s) => s.toMediaItem()).toList();
                        
                        await handler.updateQueue(mediaItems);
                        await handler.skipToQueueItem(index);
                        await handler.play();
                      },
                    );
                  },
                ),
    );
  }
}