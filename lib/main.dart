import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _readAglVersion();
  }

  @override
  void dispose() {
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
    setState(() {
      _errorMessage = '';
    });

    try {
      // 1. Get the temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/notification.wav');

      // 2. Extract asset if it doesn't exist in temp
      if (!await tempFile.exists()) {
        debugPrint('Extracting asset to ${tempFile.path}');
        try {
          final ByteData data = await rootBundle.load(
            'assets/sounds/notification.wav',
          );
          final List<int> bytes = data.buffer.asUint8List();
          await tempFile.writeAsBytes(bytes);
        } catch (e) {
          debugPrint('Asset extraction failed: $e');
          setState(() {
            _errorMessage = 'Asset Error: $e';
          });
          return;
        }
      }

      debugPrint('Playing sound from: ${tempFile.path}');

      // 3. Play using gst-launch-1.0 (native command)
      // We use playbin for easy playback of files
      final ProcessResult result = await Process.run('gst-launch-1.0', [
        'playbin',
        'uri=file://${tempFile.path}',
      ]);

      if (result.exitCode != 0) {
        debugPrint('gst-launch-1.0 failed: ${result.stderr}');
        setState(() {
          _errorMessage = 'GStreamer Error: ${result.stderr}';
        });
      } else {
        debugPrint('Audio played successfully');
      }
    } catch (e) {
      debugPrint('Native audio error: $e');
      setState(() {
        _errorMessage = 'Native Error: $e';
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
                'App Version: 1.0.0+2',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_showPicture)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset('assets/images/welcome.png', height: 200),
                ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                    label: const Text('Play Sound'),
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
