import 'dart:io';

import 'package:turkish_word_engine/turkish_word_engine.dart';

/// Kullanım:
/// dart run tool/build_dictionary.dart input.txt output.txt
///
/// Kaynak listedeki boşluk, noktalama, apostrof veya Türkçe oyun alfabesi
/// dışında karakter içeren girdileri eler; kalanları normalize edip tekilleştirir.
void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/build_dictionary.dart <input.txt> <output.txt>',
    );
    exitCode = 64;
    return;
  }

  final input = File(args[0]);
  if (!input.existsSync()) {
    stderr.writeln('Input file not found: ${input.path}');
    exitCode = 66;
    return;
  }

  final words = <String>{};
  var rejected = 0;

  for (final line in input.readAsLinesSync()) {
    final normalized = tryNormalizeTurkishWord(line);
    if (normalized == null || normalized.length > 15) {
      rejected++;
      continue;
    }
    words.add(normalized);
  }

  final sorted = words.toList()..sort();
  File(args[1]).writeAsStringSync('${sorted.join('\n')}\n');

  stdout.writeln('Accepted: ${sorted.length}');
  stdout.writeln('Rejected: $rejected');
  stdout.writeln('Output: ${args[1]}');
}
