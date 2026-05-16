// ignore_for_file: experimental_member_use

import 'package:just_audio/just_audio.dart';

import '../../repositories/backend_repository.dart';

class BackendStreamAudioSource extends StreamAudioSource {
  BackendStreamAudioSource({
    required this.backend,
    required this.resultId,
    super.tag,
  });

  final BackendRepository backend;
  final String resultId;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final response = await backend.openStream(resultId);
    final contentLength = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    return StreamAudioResponse(
      rangeRequestsSupported: false,
      sourceLength: contentLength,
      contentLength: contentLength,
      offset: 0,
      stream: response.data?.stream ?? const Stream.empty(),
      contentType: response.headers.value('content-type') ?? 'audio/mpeg',
    );
  }
}
