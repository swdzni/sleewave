import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../constants/app_constants.dart';

class AppFolders {
  const AppFolders({
    required this.root,
    required this.downloads,
    required this.imported,
    required this.covers,
    required this.temp,
  });

  final Directory root;
  final Directory downloads;
  final Directory imported;
  final Directory covers;
  final Directory temp;
}

class FileStorageService {
  AppFolders? _folders;

  AppFolders get folders {
    final folders = _folders;
    if (folders == null) {
      throw StateError('App folders are not initialized.');
    }
    return folders;
  }

  Future<AppFolders> initialize() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, AppConstants.rootFolderName));
    final downloads = Directory(
      p.join(root.path, AppConstants.downloadsFolderName),
    );
    final imported = Directory(
      p.join(root.path, AppConstants.importedFolderName),
    );
    final covers = Directory(p.join(root.path, AppConstants.coversFolderName));
    final temp = Directory(p.join(root.path, AppConstants.tempFolderName));
    for (final directory in [root, downloads, imported, covers, temp]) {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    _folders = AppFolders(
      root: root,
      downloads: downloads,
      imported: imported,
      covers: covers,
      temp: temp,
    );
    await cleanTemp();
    return folders;
  }

  Future<void> cleanTemp() async {
    final temp = folders.temp;
    if (!await temp.exists()) {
      return;
    }
    await for (final entity in temp.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  Future<File> writeTempBytes(List<int> bytes, String name) async {
    final file = File(p.join(folders.temp.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> moveTempToDownloads({
    required File tempFile,
    required String artist,
    required String title,
  }) async {
    final filename = await uniqueFilename(
      folders.downloads,
      '${sanitizeFilename(artist)} - ${sanitizeFilename(title)}.mp3',
    );
    return tempFile.rename(p.join(folders.downloads.path, filename));
  }

  Future<File> copyIntoImported(File source) async {
    final filename = await uniqueFilename(
      folders.imported,
      p.basename(source.path),
    );
    return source.copy(p.join(folders.imported.path, filename));
  }

  Future<List<File>> importedFiles() async {
    final files = <File>[];
    if (!await folders.imported.exists()) {
      return files;
    }
    await for (final entity in folders.imported.list()) {
      if (entity is File && _isAudio(entity.path)) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<String> uniqueFilename(Directory directory, String filename) async {
    final extension = p.extension(filename);
    final base = p.basenameWithoutExtension(filename);
    var candidate = filename;
    var index = 2;
    while (await File(p.join(directory.path, candidate)).exists()) {
      candidate = '$base ($index)$extension';
      index += 1;
    }
    return candidate;
  }

  String sanitizeFilename(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'Unknown' : cleaned;
  }

  bool _isAudio(String path) {
    return const {
      'mp3',
      'm4a',
      'aac',
      'wav',
      'flac',
      'ogg',
    }.contains(p.extension(path).replaceFirst('.', '').toLowerCase());
  }
}
