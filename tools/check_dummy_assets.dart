import 'dart:io';

void main() {
  final repoRoot = Directory.current.path;
  final dummyFile = File('${repoRoot}/lib/data/dummy_products.dart');
  if (!dummyFile.existsSync()) {
    print('Could not find lib/data/dummy_products.dart');
    exit(2);
  }

  final content = dummyFile.readAsStringSync();
  final regex = RegExp(r"imagePath:\s*'([^']+)'", multiLine: true);
  final matches = regex.allMatches(content).toList();
  if (matches.isEmpty) {
    print('No imagePath entries found in dummy_products.dart');
    exit(0);
  }

  final found = <String, bool>{};

  for (final m in matches) {
    final path = m.group(1)!;
    final file = File('${repoRoot}/$path');
    if (file.existsSync()) {
      found[path] = true;
      continue;
    }
    // try common extension swaps
    final altPaths = <String>{};
    if (path.endsWith('.jpg')) {
      altPaths.add(path.replaceAll(RegExp(r'\.jpg\$'), '.jpeg'));
      altPaths.add(path.replaceAll(RegExp(r'\.jpg\$'), '.webp'));
    } else if (path.endsWith('.jpeg')) {
      altPaths.add(path.replaceAll(RegExp(r'\.jpeg\$'), '.jpg'));
      altPaths.add(path.replaceAll(RegExp(r'\.jpeg\$'), '.webp'));
    } else if (path.endsWith('.webp')) {
      altPaths.add(path.replaceAll(RegExp(r'\.webp\$'), '.jpg'));
      altPaths.add(path.replaceAll(RegExp(r'\.webp\$'), '.jpeg'));
    }
    // add lowercase candidate
    altPaths.add(path.toLowerCase());

    var ok = false;
    for (final alt in altPaths) {
      final altFile = File('${repoRoot}/$alt');
      if (altFile.existsSync()) {
        print('Found (alt) for $path -> $alt');
        ok = true;
        break;
      }
    }
    found[path] = ok;
  }

  print('\nDummy assets check results:');
  var missing = 0;
  for (final entry in found.entries) {
    final status = entry.value ? 'FOUND' : 'MISSING';
    if (!entry.value) missing++;
    print('- ${entry.key}: $status');
  }

  if (missing > 0) {
    print('\nSome dummy product images are missing.');
    exit(3);
  }

  print('\nAll dummy product image assets are present.');
}
