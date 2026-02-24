import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// --- Platform Channel Wrapper ---
class AglNativeAudioPlayer {
  static const MethodChannel _channel = MethodChannel('agl_audio_player');

  Future<String?> playLocalFile(String path) async {
    try {
      await _channel.invokeMethod('play', path);
      return null;
    } on PlatformException catch (e) {
      debugPrint('Failed to play: ${e.message}');
      return e.message ?? 'Unknown platform error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> pause() async {
    try {
      await _channel.invokeMethod('pause');
      return null;
    } on PlatformException catch (e) {
      debugPrint('Failed to pause: ${e.message}');
      return e.message ?? 'Unknown platform error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> stop() async {
    try {
      await _channel.invokeMethod('stop');
      return null;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop: ${e.message}');
      return e.message ?? 'Unknown platform error';
    } catch (e) {
      return e.toString();
    }
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _handleAction(() => _player.playLocalFile(_testFilePath));
    });
  }

  void _handleAction(Future<String?> Function() action) async {
    setState(() {
      _errorMessage = null;
    });
    final error = await action();
    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

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
                  onPressed: () =>
                      _handleAction(() => _player.playLocalFile(_testFilePath)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  onPressed: () => _handleAction(() => _player.pause()),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  onPressed: () => _handleAction(() => _player.stop()),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
