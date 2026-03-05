import 'package:flutter/services.dart';

class TemplateCategory {
  final String name;
  final String folder;
  const TemplateCategory({required this.name, required this.folder});
}

const templateCategories = [
  TemplateCategory(name: 'Character',      folder: 'assets/cards/templates/character/'),
  TemplateCategory(name: 'Starting Items', folder: 'assets/cards/templates/startingitems/'),
  TemplateCategory(name: 'Treasure',       folder: 'assets/cards/templates/treasure/'),
  TemplateCategory(name: 'Boss',           folder: 'assets/cards/templates/boss/'),
  TemplateCategory(name: 'Monster',        folder: 'assets/cards/templates/monster/'),
  TemplateCategory(name: 'Room',           folder: 'assets/cards/templates/room/'),
  TemplateCategory(name: 'Happenings',     folder: 'assets/cards/templates/happenings/'),
  TemplateCategory(name: 'Loots',          folder: 'assets/cards/templates/loots/'),
];

const _backgroundsFolder = 'assets/cards/backgrounds/';
const _stickersRoot = 'assets/stickers/';

// Stickers grouped by subfolder name; root-level images go into "General".
Future<Map<String, List<String>>> loadStickers() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final result = <String, List<String>>{};

  for (final path in manifest.listAssets()
      .where((p) => p.startsWith(_stickersRoot) && p.endsWith('.png'))
      .toList()
    ..sort()) {
    final relative = path.substring(_stickersRoot.length);
    final slash = relative.indexOf('/');
    final category = slash == -1
        ? 'General'
        : relative.substring(0, slash).replaceAll(RegExp(r'^\d+\.\s*'), '');
    result.putIfAbsent(category, () => []).add(path);
  }
  return result;
}

Future<List<String>> loadBackgrounds() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets()
      .where((p) => p.startsWith(_backgroundsFolder) && p.endsWith('.png'))
      .toList()
    ..sort();
}

// Returns (categoryName, assetPath) pairs ordered by category then filename.
Future<List<(String, String)>> loadAllTemplates() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = manifest.listAssets();

  final result = <(String, String)>[];
  for (final cat in templateCategories) {
    final assets = allAssets
        .where((p) => p.startsWith(cat.folder) && p.endsWith('.png'))
        .toList()
      ..sort();
    for (final asset in assets) {
      result.add((cat.name, asset));
    }
  }
  return result;
}
