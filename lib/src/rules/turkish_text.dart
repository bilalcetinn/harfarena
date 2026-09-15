const String turkishAlphabet = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';

const Map<String, String> _turkishUppercase = {
  'a': 'A',
  'b': 'B',
  'c': 'C',
  'ç': 'Ç',
  'd': 'D',
  'e': 'E',
  'f': 'F',
  'g': 'G',
  'ğ': 'Ğ',
  'h': 'H',
  'ı': 'I',
  'i': 'İ',
  'j': 'J',
  'k': 'K',
  'l': 'L',
  'm': 'M',
  'n': 'N',
  'o': 'O',
  'ö': 'Ö',
  'p': 'P',
  'r': 'R',
  's': 'S',
  'ş': 'Ş',
  't': 'T',
  'u': 'U',
  'ü': 'Ü',
  'v': 'V',
  'y': 'Y',
  'z': 'Z',
};

String? tryNormalizeTurkishWord(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final buffer = StringBuffer();
  for (final rune in trimmed.runes) {
    final char = String.fromCharCode(rune);
    final upper = _turkishUppercase[char] ?? char;
    if (upper.length != 1 || !turkishAlphabet.contains(upper)) {
      return null;
    }
    buffer.write(upper);
  }
  return buffer.toString();
}

String normalizeTurkishRackLetter(String input) {
  if (input == '?') return '?';
  final normalized = tryNormalizeTurkishWord(input);
  if (normalized == null || normalized.length != 1) {
    throw ArgumentError('Invalid rack letter: $input');
  }
  return normalized;
}
