import 'dart:convert';
import 'dart:io';
import 'package:websocket_profiler/src/websocket_profiler.dart';
import 'package:websocket_profiler/src/table_printer.dart';
import 'package:websocket_profiler/src/profileable_websocket.dart';

void main() async {
  print('\n🔌 WebSocket Profiler — GSoC Sample');
  print('Connecting...\n');

  final servers = [
    'wss://ws.postman-echo.com/raw',
    'wss://echo.websocket.org',
    'wss://socketsbay.com/wss/v2/1/demo/',
  ];

  ProfileableWebSocket? socket;

  for (final url in servers) {
    try {
      print('Trying: $url');
      socket = await WebSocketProfiler.connect(url)
          .timeout(const Duration(seconds: 5));

      // ✅ Pehle check karo connection open hai
      if (socket.readyState != WebSocket.open) {
        print('  ❌ Not open, trying next...');
        continue;
      }

      print('✅ Connected! ID: ${socket.connectionId}');
      print('Commands: /stats  /summary  /exit\n');
      break; // ✅ Connected — loop band karo

    } catch (e) {
      print('  ❌ Failed: $e');
      continue;
    }
  }

  if (socket == null || socket.readyState != WebSocket.open) {
    print('\n❌ Koi bhi server connect nahi hua!');
    exit(1);
  }

  // ✅ Pehle listener lagao
  socket.listen(
        (msg) => print('  ← Echo: $msg'),
    onDone: () => print('\n⚠️ Connection closed by server!'),
    onError: (e) => print('\n❌ Error: $e'),
  );

  // ✅ Phir input lo
  await for (final line in stdin
      .transform(SystemEncoding().decoder)
      .transform(const LineSplitter())) {
    final input = line.trim();
    if (input.isEmpty) continue;

    // ✅ Har message se pehle check karo
    if (socket.readyState != WebSocket.open) {
      print('⚠️ Connection closed! Restart karo.');
      break;
    }

    switch (input) {
      case '/stats':
        TablePrinter.printEvents(socket.lastEvents(10));
      case '/summary':
        TablePrinter.printSummary(WebSocketProfiler.summary());
      case '/exit':
        TablePrinter.printSummary(WebSocketProfiler.summary());
        TablePrinter.printEvents(socket.events);
        await socket.close(1000, 'bye');
        exit(0);
      default:
        print('  → Sending: "$input"');
        socket.add(input);
    }
  }
}