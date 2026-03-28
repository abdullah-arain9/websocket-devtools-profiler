import 'dart:io';
import 'profileable_websocket.dart';
import 'websocket_frame_event.dart';




class WebSocketProfiler {
  WebSocketProfiler._();

  static final Map<String, ProfileableWebSocket> _connections = {};
  static int _counter = 0;

  // ✅ YEH USE KARO normal WebSocket.connect() ki jagah
  static Future<ProfileableWebSocket> connect(String url) async {
    final raw = await WebSocket.connect(url);
    final id = 'ws_${++_counter}';
    final profiled = ProfileableWebSocket.wrap(raw, id: id);
    _connections[id] = profiled;
    return profiled;
  }

  static List<WebSocketFrameEvent> allEvents() {
    return _connections.values
        .expand((ws) => ws.events)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Map<String, dynamic> summary() => {
    'totalConnections': _connections.length,
    'totalEvents': allEvents().length,
    'bytesSent': _connections.values
        .expand((ws) => ws.events)
        .where((e) => e.direction == FrameDirection.sent)
        .fold(0, (s, e) => s + e.sizeBytes),
    'bytesReceived': _connections.values
        .expand((ws) => ws.events)
        .where((e) => e.direction == FrameDirection.received)
        .fold(0, (s, e) => s + e.sizeBytes),
  };

  static void reset() {
    _connections.clear();
    _counter = 0;
  }
}