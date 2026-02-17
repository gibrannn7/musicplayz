import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'core/audio_handler.dart';
import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'screens/main_navigation.dart';
import 'core/theme.dart';
import 'widgets/premium_background.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(LocalSongModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlaylistModelAdapter());
    
    await Hive.openBox<LocalSongModel>('liked_songs');
    await Hive.openBox<PlaylistModel>('playlists');
    await Hive.openBox<LocalSongModel>('song_metadata');

    final audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.musicplayz.channel.audio',
        androidNotificationChannelName: 'Music Playz',
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    runApp(
      ProviderScope(
        overrides: [
          audioHandlerProvider.overrideWithValue(audioHandler),
        ],
        child: const MusicPlayzApp(),
      ),
    );
  } catch (e) {
    debugPrint('Initialization Error: $e');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
}

class MusicPlayzApp extends StatelessWidget {
  const MusicPlayzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'musicplayz',
      debugShowCheckedModeBanner: false,
      // Memaksa scaffold menjadi transparan agar background global terlihat
      theme: AppTheme.lightTheme.copyWith(scaffoldBackgroundColor: Colors.transparent),
      darkTheme: AppTheme.darkTheme.copyWith(scaffoldBackgroundColor: Colors.transparent),
      themeMode: ThemeMode.system,
      // Trik Global Background:
      builder: (context, child) {
        return Stack(
          children: [
            const PremiumBackground(),
            if (child != null) child,
          ],
        );
      },
      home: const MainNavigation(),
    );
  }
}