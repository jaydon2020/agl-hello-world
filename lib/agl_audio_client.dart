import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AglAudioClient {
  WebSocketChannel? _channel;
  final String _host = 'localhost';
  final int _port = 1700; // Default AGL binder port, may vary
  final String _api = 'mediaplayer'; // Using mediaplayer service
  String? _token;

  // Stream controller for handling responses if needed
  final _responseController =
      StreamController<Map<String, dynamic>>.broadcast();

  Future<void> init() async {
    // In a real AGL app, the port and secret token are usually passed via
    // command line arguments or environment variables by the app launcher (afm-user-daemon).
    // For this demo, we'll try to read them from environment or use defaults.

    // Example env vars: AGL_PORT, AGL_TOKEN
    String portStr = Platform.environment['AGL_PORT'] ?? _port.toString();
    _token = Platform.environment['AGL_TOKEN'] ?? 'HELLO';

    final uri = Uri.parse('ws://$_host:$portStr/api?token=$_token');

    try {
      _channel = WebSocketChannel.connect(uri);
      debugPrint('Connecting to AGL Binder: $uri');

      _channel!.stream.listen(
        (message) {
          debugPrint('AGL Binder Message: $message');
          if (message is String) {
            List<dynamic> response = jsonDecode(message);
            // Simple JSON-RPC response handling
            // [2, "msgid", "response_data"]
            if (response.isNotEmpty && response[0] == 3) {
              // 3 is CALL_RESULT
              // Handle result
            }
          }
        },
        onError: (error) {
          debugPrint('AGL Binder Error: $error');
        },
        onDone: () {
          debugPrint('AGL Binder Connection Closed');
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to AGL Binder: $e');
    }
  }

  void play(String uri) {
    if (_channel == null) {
      debugPrint('AGL Client not connected');
      return;
    }

    // AGL JSON-RPC format: [2, "msgid", "api/verb", {args}]
    // 2 = CALL
    // We are constructing requests below using _sendRequest

    // Alternatively, just 'loop', 'controls' etc might differ by binding implementation.
    // 'mediaplayer' binding often has 'loop', 'open', 'play'.
    // Let's try to just 'open' and then 'play'.

    _sendRequest('$_api/loop', {'state': 'off'});
    _sendRequest('$_api/playlist_add', {'uri': uri});
    _sendRequest('$_api/play', {});
  }

  void _sendRequest(String apiVerb, Map<String, dynamic> args) {
    if (_channel == null) return;

    final request = [
      2,
      DateTime.now().millisecondsSinceEpoch.toString(),
      apiVerb,
      args,
    ];

    debugPrint('Sending to AGL: $request');
    _channel!.sink.add(jsonEncode(request));
  }

  void dispose() {
    _channel?.sink.close();
    _responseController.close();
  }
}
