String normalizeUsername(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), '_');

String profileDocumentCode(String username) {
  var hash = 0x811c9dc5;
  for (final unit in normalizeUsername(username).toLowerCase().codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  var value = hash;
  final output = StringBuffer('P');
  for (var i = 0; i < 7; i++) {
    output.write(alphabet[value % alphabet.length]);
    value ~/= alphabet.length;
  }
  return output.toString();
}
