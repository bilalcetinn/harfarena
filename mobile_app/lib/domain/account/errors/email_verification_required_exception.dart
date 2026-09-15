class EmailVerificationRequiredException implements Exception {
  const EmailVerificationRequiredException(this.email);

  final String? email;

  @override
  String toString() => 'E-posta doğrulaması gerekli.';
}
