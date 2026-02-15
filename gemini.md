# SYSTEM ROLE

Anda adalah Senior Flutter Developer expert. Tugas Anda adalah membangun aplikasi pemutar musik offline 100% lokal bernama "musicplayz". Aplikasi ini TIDAK memiliki backend, TIDAK ada fitur login, dan mengandalkan file MP3 lokal dari device.

# CORE RULES & CONSTRAINTS

1. Target SDK: `sdk: ^3.7.0`.
2. Target Device: Android dan iOS.
3. DILARANG KERAS menggunakan emoji di dalam komentar kode, string, atau UI (Gunakan `Icons` bawaan Material/Cupertino).
4. Kode harus FULL, siap jalan (ready-to-run), clean, minimalis, dan tidak ada memory leak.
5. Gunakan `flutter_riverpod` untuk State Management.
6. Gunakan `hive_flutter` untuk local storage (Liked Songs & Playlists).
7. Arsitektur harus modular sesuai struktur yang diberikan.

# TECH STACK & DEPENDENCIES

Tambahkan ini ke `pubspec.yaml`:

- just_audio: ^0.9.36
- audio_service: ^0.18.12
- on_audio_query: ^3.1.12
- hive_flutter: ^1.1.0
- flutter_riverpod: ^2.5.1
- permission_handler: ^11.3.0
- marquee: ^2.2.3
- audio_video_progress_bar: ^2.0.3
- path_provider: ^2.1.2
- uuid: ^4.3.3

# ARCHITECTURE & FOLDER STRUCTURE

lib/
├── main.dart
├── core/
│ ├── audio_handler.dart (Extends BaseAudioHandler)
│ ├── permission_handler.dart
│ └── theme.dart (Clean minimalis, dark/light mode)
├── models/
│ ├── song_model.dart (Hive type)
│ └── playlist_model.dart (Hive type)
├── services/
│ ├── audio_manager.dart (Wrapper untuk setup audio_service)
│ ├── storage_service.dart (Hive setup & operations)
├── providers/
│ ├── audio_state_provider.dart
│ ├── library_provider.dart
│ └── playlist_provider.dart
├── screens/
│ ├── main_navigation.dart (BottomNavigationBar)
│ ├── home_screen.dart
│ ├── now_playing_screen.dart
│ ├── playlist_screen.dart
│ ├── liked_screen.dart
│ └── queue_screen.dart
└── widgets/
├── mini_player.dart
├── song_tile.dart
└── custom_icon_button.dart

# NATIVE CONFIGURATION REQUIREMENTS (WAJIB DIIKUTI)

## Android (`android/app/src/main/AndroidManifest.xml`)

Tambahkan permission:
`<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>`
`<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>` (Untuk Android 13+)
`<uses-permission android:name="android.permission.WAKE_LOCK"/>`
`<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>`
`<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>`
Deklarasikan service `com.ryanheise.audioservice.AudioServicePlugin` di dalam tag `<application>`.

## iOS (`ios/Runner/Info.plist`)

Tambahkan:
`<key>NSAppleMusicUsageDescription</key>`
`<string>App requires access to media library to play local music.</string>`
`<key>UIBackgroundModes</key>`
`<array><string>audio</string></array>`

# FEATURE IMPLEMENTATION DETAILS

## 1. Core Audio & Background Service (`core/audio_handler.dart`)

- Buat class `MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler`.
- Gunakan `ConcatenatingAudioSource` dari `just_audio` untuk sistem antrian (Queue).
- Implementasi metode wajib: `play()`, `pause()`, `stop()`, `skipToNext()`, `skipToPrevious()`, `seek()`.
- Listen ke playback event dari `just_audio` dan broadcast state ke `audio_service` agar Notification dan Lockscreen update secara realtime.
- Implementasi Sleep Timer: Buat fungsi `setSleepTimer(Duration duration)` menggunakan `Timer` dari Dart. Saat timer _complete_, panggil `pause()`.

## 2. Local Storage (`models/` & `services/storage_service.dart`)

- Buat `LocalSongModel` dengan anotasi Hive (id, title, artist, uri, duration, isLiked).
- Buat `PlaylistModel` dengan anotasi Hive (id, name, List<LocalSongModel> songs).
- Jalankan `build_runner` untuk men-generate adapter Hive.

## 3. Provider State Management (`providers/`)

- `libraryProvider`: FutureProvider yang memanggil `on_audio_query` untuk mendapatkan semua lagu MP3 di device. Handle request permission di sini.
- `audioStateProvider`: StreamProvider yang listen ke `AudioService.position` dan `AudioService.playbackState` untuk merender UI tanpa memory leak.
- `queueProvider`: StateNotifierProvider untuk mengelola daftar antrian saat ini, mendukung _reorder_ (drag & drop) dan paginasi lokal (load 20 lagu pertama, sisanya diload saat discroll).

## 4. UI/UX Guidelines (Tampilan Minimalis & Clean)

- Warna: Dominan hitam/putih (monochrome) dengan aksen warna primer yang soft.
- Font: Gunakan typography bawaan Material 3 yang rapi.
- `MainNavigation`: Memiliki `BottomNavigationBar` (Home, Playlist, Liked, Queue) dan sebuah `MiniPlayer` yang ditempatkan di atas BottomNavBar menggunakan `Stack` atau `Column`. `MiniPlayer` HANYA muncul jika `playbackState` tidak null/berjalan.

## 5. Specific Screens Instructions

- **Home Screen**: Menampilkan list lagu. Gunakan `ListView.builder`.
- **Mini Player**: Tinggi sekitar 65px. Gunakan widget `Marquee` untuk judul lagu. Tombol play/pause di kanan. Tap area untuk push ke `NowPlayingScreen`.
- **Now Playing Screen**: Cover album besar di tengah (gunakan `QueryArtworkWidget` dari `on_audio_query`). Progress bar menggunakan `audio_video_progress_bar`. Deretan icon button di bawah: Shuffle, Prev, Play/Pause (ukuran lebih besar), Next, Repeat. Deretan tombol tambahan: Add to Playlist, Sleep Timer (buka bottom sheet berisi opsi 15m, 30m, 45m, 1h, 2h), Heart (Like/Unlike).
- **Queue Screen**: Gunakan `ReorderableListView.builder` agar user bisa _drag and drop_ lagu. Hapus lagu dari antrian dengan _swipe to dismiss_.

Mulai eksekusi sekarang. Ingat: NO EMOJI. FULL CODE untuk setiap file yang diminta pada tahap tersebut.
