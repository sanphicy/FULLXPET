import 'dart:convert';
import 'dart:io';

void main() {
  final supportedLocales = ['en', 'zh'];
  // ⚠️ 这里的路径已经修改为你实际的目录结构
  final srcDir = Directory('lib/common/l10n/src');
  final targetDir = Directory('lib/common/l10n');

  if (!srcDir.existsSync()) {
    print('❌ 源文件夹不存在: ${srcDir.path}');
    return;
  }

  for (var locale in supportedLocales) {
    final mergedMap = <String, dynamic>{};
    mergedMap['@@locale'] = locale;

    // 开启 recursive: true 递归遍历所有子文件夹 (比如 auth, device)
    final files = srcDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('_$locale.arb'));

    for (var file in files) {
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> map = jsonDecode(content);

        map.remove('@@locale');

        // 检查是否有重复的 Key
        for (var key in map.keys) {
          if (mergedMap.containsKey(key)) {
            print('⚠️ 警告: 发现重复的 Key [$key] 在文件 ${file.path} 中，将会被覆盖！');
          }
        }

        mergedMap.addAll(map);
      } catch (e) {
        print('❌ 解析文件失败 ${file.path}: $e');
      }
    }

    final targetFile = File('${targetDir.path}/app_$locale.arb');
    const encoder = JsonEncoder.withIndent('  ');
    targetFile.writeAsStringSync(encoder.convert(mergedMap));

    print('✅ 成功合并 $locale 语言包，共 ${mergedMap.length - 1} 个词条 -> ${targetFile.path}');
  }
}
