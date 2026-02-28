import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Dart wrapper for AGL's pipewire-ic-ipc library (libicipc.so).
/// Uses FFI to send SUSPEND and RESUME commands to WirePlumber.
class IcipcClient {
  static const String _libName = 'libicipc.so';
  late DynamicLibrary _lib;
  Pointer<Void>? _client;

  // FFI Function signatures
  late Pointer<Void> Function(Pointer<Utf8> path, bool connect) _icipcClientNew;
  late void Function(Pointer<Void> self) _icipcClientFree;
  late bool Function(
    Pointer<Void> self,
    Pointer<Utf8> name,
    Pointer<Void> args,
    Pointer<
      NativeFunction<
        Void Function(Pointer<Void>, Pointer<Uint8>, Size, Pointer<Void>)
      >
    >
    reply,
    Pointer<Void> data,
  )
  _icipcClientSendRequest;

  // Since we just want fire-and-forget, we'll try passing nullptr for reply callbacks.
  // The C signature:
  // bool icipc_client_send_request(struct icipc_client *self, const char *name, const struct icipc_data *args, icipc_sender_reply_func_t reply, void *data);

  IcipcClient() {
    _initLib();
  }

  void _initLib() {
    try {
      _lib = DynamicLibrary.open(_libName);

      // struct icipc_client *icipc_client_new(const char *path, bool connect);
      _icipcClientNew = _lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Utf8>, Bool),
            Pointer<Void> Function(Pointer<Utf8>, bool)
          >('icipc_client_new');

      // void icipc_client_free(struct icipc_client *self);
      _icipcClientFree = _lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('icipc_client_free');

      // bool icipc_client_send_request(struct icipc_client *self, const char *name, const struct icipc_data *args, icipc_sender_reply_func_t reply, void *data);
      _icipcClientSendRequest = _lib
          .lookupFunction<
            Bool Function(
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Void>,
              Pointer<
                NativeFunction<
                  Void Function(
                    Pointer<Void>,
                    Pointer<Uint8>,
                    Size,
                    Pointer<Void>,
                  )
                >
              >,
              Pointer<Void>,
            ),
            bool Function(
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Void>,
              Pointer<
                NativeFunction<
                  Void Function(
                    Pointer<Void>,
                    Pointer<Uint8>,
                    Size,
                    Pointer<Void>,
                  )
                >
              >,
              Pointer<Void>,
            )
          >('icipc_client_send_request');

      debugPrint('IcipcClient: Successfully loaded $_libName');
    } catch (e) {
      debugPrint('IcipcClient: Failed to load $_libName: $e');
    }
  }

  /// Connects to the icipc server at the standard socket path.
  /// Usually "pipewire-ic-ipc" in $XDG_RUNTIME_DIR.
  void connect() {
    if (_client != null) return;

    try {
      // The C code says: path is "the name of the socket file... or just a filename
      // that will be looked for in standard socket directories"
      final pathPtr = 'pipewire-ic-ipc'.toNativeUtf8();
      _client = _icipcClientNew(pathPtr, true);
      calloc.free(pathPtr);

      if (_client != nullptr) {
        debugPrint('IcipcClient: Connected to pipewire-ic-ipc socket');
      } else {
        debugPrint('IcipcClient: Failed to connect (client == null)');
        _client = null;
      }
    } catch (e) {
      debugPrint('IcipcClient: Error during connect: $e');
    }
  }

  /// Sends the SUSPEND command
  void suspend() {
    _sendRequest('SUSPEND');
  }

  /// Sends the RESUME command
  void resume() {
    _sendRequest('RESUME');
  }

  void _sendRequest(String command) {
    if (_client == null || _client == nullptr) {
      debugPrint('IcipcClient: Cannot send $command (not connected)');
      return;
    }

    try {
      final namePtr = command.toNativeUtf8();
      final success = _icipcClientSendRequest(
        _client!,
        namePtr,
        nullptr, // No args
        nullptr, // No reply callback (fire and forget)
        nullptr, // No user data
      );
      calloc.free(namePtr);

      if (success) {
        debugPrint('IcipcClient: Successfully sent $command');
      } else {
        debugPrint('IcipcClient: Failed to send $command');
      }
    } catch (e) {
      debugPrint('IcipcClient: Error sending $command: $e');
    }
  }

  void dispose() {
    if (_client != null && _client != nullptr) {
      _icipcClientFree(_client!);
      _client = null;
      debugPrint('IcipcClient: Freed client connection');
    }
  }
}
