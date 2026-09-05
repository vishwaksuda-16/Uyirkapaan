import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/constants/api_constants.dart';

/// Representation of a real-time event received from the backend Socket.IO or simulation.
class SocketEvent {
  final String event;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SocketEvent({
    required this.event,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'SocketEvent(event: $event, data: $data)';
}

/// Service managing Socket.IO connection to http://localhost:4000
/// and listening for real-time dispatch and tracking events.
class SocketService {
  io.Socket? _socket;
  final _eventController = StreamController<SocketEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;
  String? _activeRoom;

  Stream<SocketEvent> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  String? get activeRoom => _activeRoom;

  bool _loggedConnectError = false;

  /// Connect to Socket.IO backend at http://localhost:4000 with JWT authentication
  void connect({String? token, String? url}) {
    disconnect();
    final socketUrl = url ?? ApiConstants.socketUrl;

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .disableReconnection()
            .setAuth({'token': token ?? ''})
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('[Socket.IO] Connected to $socketUrl');
        _loggedConnectError = false;
        _isConnected = true;
        _connectionController.add(true);
        if (_activeRoom != null) {
          _joinRoom(_activeRoom!);
        }
      });

      _socket?.onDisconnect((reason) {
        debugPrint('[Socket.IO] Disconnected: $reason');
        _isConnected = false;
        _connectionController.add(false);
      });

      _socket?.onConnectError((err) {
        if (!_loggedConnectError) {
          debugPrint('[Socket.IO] Notice: Backend on $socketUrl is not reachable. Operating in offline/simulation mode.');
          _loggedConnectError = true;
        }
        _isConnected = false;
        _connectionController.add(false);
      });

      _socket?.onError((err) {
        if (!_loggedConnectError) {
          debugPrint('[Socket.IO] Notice: Backend on $socketUrl is not reachable. Operating in offline/simulation mode.');
          _loggedConnectError = true;
        }
      });

      // Register the 10 mandated backend Socket.IO events
      const eventNames = [
        'EMERGENCY_CREATED',
        'AMBULANCE_ASSIGNED',
        'ASSIGNMENT_ACCEPTED',
        'AMBULANCE_LOCATION_UPDATED',
        'ETA_UPDATED',
        'STATUS_UPDATED',
        'FALLBACK_STARTED',
        'AMBULANCE_REASSIGNED',
        'AMBULANCE_ARRIVED',
        'EMERGENCY_COMPLETED',
      ];

      for (final eventName in eventNames) {
        _socket?.on(eventName, (payload) {
          debugPrint('[Socket.IO] Received $eventName: $payload');
          final Map<String, dynamic> data = payload is Map<String, dynamic>
              ? payload
              : (payload is Map ? Map<String, dynamic>.from(payload) : {'payload': payload});

          _eventController.add(SocketEvent(event: eventName, data: data));
        });
      }

      _socket?.connect();
    } catch (e) {
      debugPrint('[Socket.IO] Initialization failed: $e');
    }
  }

  /// Joins room `emergency:{requestId}`
  void joinEmergencyRoom(String requestId) {
    _activeRoom = 'emergency:$requestId';
    _joinRoom(_activeRoom!);
  }

  void _joinRoom(String room) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join', room);
      _socket!.emit('joinRoom', room);
      debugPrint('[Socket.IO] Joined room $room');
    }
  }

  /// Leaves room `emergency:{requestId}`
  void leaveEmergencyRoom() {
    if (_socket != null && _isConnected && _activeRoom != null) {
      _socket!.emit('leave', _activeRoom);
      _socket!.emit('leaveRoom', _activeRoom);
      debugPrint('[Socket.IO] Left room $_activeRoom');
    }
    _activeRoom = null;
  }

  /// Allows simulated dispatch engine to inject events into the same broadcast stream
  void emitSimulatedEvent(String eventName, Map<String, dynamic> data) {
    _eventController.add(SocketEvent(event: eventName, data: data));
  }

  void disconnect() {
    if (_socket != null) {
      try {
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
