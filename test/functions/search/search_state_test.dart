import 'package:flutter_test/flutter_test.dart';
import 'package:sleewave/core/models/source_info.dart';
import 'package:sleewave/functions/search/models/search_state.dart';

void main() {
  const sources = [
    SourceInfo(
      id: 'source-a',
      name: 'Source A',
      available: true,
      supportsSearch: true,
      supportsStream: true,
      supportsDownload: true,
    ),
    SourceInfo(
      id: 'source-b',
      name: 'Source B',
      available: true,
      supportsSearch: true,
      supportsStream: true,
      supportsDownload: true,
    ),
    SourceInfo(
      id: 'source-c',
      name: 'Source C',
      available: false,
      supportsSearch: true,
      supportsStream: true,
      supportsDownload: true,
    ),
  ];

  test('empty source selection searches all available sources', () {
    final state = SearchState(availableSources: sources);

    expect(state.effectiveSourceIds(), ['source-a', 'source-b']);
  });

  test('explicit source selection leaves all mode', () {
    final state = SearchState(
      availableSources: sources,
      selectedSourceIds: const ['source-b', 'source-c'],
    );

    expect(state.effectiveSourceIds(), ['source-b']);
  });
}
