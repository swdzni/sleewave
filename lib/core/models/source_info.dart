class SourceInfo {
  const SourceInfo({
    required this.id,
    required this.name,
    required this.available,
    required this.supportsSearch,
    required this.supportsStream,
    required this.supportsDownload,
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      available: json['available'] == true,
      supportsSearch: json['supports_search'] == true,
      supportsStream: json['supports_stream'] == true,
      supportsDownload: json['supports_download'] == true,
    );
  }

  final String id;
  final String name;
  final bool available;
  final bool supportsSearch;
  final bool supportsStream;
  final bool supportsDownload;

  bool get canSearch => available && supportsSearch;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'available': available,
      'supports_search': supportsSearch,
      'supports_stream': supportsStream,
      'supports_download': supportsDownload,
    };
  }
}
