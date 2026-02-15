import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'playlist_screen.dart';
import 'liked_screen.dart';
import 'queue_screen.dart';
import '../widgets/mini_player.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlaylistScreen(),
    const LikedScreen(),
    const QueueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan body langsung tanpa Stack yang kompleks
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlist'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Liked'),
              BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'Queue'),
            ],
          ),
        ],
      ),
    );
  }
}
