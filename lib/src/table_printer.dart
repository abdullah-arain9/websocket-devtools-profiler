import 'websocket_frame_event.dart';

class TablePrinter {
  static final _line = '─' * 78;

  static void printEvents(List<WebSocketFrameEvent> events, {int? last}) {
    final toShow = last != null && events.length > last
        ? events.sublist(events.length - last)
        : events;

    if (toShow.isEmpty) {
      print('[No events recorded yet]');
      return;
    }

    print('\n$_line');
    print(
      _col('ID', 5) +
          _col('TIME', 15) +
          _col('DIR', 10) +
          _col('TYPE', 9) +
          _col('BYTES', 9) +
          _col('ELAPSED', 12) +
          'PREVIEW',
    );
    print(_line);

    for (final e in toShow) {
      final timeStr =
          '${e.timestamp.hour.toString().padLeft(2, '0')}:'
          '${e.timestamp.minute.toString().padLeft(2, '0')}:'
          '${e.timestamp.second.toString().padLeft(2, '0')}.'
          '${e.timestamp.millisecond.toString().padLeft(3, '0')}';

      final dirSymbol =
      e.direction == FrameDirection.sent ? '↑ sent' : '↓ recv';

      final preview = e.payloadPreview ?? '';
      final previewShort =
      preview.length > 20 ? '${preview.substring(0, 20)}...' : preview;

      // ✅ BYTES mein B add, ELAPSED ke baad space
      print(
        _col(e.id.toString(), 5) +
            _col(timeStr, 15) +
            _col(dirSymbol, 10) +
            _col(e.type.name, 9) +
            _col('${e.sizeBytes}B', 9) +        // ✅ B add kiya
            _col('+${e.elapsed.inMilliseconds}ms', 12) + // ✅ space fix
            previewShort,
      );
    }

    print('$_line\n');
  }

  static void printSummary(Map<String, dynamic> s) {
    print('\n📊 Summary:');
    print('   Connections : ${s['totalConnections']}');
    print('   Events      : ${s['totalEvents']}');
    print('   Sent        : ${_formatBytes(s['bytesSent'])}');
    print('   Received    : ${_formatBytes(s['bytesReceived'])}');
    print('');
  }

  static String _col(String text, int width) => text.padRight(width);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}