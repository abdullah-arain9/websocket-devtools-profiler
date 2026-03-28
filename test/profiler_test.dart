import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:websocket_profiler/src/profileable_websocket.dart';
import 'package:websocket_profiler/src/websocket_frame_event.dart';
import 'package:websocket_profiler/src/websocket_profiler.dart';

class MockWebSocket implements WebSocket {
  final _controller = StreamController<dynamic>();
  final List<dynamic> sent = [];
  bool closed = false;

  @override
  void add(dynamic data) => sent.add(data);

  @override
  StreamSubscription listen(
      void Function(dynamic)? onData, {
        Function? onError,
        void Function()? onDone,
        bool? cancelOnError,
      }) =>
      _controller.stream.listen(onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError);

  void simulateReceive(dynamic data) => _controller.add(data);

  @override
  Future close([int? code, String? reason]) async {
    closed = true;
    await _controller.close();
  }

  // ── Missing methods ────────────────────────────
  @override
  Duration? get pingInterval => null;

  @override
  set pingInterval(Duration? value) {}

  @override
  void addUtf8Text(List<int> bytes) {}

  @override
  Future<E> drain<E>([E? futureValue]) =>
      _controller.stream.drain(futureValue);

  @override
  Future<dynamic> elementAt(int index) =>
      _controller.stream.elementAt(index);

  @override
  Future<bool> every(bool Function(dynamic) test) =>
      _controller.stream.every(test);

  @override
  Stream<dynamic> distinct([bool Function(dynamic, dynamic)? equals]) =>
      _controller.stream.distinct(equals);

  // ── Stubs ──────────────────────────────────────
  @override int get closeCode => 1000;
  @override String? get closeReason => null;
  @override String get extensions => '';
  @override String get protocol => '';
  @override int get readyState => WebSocket.open;
  @override void addError(Object e, [StackTrace? st]) {}
  @override Future addStream(Stream s) async {}
  @override Future get done async {}
  @override Future<bool> any(bool Function(dynamic) t) => _controller.stream.any(t);
  @override Stream asBroadcastStream({void Function(StreamSubscription)? onListen, void Function(StreamSubscription)? onCancel}) => _controller.stream.asBroadcastStream();
  @override Stream<E> asyncExpand<E>(Stream<E>? Function(dynamic) c) => _controller.stream.asyncExpand(c);
  @override Stream<E> asyncMap<E>(FutureOr<E> Function(dynamic) c) => _controller.stream.asyncMap(c);
  @override Stream<R> cast<R>() => _controller.stream.cast<R>();
  @override Future<bool> contains(Object? n) => _controller.stream.contains(n);
  @override Stream<E> expand<E>(Iterable<E> Function(dynamic) c) => _controller.stream.expand(c);
  @override Future get first => _controller.stream.first;
  @override Future firstWhere(bool Function(dynamic) t, {dynamic Function()? orElse}) => _controller.stream.firstWhere(t, orElse: orElse);
  @override Future<S> fold<S>(S i, S Function(S, dynamic) c) => _controller.stream.fold(i, c);
  @override Future forEach(void Function(dynamic) a) => _controller.stream.forEach(a);
  @override Stream handleError(Function h, {bool Function(dynamic)? test}) => _controller.stream.handleError(h, test: test);
  @override bool get isBroadcast => false;
  @override Future<bool> get isEmpty => _controller.stream.isEmpty;
  @override Future<String> join([String s = '']) => _controller.stream.join(s);
  @override Future get last => _controller.stream.last;
  @override Future lastWhere(bool Function(dynamic) t, {dynamic Function()? orElse}) => _controller.stream.lastWhere(t, orElse: orElse);
  @override Future<int> get length => _controller.stream.length;
  @override Stream<S> map<S>(S Function(dynamic) c) => _controller.stream.map(c);
  @override Future pipe(StreamConsumer c) => _controller.stream.pipe(c);
  @override Future reduce(dynamic Function(dynamic, dynamic) c) => _controller.stream.reduce(c);
  @override Future get single => _controller.stream.single;
  @override Future singleWhere(bool Function(dynamic) t, {dynamic Function()? orElse}) => _controller.stream.singleWhere(t, orElse: orElse);
  @override Stream skip(int c) => _controller.stream.skip(c);
  @override Stream skipWhile(bool Function(dynamic) t) => _controller.stream.skipWhile(t);
  @override Stream take(int c) => _controller.stream.take(c);
  @override Stream takeWhile(bool Function(dynamic) t) => _controller.stream.takeWhile(t);
  @override Stream timeout(Duration d, {void Function(EventSink)? onTimeout}) => _controller.stream.timeout(d, onTimeout: onTimeout);
  @override Future<List> toList() => _controller.stream.toList();
  @override Future<Set> toSet() => _controller.stream.toSet();
  @override Stream<S> transform<S>(StreamTransformer<dynamic, S> t) => _controller.stream.transform(t);
  @override Stream where(bool Function(dynamic) t) => _controller.stream.where(t);
}

void main() {

  group('WebSocketFrameEvent', () {
    test('toJson sahi kaam karta hai', () {
      final event = WebSocketFrameEvent(
        id: 1,
        timestamp: DateTime(2026, 3, 28),
        direction: FrameDirection.sent,
        type: FrameType.text,
        sizeBytes: 42,
        connectionId: 'ws_1',
        elapsed: const Duration(milliseconds: 100),
        payloadPreview: 'hello',
      );

      final json = event.toJson();
      expect(json['id'], equals(1));
      expect(json['direction'], equals('sent'));
      expect(json['type'], equals('text'));
      expect(json['sizeBytes'], equals(42));
      expect(json['elapsedMs'], equals(100));
      expect(json['payloadPreview'], equals('hello'));
    });
  });

  group('ProfileableWebSocket', () {
    late MockWebSocket mock;
    late ProfileableWebSocket profiled;

    setUp(() {
      mock = MockWebSocket();
      profiled = ProfileableWebSocket.wrap(mock, id: 'ws_test');
    });

    test('add() ke baad sent event record hota hai', () {
      profiled.add('hello');
      expect(profiled.events.length, equals(1));
      expect(profiled.events.first.direction, equals(FrameDirection.sent));
      expect(profiled.events.first.type, equals(FrameType.text));
    });

    test('receive hone pe received event record hota hai', () async {
      profiled.listen((_) {});
      mock.simulateReceive('server reply');
      await Future.delayed(Duration.zero);
      expect(profiled.events.length, equals(1));
      expect(profiled.events.first.direction, equals(FrameDirection.received));
    });

    test('sent aur received dono sahi order mein hain', () async {
      profiled.listen((_) {});

      profiled.add('msg1');
      await Future.delayed(Duration.zero);
      mock.simulateReceive('echo1');
      await Future.delayed(Duration.zero);
      profiled.add('msg2');
      await Future.delayed(Duration.zero);
      mock.simulateReceive('echo2');
      await Future.delayed(Duration.zero);

      expect(profiled.events.length, equals(4));
      expect(profiled.events[0].direction, equals(FrameDirection.sent));
      expect(profiled.events[1].direction, equals(FrameDirection.received));
      expect(profiled.events[2].direction, equals(FrameDirection.sent));
      expect(profiled.events[3].direction, equals(FrameDirection.received));
    });

    test('lastEvents(3) sirf last 3 return karta hai', () {
      profiled.add('a');
      profiled.add('b');
      profiled.add('c');
      profiled.add('d');
      profiled.add('e');
      final last = profiled.lastEvents(3);
      expect(last.length, equals(3));
      expect(last.last.payloadPreview, equals('e'));
    });

    test('frameEvents stream pe event aata hai', () async {
      final streamEvents = <WebSocketFrameEvent>[];
      profiled.frameEvents.listen(streamEvents.add);
      profiled.add('test message');
      await Future.delayed(Duration.zero);
      expect(streamEvents.length, equals(1));
      expect(streamEvents.first.direction, equals(FrameDirection.sent));
    });

    test('connectionId sahi set hoti hai', () {
      expect(profiled.connectionId, equals('ws_test'));
    });

    test('sizeBytes UTF-8 bytes mein hoti hai', () {
      profiled.add('hello');
      expect(profiled.events.first.sizeBytes, equals(5));
    });
  });

  group('WebSocketProfiler registry', () {
    setUp(() => WebSocketProfiler.reset());

    test('reset ke baad summary zero hoti hai', () {
      final s = WebSocketProfiler.summary();
      expect(s['totalConnections'], equals(0));
      expect(s['totalEvents'], equals(0));
    });
  });
}