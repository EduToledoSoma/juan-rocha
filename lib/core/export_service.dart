import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Returns the saved file path on desktop. On mobile opens the native share sheet.
Future<String?> deliverExport({
  required String filename,
  required List<int> bytes,
  String? message,
}) async {
  final Directory dir;
  if (Platform.isLinux || Platform.isWindows) {
    final base = await getApplicationDocumentsDirectory();
    dir = Directory(p.join(base.path, 'JuanRochaBoxe', 'Exportacoes'));
  } else {
    dir = await getTemporaryDirectory();
  }
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
  if (Platform.isLinux || Platform.isWindows) {
    return file.path;
  }
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: message),
  );
  return null;
}
