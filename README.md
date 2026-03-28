# WebSocket DevTools Profiler

**GSoC 2026 — Sample Project**  
**Organization:** Dart  
**Project:** Add WebSocket/gRPC Support to Flutter DevTools Network Panel  
**Mentors:** Elliott Brooks, Samuel Rawlins

---

## Problem Statement

Flutter DevTools Network Panel currently only shows **HTTP traffic**. Real-world Flutter apps heavily use WebSocket for chat, live feeds, and real-time data — but developers have **zero visibility** into what is happening at the frame level.

```
DevTools Network Panel (Today)
--------------------------------------------------
  GET  /api/users       200   120ms    OK
  POST /api/login       200   340ms    OK
  WebSocket traffic     ???   ???      BLIND SPOT
  gRPC calls            ???   ???      BLIND SPOT
--------------------------------------------------
```

This project demonstrates the **instrumentation layer** needed to fix this — using the same `dart:developer` Timeline approach that HTTP profiling uses today.

---

## Architecture

```
+----------------------------------------------------------+
|                   Flutter / Dart App                     |
|                                                          |
|  // ONE LINE CHANGE — drop-in replacement                |
|  final socket = await WebSocketProfiler.connect(url);    |
|                         |                                |
|         ProfileableWebSocket                             |
|         implements dart:io WebSocket                     |
|                                                          |
|  add()    --> intercepts outgoing frames  [sent]         |
|  listen() --> intercepts incoming frames  [recv]         |
|                                                          |
|  WebSocketFrameEvent {                                   |
|    id, timestamp, direction,                             |
|    type, sizeBytes, elapsed,                             |
|    connectionId, payloadPreview                          |
|  }                                                       |
+-------------------------+--------------------------------+
                          |
                          | dart:developer.Timeline.instantSync()
                          | same mechanism as HTTP profiling today
                          |
+-------------------------+--------------------------------+
|             dart:developer Timeline                      |
|                                                          |
|  HttpClient profiling  [already here]                    |
|  WebSocket profiling   [added by this project]           |
|                                                          |
|  Low risk — reuses existing DevTools infrastructure      |
+-------------------------+--------------------------------+
                          |
                          | VM Service Protocol (existing)
                          |
+-------------------------+--------------------------------+
|          Flutter DevTools Network Panel                  |
|                                                          |
|  [ HTTP ]  [ WebSocket ]  [ gRPC ]                       |
|               ^ NEW tab — this project                   |
|                                                          |
|  Shows: frame events, direction, bytes, latency          |
+----------------------------------------------------------+
```

---

## Key Design Decisions

### 1. Why dart:developer.Timeline and not a new VM Service stream?

HTTP profiling in `dart:io` already posts to `dart:developer` Timeline events. Reusing this infrastructure means:

- Lower risk — no VM changes needed in Phase 1
- DevTools already consumes timeline events
- Incremental approach — dedicated VM Service stream can be added in Phase 2
- Consistent with existing profiling patterns in the SDK

### 2. Why implements WebSocket and not just a wrapper?

```dart
// Basic wrapper — what most students do
class ProfileableWebSocket {
  final WebSocket _socket;
  void add(data) { ... }
}

// Proper interface — this project
class ProfileableWebSocket implements WebSocket {
  // drop-in replacement — zero app code changes needed
}
```

By implementing the full interface, existing apps can switch with **one line change** — no refactoring required anywhere in the codebase.

### 3. Why a WebSocketProfiler registry?

Real apps have **multiple simultaneous WebSocket connections**. The registry manages all of them with a unique `connectionId` per connection — exactly like `HttpClient` works internally in `dart:io`.

---

## Project Structure

```
websocket_profiler/
|
+-- lib/
|   +-- websocket_profiler.dart         (public exports)
|   +-- src/
|       +-- websocket_frame_event.dart  (typed event model, mirrors HttpProfileData)
|       +-- profileable_websocket.dart  (core wrapper, implements WebSocket)
|       +-- websocket_profiler.dart     (connection registry, manages multiple sockets)
|       +-- table_printer.dart          (CLI display utility)
|
+-- bin/
|   +-- main.dart                       (interactive CLI demo)
|
+-- test/
|   +-- profiler_test.dart              (9 unit tests, no network needed)
|
+-- pubspec.yaml                        (zero external dependencies)
```

---

## Sample Output

```
WebSocket Profiler — GSoC Sample
Connecting...

Connected! ID: ws_1
Commands: /stats  /summary  /exit

------------------------------------------------------------------------------
ID   TIME           DIR       TYPE     BYTES    ELAPSED     PREVIEW
------------------------------------------------------------------------------
1    14:06:41.786   sent      text     20B      +22274ms    hello GSOC community
2    14:06:42.196   recv      text     20B      +22684ms    hello GSOC community
3    14:06:53.829   sent      text     17B      +34317ms    its Abdullah Here
4    14:06:54.090   recv      text     17B      +34578ms    its Abdullah Here
5    14:07:09.281   sent      text     13B      +49769ms    how are doing
6    14:07:09.505   recv      text     13B      +49993ms    how are doing
7    14:07:26.901   sent      text     17B      +67389ms    testing websocket
8    14:07:27.352   recv      text     17B      +67840ms    testing websocket
------------------------------------------------------------------------------

Summary:
   Connections : 1
   Events      : 8
   Sent        : 67B
   Received    : 67B
```

---

## Tests

```bash
dart test
```

```
00:02 +9: All tests passed!
```

| Test | Description |
|------|-------------|
| toJson serialization | Event model JSON round-trip |
| sent event recorded | add() intercepts outgoing frames |
| received event recorded | listen() intercepts incoming frames |
| correct order | sent and received sequence maintained |
| lastEvents(n) | returns correct subset |
| frameEvents stream | real-time event stream works |
| connectionId | correct ID assigned per connection |
| sizeBytes accuracy | UTF-8 byte count is correct |
| registry reset | summary zeroes correctly after reset |

No network required — MockWebSocket used for all tests.

---

## GSoC Road Map

| Phase | What | Status |
|-------|------|--------|
| Sample | ProfileableWebSocket wrapper | Done |
| Sample | dart:developer Timeline integration | Done |
| Sample | CLI demo with 9 unit tests | Done |
| Phase 1 | Integrate instrumentation into dart:io SDK | GSoC coding period |
| Phase 1 | Extend VM Service Protocol for WebSocket | GSoC coding period |
| Phase 2 | DevTools Network Panel — WebSocket tab UI | GSoC coding period |
| Phase 3 | gRPC traffic support | GSoC coding period |
| Phase 4 | DevTools Network Panel — gRPC tab UI | GSoC coding period |

---

## Running

```bash
# Clone
git clone https://github.com/abdullah-arain9/websocket-devtools-profiler.git
cd websocket-devtools-profiler

# Install dependencies
dart pub get

# Run tests
dart test

# Run CLI demo
dart run bin/main.dart
```

CLI Commands:

| Command | What it does |
|---------|-------------|
| any message | Send to echo server — response appears instantly |
| /stats | Show last 10 frame events as formatted table |
| /summary | Show total connections and bytes sent/received |
| /exit | Quit and print full event log |

---

## Related Links

- [GSoC 2026 Dart Project Ideas](https://dart.dev/community/gsoc)
- [dart:developer Timeline docs](https://api.dart.dev/dart-developer/Timeline-class.html)
- [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md)
- [Flutter DevTools Source](https://github.com/flutter/devtools)
- [dart:io WebSocket docs](https://api.dart.dev/dart-io/WebSocket-class.html)

---

## About

Built as a GSoC 2026 sample project to demonstrate understanding of the instrumentation layer needed for WebSocket support in Flutter DevTools Network Panel.

The goal is not just to wrap WebSocket — but to integrate profiling at the right layer so DevTools can surface this data with minimal risk and maximum reuse of existing infrastructure.
