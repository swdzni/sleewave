import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/network/backend_models.dart';
import 'package:sleewave/core/network/sse_client.dart';

void main() {
  test('parses a multi-event search stream', () async {
    const payload = '''
event: start
data: {"event":"start","query":"pulse","sources":["source_a"],"emitted":0}

event: track
data: {"event":"track","source":"source_a","track":{"title":"Blue Pulse","artist":"Test Artist","duration":241,"result_id":"result-1","availability":{"in_server_cache":true,"on_device":false,"preferred_origin":"server"}},"emitted":1}

event: warning
data: {"event":"warning","source":"source_a","warning":{"source":"source_a","message":"Skipped one source."},"emitted":1}

event: done
data: {"event":"done","emitted":1}

''';
    final events = await SseClient(
      Dio(),
    ).parse(Stream.value(utf8.encode(payload))).toList();

    expect(events, hasLength(4));
    expect(events[0], isA<SearchStarted>());
    expect(events[1], isA<SearchTrackFound>());
    expect((events[1] as SearchTrackFound).track.title, 'Blue Pulse');
    expect(events[2], isA<SearchWarning>());
    expect(events[3], isA<SearchDone>());
  });

  test('parses byte streams backed by Uint8List chunks', () async {
    final stream = Stream<List<int>>.value(
      Uint8List.fromList(utf8.encode('event: done\ndata: {"emitted":0}\n\n')),
    );

    final events = await SseClient(Dio()).parse(stream).toList();

    expect(events.single, isA<SearchDone>());
  });
}
