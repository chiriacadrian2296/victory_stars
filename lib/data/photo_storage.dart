import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a win's photo into app-private storage and cleans it up again.
///
/// [ImagePicker] only hands back a path into the OS's own temp/cache area
/// (or a content URI on some Android versions) — not guaranteed to survive
/// past the current session, and never meant to be kept long-term. Every
/// photo a star points to (via [Star.photoPath]) is instead a copy living
/// under this app's own documents directory, made right when it's picked.
class PhotoStorage {
  static const _subdirName = 'win_photos';

  static Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subdirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [picked] into app-private storage under a unique name and
  /// returns the new, permanent path.
  static Future<String> save(XFile picked) async {
    final dir = await _photosDir();
    final dotIndex = picked.name.lastIndexOf('.');
    final extension = dotIndex == -1 ? '.jpg' : picked.name.substring(dotIndex);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedPath = '${dir.path}/$fileName';
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  /// Same as [save], but for a photo that's already been through the 9:16
  /// crop step (see [PhotoCropScreen]) and only exists as encoded bytes —
  /// there's no picker [XFile] backing it to copy from.
  static Future<String> saveBytes(Uint8List bytes, {String extension = '.png'}) async {
    final dir = await _photosDir();
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedPath = '${dir.path}/$fileName';
    await File(savedPath).writeAsBytes(bytes);
    return savedPath;
  }

  /// Deletes the photo at [path], if it still exists. Failures are swallowed
  /// — a leftover file here is a wasted few KB, not worth surfacing an error
  /// for on what's already a best-effort cleanup step.
  static Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup — see doc comment above.
    }
  }
}
