import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'home_screen.dart';
import 'playlist_screen.dart';
import 'liked_screen.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparan agar Aura terlihat
      body: Stack(
        children: [
          // Konten Utama
          _screens[_selectedIndex],
          
          // Area Bawah: Mini Player & Floating Nav Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                
                // Floating Glassmorphism Bottom Nav
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                        ),
                        child: GNav(
                          gap: 8,
                          activeColor: Colors.white,
                          iconSize: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          duration: const Duration(milliseconds: 400),
                          tabBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          color: Colors.grey.shade400,
                          tabs: const [
                            GButton(icon: Icons.home_rounded, text: 'Home'),
                            GButton(icon: Icons.library_music_rounded, text: 'Playlist'),
                            GButton(icon: Icons.favorite_rounded, text: 'Liked'),
                          ],
                          selectedIndex: _selectedIndex,
                          onTabChange: (index) {
                            setState(() => _selectedIndex = index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}