import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  String _statusMessage = '';
  bool _isError = false;
  late AudioPlayer _audioPlayer;

  // Toyota AGL backend MethodChannel — used to manually 'create' the player
  static const MethodChannel _audioChannel = MethodChannel(
    'xyz.luan/audioplayers',
  );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _readAglVersion();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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

  Future<void> _playSoundAudioPlayers() async {
    setState(() {
      _statusMessage = 'Audioplayers: Preparing audio...';
      _isError = false;
    });

    try {
      final String filePath = '/usr/share/sounds/alsa/Front_Center.wav';

      // 1. Get the actual dynamically generated ID from the audio player
      final String actualPlayerId = _audioPlayer.playerId;

      // 2. Pass THAT exact ID to the C++ backend
      // This fixes the "Player has not yet been created" error
      try {
        await _audioChannel.invokeMethod('create', {
          'playerId': actualPlayerId,
        });
        debugPrint('Diagnostic: Player created with exact ID=$actualPlayerId');
      } catch (e) {
        debugPrint('Note: Player might already exist: $e');
      }

      setState(() => _statusMessage = 'Audioplayers: Playing audio...');
      debugPrint('Diagnostic: Playing sound from: $filePath');

      await _audioPlayer
          .play(filePath, isLocal: true)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Audio playback timed out after 5 seconds');
            },
          );

      debugPrint('Diagnostic: Audio played successfully');
      setState(() {
        _statusMessage = 'Audioplayers: Audio played successfully';
        _isError = false;
      });
    } catch (e) {
      debugPrint('Diagnostic: Audio error: $e');
      setState(() {
        _statusMessage = 'Audioplayers Error: $e';
        _isError = true;
      });
    }
  }

  Future<void> _playSoundAplay() async {
    setState(() {
      _statusMessage = 'aplay: Playing audio...';
      _isError = false;
    });

    try {
      final String filePath = '/usr/share/sounds/alsa/Front_Center.wav';
      final result = await Process.run('aplay', [filePath]);

      if (result.exitCode == 0) {
        setState(() {
          _statusMessage = 'aplay: Audio played successfully';
          _isError = false;
        });
      } else {
        setState(() {
          _statusMessage = 'aplay Error: ${result.stderr}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'aplay Exception: $e';
        _isError = true;
      });
    }
  }

  Future<void> _playSoundGStreamer() async {
    setState(() {
      _statusMessage = 'GStreamer: Playing audio...';
      _isError = false;
    });

    try {
      final String filePath = '/usr/share/sounds/alsa/Front_Center.wav';
      // Include media.role=Multimedia so WirePlumber allows audio output
      final result = await Process.run('gst-launch-1.0', [
        'playbin',
        'uri=file://$filePath',
        'audio-sink=pipewiresink stream-properties="p,media.role=Multimedia"',
      ]);

      if (result.exitCode == 0) {
        setState(() {
          _statusMessage = 'GStreamer: Audio played successfully';
          _isError = false;
        });
      } else {
        setState(() {
          _statusMessage = 'GStreamer Error: ${result.stderr}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'GStreamer Exception: $e';
        _isError = true;
      });
    }
  }

  Future<void> _playSoundPaplay() async {
    setState(() {
      _statusMessage = 'paplay: Playing audio...';
      _isError = false;
    });

    try {
      final String filePath = '/usr/share/sounds/alsa/Front_Center.wav';
      final result = await Process.run('paplay', [filePath]);

      if (result.exitCode == 0) {
        setState(() {
          _statusMessage = 'paplay: Audio played successfully';
          _isError = false;
        });
      } else {
        setState(() {
          _statusMessage = 'paplay Error: ${result.stderr}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'paplay Exception: $e';
        _isError = true;
      });
    }
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
              const SizedBox(height: 20),
              const Text(
                'App Version: 1.0.1+5',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_showPicture)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/welcome.png', height: 200),
                ),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isError ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10.0,
                runSpacing: 10.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePicture,
                    icon: const Icon(Icons.image),
                    label: Text(_showPicture ? 'Hide Picture' : 'Show Picture'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playSoundAudioPlayers,
                    icon: const Icon(Icons.audiotrack),
                    label: const Text('AudioPlayers'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playSoundAplay,
                    icon: const Icon(Icons.terminal),
                    label: const Text('aplay'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playSoundGStreamer,
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('GStreamer'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playSoundPaplay,
                    icon: const Icon(Icons.speaker),
                    label: const Text('paplay'),
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
