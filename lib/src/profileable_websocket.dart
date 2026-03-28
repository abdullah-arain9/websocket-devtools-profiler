import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'websocket_frame_event.dart';

class ProfileableWebSocket implements WebSocket {
  final WebSocket _inner;
  final String connectionId;
  final DateTime _connectedAt;
  final List<WebSocketFrameEvent> _events = [];
  final _streamCtrl = StreamController<WebSocketFrameEvent>.broadcast();
  int _counter = 0;

  ProfileableWebSocket._(this._inner, this.connectionId)
      : _connectedAt = DateTime.now();

  factory ProfileableWebSocket.wrap(WebSocket socket, {required String id}) {
    return ProfileableWebSocket._(socket, id);
  }

  List<WebSocketFrameEvent> get events => List.unmodifiable(_events);
  Stream<WebSocketFrameEvent> get frameEvents => _streamCtrl.stream;

  List<WebSocketFrameEvent> lastEvents(int n) {
    if (_events.length <= n) return List.unmodifiable(_events);
    return List.unmodifiable(_events.sublist(_events.length - n));
  }

  void _record({
    required FrameDirection direction,
    required FrameType type,
    required int sizeBytes,
    String? payloadPreview,
  }) {
    final now = DateTime.now();
    final event = WebSocketFrameEvent(
      id: ++_counter,
      timestamp: now,
      direction: direction,
      type: type,
      sizeBytes: sizeBytes,
      connectionId: connectionId,
      elapsed: now.difference(_connectedAt),
      payloadPreview: payloadPreview,
    );
    _events.add(event);
    _streamCtrl.add(event);
    dev.Timeline.instantSync(
      'WebSocket.${direction.name}',
      arguments: event.toJson(),
    );
  }

  @override
  void add(dynamic data) {
    final bytes = data is String
        ? utf8.encode(data).length
        : (data as List<int>).length;
    _record(
      direction: FrameDirection.sent,
      type: data is String ? FrameType.text : FrameType.binary,
      sizeBytes: bytes,
      payloadPreview: data is String
          ? data.substring(0, data.length.clamp(0, 100))
          : '[binary]',
    );
    _inner.add(data);
  }

  @override
  StreamSubscription listen(
      void Function(dynamic)? onData, {
        Function? onError,
        void Function()? onDone,
        bool? cancelOnError,
      }) {
    return _inner.listen(
          (msg) {
        final bytes = msg is String
            ? utf8.encode(msg).length
            : (msg as List<int>).length;
        _record(
          direction: FrameDirection.received,
          type: msg is String ? FrameType.text : FrameType.binary,
          sizeBytes: bytes,
          payloadPreview: msg is String
              ? msg.substring(0, msg.length.clamp(0, 100))
              : '[binary]',
        );
        onData?.call(msg);
      },
      onError: onError,
      onDone: () {
        _streamCtrl.close();
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future close([int? code, String? reason]) => _inner.close(code, reason);

  // ── Missing methods fix ────────────────────────
  @override
  Duration? get pingInterval => _inner.pingInterval;

  @override
  set pingInterval(Duration? value) => _inner.pingInterval = value;

  @override
  void addUtf8Text(List<int> bytes) => _inner.addUtf8Text(bytes);

  @override
  Future<E> drain<E>([E? futureValue]) => _inner.drain(futureValue);

  @override
  Future<dynamic> elementAt(int index) => _inner.elementAt(index);

  @override
  Future<bool> every(bool Function(dynamic) test) => _inner.every(test);

  @override
  Stream<dynamic> distinct([bool Function(dynamic, dynamic)? equals]) =>
      _inner.distinct(equals);

  // ── Delegates ─────────────────────────────────
  @override
  int get closeCode => _inner.closeCode ?? 0;

  @override
  String? get closeReason => _inner.closeReason;

  @override
  String get extensions => _inner.extensions;

  @override
  String get protocol => _inner.protocol ?? '';

  @override
  int get readyState => _inner.readyState;

  @override
  void addError(Object e, [StackTrace? st]) => _inner.addError(e, st);

  @override
  Future addStream(Stream s) => _inner.addStream(s);

  @override
  Future get done => _inner.done;

  @override
  Future<bool> any(bool Function(dynamic) t) => _inner.any(t);

  @override
  Stream asBroadcastStream({
    void Function(StreamSubscription)? onListen,
    void Function(StreamSubscription)? onCancel,
  }) => _inner.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(dynamic) c) =>
      _inner.asyncExpand(c);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(dynamic) c) =>
      _inner.asyncMap(c);

  @override
  Stream<R> cast<R>() => _inner.cast<R>();

  @override
  Future<bool> contains(Object? n) => _inner.contains(n);

  @override
  Stream<E> expand<E>(Iterable<E> Function(dynamic) c) => _inner.expand(c);

  @override
  Future get first => _inner.first;

  @override
  Future firstWhere(bool Function(dynamic) t, {dynamic Function()? orElse}) =>
      _inner.firstWhere(t, orElse: orElse);

  @override
  Future<S> fold<S>(S i, S Function(S, dynamic) c) => _inner.fold(i, c);

  @override
  Future forEach(void Function(dynamic) a) => _inner.forEach(a);

  @override
  Stream handleError(Function h, {bool Function(dynamic)? test}) =>
      _inner.handleError(h, test: test);

  @override
  bool get isBroadcast => _inner.isBroadcast;

  @override
  Future<bool> get isEmpty => _inner.isEmpty;

  @override
  Future<String> join([String s = '']) => _inner.join(s);

  @override
  Future get last => _inner.last;

  @override
  Future lastWhere(bool Function(dynamic) t, {dynamic Function()? orElse}) =>
      _inner.lastWhere(t, orElse: orElse);

  @override
  Future<int> get length => _inner.length;

  @override
  Stream<S> map<S>(S Function(dynamic) c) => _inner.map(c);

  @override
  Future pipe(StreamConsumer c) => _inner.pipe(c);

  @override
  Future reduce(dynamic Function(dynamic, dynamic) c) => _inner.reduce(c);

  @override
  Future get single => _inner.single;

  @override
  Future singleWhere(bool Function(dynamic) t,
      {dynamic Function()? orElse}) =>
      _inner.singleWhere(t, orElse: orElse);

  @override
  Stream skip(int c) => _inner.skip(c);

  @override
  Stream skipWhile(bool Function(dynamic) t) => _inner.skipWhile(t);

  @override
  Stream take(int c) => _inner.take(c);

  @override
  Stream takeWhile(bool Function(dynamic) t) => _inner.takeWhile(t);

  @override
  Stream timeout(Duration d, {void Function(EventSink)? onTimeout}) =>
      _inner.timeout(d, onTimeout: onTimeout);

  @override
  Future<List> toList() => _inner.toList();

  @override
  Future<Set> toSet() => _inner.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<dynamic, S> t) =>
      _inner.transform(t);

  @override
  Stream where(bool Function(dynamic) t) => _inner.where(t);
}