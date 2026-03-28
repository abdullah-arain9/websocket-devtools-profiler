import 'dart:convert';

enum FrameDirection { sent, received }
enum FrameType { text, binary, ping, pong, close }

class WebSocketFrameEvent {
  final int id;
  final DateTime timestamp;
  final FrameDirection direction;
  final FrameType type;
  final int sizeBytes;
  final String connectionId;
  final Duration elapsed;
  final String? payloadPreview;

  const WebSocketFrameEvent({
    required this.id,
    required this.timestamp,
    required this.direction,
    required this.type,
    required this.sizeBytes,
    required this.connectionId,
    required this.elapsed,
    this.payloadPreview,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'direction': direction.name,
    'type': type.name,
    'sizeBytes': sizeBytes,
    'connectionId': connectionId,
    'elapsedMs': elapsed.inMilliseconds,
    if (payloadPreview != null) 'payloadPreview': payloadPreview,
  };
}