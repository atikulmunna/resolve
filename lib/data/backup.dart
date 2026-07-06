import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/habit.dart';
import '../models/relapse.dart';

/// Backup export / import (Tier-3). Resolve is offline and single-device, so a
/// lost or wiped phone means a lost streak history, emotionally brutal for
/// exactly this kind of app. This serializes the entire state to a portable
/// JSON file the user can save/share, and restores it back.
///
/// Reuses the models' existing `toJson` / `fromJson` end-to-end, so the backup
/// format tracks persistence automatically.
class Backup {
  Backup._();

  static const int version = 1;

  /// Encode the full state to a pretty JSON document.
  static String encode(Habit habit, List<Relapse> relapses) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'resolve',
      'version': version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'habit': habit.toJson(),
      'relapses': relapses.map((r) => r.toJson()).toList(),
    });
  }

  /// Parse a backup document. Throws [FormatException] on anything that isn't a
  /// recognizable Resolve backup, so the UI can show a clean error.
  static ({Habit habit, List<Relapse> relapses}) decode(String raw) {
    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('That file is not valid JSON.');
    }
    if (parsed is! Map<String, dynamic> ||
        parsed['habit'] is! Map<String, dynamic>) {
      throw const FormatException('That is not a Resolve backup.');
    }
    final habit = Habit.fromJson(parsed['habit'] as Map<String, dynamic>);
    final relapses = <Relapse>[
      for (final r in (parsed['relapses'] as List? ?? []))
        Relapse.fromJson(r as Map<String, dynamic>),
    ];
    return (habit: habit, relapses: relapses);
  }

  /// Write the backup to a temp file and open the system share sheet.
  static Future<void> share(Habit habit, List<Relapse> relapses) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first; // yyyy-MM-dd
    final file = File('${dir.path}/resolve-backup-$stamp.json');
    await file.writeAsString(encode(habit, relapses));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Resolve backup',
    );
  }

  /// Prompt the user to pick a backup file and decode it. Returns null if the
  /// picker was cancelled; throws [FormatException] on an unreadable file.
  static Future<({Habit habit, List<Relapse> relapses})?> pickAndDecode() async {
    // FileType.any (not custom/json): Android's document picker is unreliable
    // filtering on a .json extension. We load the bytes and validate ourselves.
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final String content;
    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else {
      throw const FormatException('Could not read the selected file.');
    }
    return decode(content);
  }
}
