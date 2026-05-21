// ignore_for_file: experimental_member_use

import 'package:just_audio/just_audio.dart';

import '../../repositories/backend_repository.dart';

class BackendStreamAudioSource extends StreamAudioSource {
  BackendStreamAudioSource({
    required this.backend,
    required this.resultId,
    required this.directUrl,
    super.tag,
  });

  final BackendRepository backend;
  final String resultId;
  final bool directUrl;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final response = await backend.openStream(
      resultId,
      start: start,
      end: end,
      directUrl: directUrl,
    );
    final headers = response.headers;
    final contentLength = int.tryParse(headers.value('content-length') ?? '');
    final contentRange = _parseContentRange(headers.value('content-range'));
    final rangeSupported = response.statusCode == 206 && contentRange != null;
    final offset = rangeSupported ? contentRange.start : 0;
    final sourceLength = contentRange?.sourceLength ?? contentLength;
    return StreamAudioResponse(
      rangeRequestsSupported: rangeSupported,
      sourceLength: sourceLength,
      contentLength: contentRange?.contentLength ?? contentLength,
      offset: offset,
      stream: response.data?.stream ?? const Stream.empty(),
      contentType: headers.value('content-type') ?? 'audio/mpeg',
    );
  }

  _ContentRange? _parseContentRange(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    final sourceLength = match.group(3) == '*'
        ? null
        : int.tryParse(match.group(3)!);
    if (start == null || end == null || end < start) {
      return null;
    }
    return _ContentRange(start: start, end: end, sourceLength: sourceLength);
  }
}

class _ContentRange {
  const _ContentRange({
    required this.start,
    required this.end,
    required this.sourceLength,
  });

  final int start;
  final int end;
  final int? sourceLength;

  int get contentLength => end - start + 1;
}
