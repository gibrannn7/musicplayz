# MusicPlayz

A modern and feature-rich local music player built with Flutter. MusicPlayz allows you to scan, organize, and listen to your local audio files with a beautiful and intuitive user interface.

## 🌟 Features

- **Local Music Playback**: Seamlessly play your local audio files using `just_audio`.
- **Background Playback**: Continues playing music even when the app is in the background or screen is off (`audio_service`).
- **Device Storage Scanning**: Automatically fetches and queries local audio files (`on_audio_query`).
- **State Management**: Built with robust and reactive state management using `flutter_riverpod`.
- **Local Storage**: Fast and efficient offline storage using `hive`.
- **Modern UI/UX**: 
  - Beautiful navigation with `google_nav_bar`.
  - Smooth animations using `lottie`.
  - Premium typography with `google_fonts`.
  - Scrolling text for long titles (`marquee`).
  - Sleek audio progress bar (`audio_video_progress_bar`).

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.7.0)
- **Audio Core**: `just_audio`, `audio_service`, `on_audio_query`
- **State Management**: `flutter_riverpod`
- **Database**: `hive_flutter`
- **Permissions**: `permission_handler`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version ^3.7.0 or higher)
- Android Studio / VS Code
- A physical device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone <your-repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd musicplayz
   ```
3. Get the required dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📱 Permissions Required

To function properly, MusicPlayz requires:
- **Storage/Audio Permission**: To scan and read local music files.
- **Notification Permission**: To display media controls in the background.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.
