import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vastuscan_ar/models/scan_session.dart';

class StorageService {
  StorageService._privateConstructor();
  static final StorageService instance = StorageService._privateConstructor();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${directory.path}/vastu_scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    return scansDir.path;
  }

  /// Saves a scan session to a JSON file
  Future<void> saveSession(ScanSession session) async {
    try {
      final path = await _localPath;
      final file = File('$path/${session.id}.json');
      final jsonString = jsonEncode(session.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  /// Loads all saved scan sessions
  Future<List<ScanSession>> getAllSessions() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      List<ScanSession> sessions = [];

      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (var entity in entities) {
          if (entity is File && entity.path.endsWith('.json')) {
            final jsonString = await entity.readAsString();
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            sessions.add(ScanSession.fromJson(jsonMap));
          }
        }
      }
      
      // Sort by newest first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }

  /// Deletes a specific scan session
  Future<void> deleteSession(String id) async {
    try {
      final path = await _localPath;
      final file = File('$path/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting session: $e');
    }
  }
}
