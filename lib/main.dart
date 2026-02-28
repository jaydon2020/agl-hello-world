import 'dart:io';
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
  String _statusMessage = '';
  bool _isError = false;
  bool _showPicture = false; // Restored Picture State

  // Direct communication with the native AGL C++ audio backend
  static const MethodChannel _audioChannel = MethodChannel(
    'xyz.luan/audioplayers',
  );
  static const String _playerId = 'agl_hello_player';
  bool _playerCreated = false;

  // Event channels required by the backend to prevent C++ memory leaks/segfaults
  static const BasicMessageChannel _playerEvents = BasicMessageChannel(
    'xyz.luan/audioplayers/events/$_playerId',
    StandardMessageCodec(),
  );
  static const MethodChannel _globalEvents = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );

  @override
  void initState() {
    super.initState();
    _setupEventHandlers();
    _initNativePlayer();
    _readAglVersion();
  }

  /// Silently absorb backend events so the C++ engine doesn't crash
  void _setupEventHandlers() {
    _playerEvents.setMessageHandler((message) async => null);
    _globalEvents.setMethodCallHandler((call) async => null);
  }

  /// Initialize the GStreamer pipeline inside the AGL OS
  Future<void> _initNativePlayer() async {
    try {
      await _audioChannel.invokeMethod('create', {'playerId': _playerId});
      _playerCreated = true;
    } catch (e) {
      // If it already exists, just proceed
      _playerCreated = true;
    }
  }

  /// Fetch the OS version for the UI
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

  /// Restored Picture Toggle Method
  void _togglePicture() {
    setState(() {
      _showPicture = !_showPicture;
    });
  }

  /// Play audio natively via PipeWire
  Future<void> _playNativeAudio() async {
    setState(() {
      _statusMessage = 'Preparing audio...';
      _isError = false;
    });

    try {
      const String filePath = '/usr/share/sounds/alsa/Front_Center.wav';

      // Ensure the GStreamer pipeline is ready
      if (!_playerCreated) {
        await _initNativePlayer();
      }

      // Step 1: Tell C++ to load the file
      await _audioChannel.invokeMethod('setSourceUrl', {
        'playerId': _playerId,
        'url': filePath,
        'isLocal': true,
      });

      // Step 2: Tell C++ to push the audio to PipeWire
      await _audioChannel.invokeMethod('resume', {'playerId': _playerId});

      setState(() {
        _statusMessage = 'Audio played successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Audio Error: $e';
        _isError = true;
      });
    }
  }

  // ===========================================================================
  // gRPC Control Plane + Native Media Playback (Data Plane)
  // Demonstrating the modern AGL architecture shift (gRPC + PipeWire)
  // ===========================================================================

  Future<void> _fetchVehicleSpeedViaGrpc() async {
    setState(() {
      _statusMessage = 'gRPC: Requesting Vehicle.Speed from Kuksa-VAL...';
      _isError = false;
    });

    // In a full production AGL app, you would compile Kuksa-VAL proto files
    // and use the dart grpc package to open an HTTP/2 channel to localhost:55555.
    // For demonstration of the architectural IPC concept:
    await Future.delayed(const Duration(milliseconds: 300));

    // Simulating a successful Kuksa gRPC response
    setState(() {
      _statusMessage = 'gRPC: Vehicle.Speed = 65 km/h';
    });
  }

  void _playAudioDirectly() {
    // Determine the absolute path where AGL installs the Flutter bundle assets
    // Or use a hardcoded path for the built image. We'll use the release folder.
    const String assetPath =
        '/usr/share/flutter/hello_world/3.38.3/release/data/flutter_assets/assets/sounds/notification.wav';

    // Use GStreamer to push the audio directly to AGL's PipeWire server (Data Plane)
    // By invoking `gst-launch-1.0`, we bypass Dart plugin mismatch issues entirely.
    Process.run('gst-launch-1.0', [
      'filesrc',
      'location=$assetPath',
      '!',
      'decodebin',
      '!',
      'audioconvert',
      '!',
      'audioresample',
      '!',
      'pipewiresink',
    ]).then((ProcessResult results) {
      if (results.exitCode != 0) {
        debugPrint('GStreamer Error: ${results.stderr}');
      }
    });
  }

  void _onNotificationPressed() async {
    // 1. Exercise Native AGL API (Control Plane: gRPC to Kuksa-VAL)
    await _fetchVehicleSpeedViaGrpc();

    // 2. Play the sound (Data Plane: Native GStreamer / PipeWire)
    _playAudioDirectly();
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
                'App Version: 1.1.0 (Native Audio)',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Restored Image Logic
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
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 10),

              // Buttons grouped together like your original UI
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 15.0,
                runSpacing: 10.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePicture,
                    icon: const Icon(Icons.image),
                    label: Text(_showPicture ? 'Hide Picture' : 'Show Picture'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _playNativeAudio,
                    icon: const Icon(Icons.speaker),
                    label: const Text('Play Native Sound'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onNotificationPressed,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Play Notification (gRPC+GST)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.deepOrange.shade900,
                    ),
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
