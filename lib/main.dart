import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// --- Platform Channel Wrapper ---
class AglNativeAudioPlayer {
  static const MethodChannel _channel = MethodChannel('agl_audio_player');

  Future<void> playLocalFile(String path) async {
    try {
      await _channel.invokeMethod('play', path);
    } on PlatformException catch (_) {
      debugPrint("Failed to play: '\${_.message}'.");
    }
  }

  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }
}

// --- Basic UI ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGL Custom Audio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AudioTestScreen(),
    );
  }
}

class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final AglNativeAudioPlayer _player = AglNativeAudioPlayer();
  // Using a standard ALSA test sound available on most AGL builds
  final String _testFilePath = '/usr/share/sounds/alsa/Front_Center.wav';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGL Pipewire Native Bridge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GStreamer -> PipeWire (media.role=Multimedia)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  onPressed: () => _player.playLocalFile(_testFilePath),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  onPressed: () => _player.pause(),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  onPressed: () => _player.stop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
