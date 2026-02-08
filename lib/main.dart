import 'dart:io';
import 'package:flutter/material.dart';
import 'agl_audio_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGL Hello World',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AGL Custom App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _aglVersion = 'Unknown';
  bool _showPicture = false;
  final AglAudioClient _aglClient = AglAudioClient();

  @override
  void initState() {
    super.initState();
    _readAglVersion();
    _aglClient.init();
  }

  @override
  void dispose() {
    _aglClient.dispose();
    super.dispose();
  }

  Future<void> _readAglVersion() async {
    try {
      final file = File('/etc/os-release');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          if (line.startsWith('PRETTY_NAME=') ||
              line.startsWith('VERSION_ID=')) {
            setState(() {
              _aglVersion = line.split('=')[1].replaceAll('"', '');
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading /etc/os-release: $e');
    }
  }

  void _togglePicture() {
    setState(() {
      _showPicture = !_showPicture;
    });
  }

  Future<void> _playSound() async {
    // In a real AGL scenario, we'd pass the absolute path to the binding
    // However, AGL bindings often need the file to be accessible by the binder user.
    // For this demo, we assume the asset is accessible or we pass a known test path.
    String assetPath =
        '${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/assets/sounds/notification.wav';

    // Fallback if not found (e.g. dev mode)
    if (!await File(assetPath).exists()) {
      assetPath = '/usr/share/sounds/alsa/Front_Center.wav';
    }

    debugPrint('Requesting AGL to play: $assetPath');
    _aglClient.play(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'AGL Version:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _aglVersion,
                style: const TextStyle(fontSize: 24, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Developed by:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Antigravity',
                style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),
              if (_showPicture)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/welcome.png', height: 200),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePicture,
                    icon: const Icon(Icons.image),
                    label: Text(_showPicture ? 'Hide Picture' : 'Show Picture'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playSound,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Play Sound (AGL Service)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
