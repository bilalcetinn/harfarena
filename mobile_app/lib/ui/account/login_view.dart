import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/core/constants/app_assets.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/account/errors/email_verification_required_exception.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_page_route.dart';

import 'email_verification_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({required this.onReady, required this.service, super.key});

  final ValueChanged<PlayerProfile> onReady;
  final AccountRepository service;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AccountRepository _service;
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _busy) return;

    await _run(() {
      return _service.signIn(
        email: _identityController.text,
        password: _passwordController.text,
      );
    });
  }

  Future<void> _run(Future<PlayerProfile> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final profile = await action();
      if (mounted) widget.onReady(profile);
    } on EmailVerificationRequiredException {
      if (!mounted) return;
      _openEmailVerification();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openEmailVerification() {
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (verificationContext) => EmailVerificationView(
          service: _service,
          onVerified: widget.onReady,
          onSignedOut: () {
            if (verificationContext.mounted) {
              Navigator.of(verificationContext).pop();
            }
          },
        ),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) =>
            RegisterView(service: _service, onReady: widget.onReady),
      ),
    );
  }

  void _openPasswordReset() {
    Navigator.of(context).push(
      AppPageRoute<void>(builder: (_) => PasswordResetView(service: _service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF7F9FC),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF7F9FC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset(
                        AppAssets.logo,
                        width: 142,
                        height: 112,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Kelime oyununa hoş geldin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF10213A),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Arkadaşlarınla yarış, kelimeler oluştur ve zirveye çık.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF708099),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AuthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      color: Color(0xFF10213A),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF6ED),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Türkçe Kelime Oyunu',
                                    style: TextStyle(
                                      color: AppColors.brandGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _AuthField(
                              controller: _identityController,
                              label: 'E-posta',
                              hint: 'ornek@mail.com',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty || !email.contains('@')) {
                                  return 'Geçerli bir e-posta adresi gir.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),
                            _AuthField(
                              controller: _passwordController,
                              label: 'Şifre',
                              hint: 'Şifreni gir',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              onSubmitted: (_) => _signIn(),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Şifreyi göster'
                                    : 'Şifreyi gizle',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 19,
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) < 6
                                  ? 'Şifre en az 6 karakter olmalı.'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _openPasswordReset,
                                child: const Text('Şifremi Unuttum'),
                              ),
                            ),
                            _PrimaryButton(
                              label: 'GİRİŞ YAP',
                              busy: _busy,
                              onPressed: _signIn,
                            ),
                            const _OrDivider(),
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(_service.signInWithGoogle),
                              icon: const Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              label: const Text('Google ile Devam Et'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10213A),
                                minimumSize: const Size.fromHeight(46),
                                side: const BorderSide(
                                  color: Color(0xFFDCE4EE),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Henüz hesabın yok mu?',
                            style: TextStyle(color: Color(0xFF61718A)),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _openRegister,
                            child: const Text('Kayıt Ol'),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(_service.continueAsGuest),
                        child: const Text('Misafir Olarak Devam Et'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({required this.service, required this.onReady, super.key});

  final AccountRepository service;
  final ValueChanged<PlayerProfile> onReady;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  Timer? _usernameDebounce;
  int _usernameRequestId = 0;
  bool _usernameChecking = false;
  bool? _usernameAvailable;

  bool _busy = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    final requestId = ++_usernameRequestId;
    final trimmed = value.trim();

    if (trimmed.length < 3 || trimmed.length > 16) {
      setState(() {
        _usernameChecking = false;
        _usernameAvailable = null;
      });
      return;
    }

    setState(() {
      _usernameChecking = true;
      _usernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final available = await widget.service.isUsernameAvailable(trimmed);

        if (!mounted || requestId != _usernameRequestId) {
          return;
        }

        setState(() {
          _usernameChecking = false;
          _usernameAvailable = available;
        });
      } on ArgumentError {
        if (!mounted || requestId != _usernameRequestId) {
          return;
        }

        setState(() {
          _usernameChecking = false;
          _usernameAvailable = null;
        });
      } catch (_) {
        if (!mounted || requestId != _usernameRequestId) {
          return;
        }

        // Ağ hatası gibi durumlarda kayıt butonundaki son kontrol
        // yine devreye girecek. Alanı yanlışlıkla "uygun" göstermiyoruz.
        setState(() {
          _usernameChecking = false;
          _usernameAvailable = null;
        });
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() => _busy = true);

    try {
      final available = await widget.service.isUsernameAvailable(
        _username.text,
      );

      if (!available) {
        if (!mounted) return;

        setState(() {
          _usernameAvailable = false;
        });

        _formKey.currentState!.validate();
        return;
      }

      await widget.service.register(
        username: _username.text,
        email: _email.text,
        password: _password.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        AppPageRoute<void>(
          builder: (verificationContext) => EmailVerificationView(
            service: widget.service,
            onVerified: widget.onReady,
            onSignedOut: () {
              if (verificationContext.mounted) {
                Navigator.of(verificationContext).pop();
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        final message = _friendlyAuthError(error);

        if (message == 'Bu kullanıcı adı alınmış.') {
          setState(() {
            _usernameAvailable = false;
          });
          _formKey.currentState!.validate();
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPage(
      title: 'Kayıt Ol',
      subtitle: 'Kullanıcı adını seç, e-postanı doğrula ve oynamaya başla.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AuthField(
              controller: _username,
              label: 'Kullanıcı adı',
              hint: '3-16 karakter',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onChanged: _onUsernameChanged,
              validator: (value) {
                final trimmed = value?.trim() ?? '';

                if (trimmed.length < 3) {
                  return 'En az 3 karakter gir.';
                }

                if (_usernameAvailable == false) {
                  return 'Bu kullanıcı adı alınmış.';
                }

                return null;
              },
            ),
            if (_usernameChecking) ...[
              const SizedBox(height: 7),
              const _UsernameAvailabilityMessage(
                checking: true,
                available: null,
              ),
            ] else if (_usernameAvailable != null) ...[
              const SizedBox(height: 7),
              _UsernameAvailabilityMessage(
                checking: false,
                available: _usernameAvailable,
              ),
            ],
            const SizedBox(height: 13),
            _AuthField(
              controller: _email,
              label: 'E-posta',
              hint: 'bilgi@ornek.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) => !(value?.contains('@') ?? false)
                  ? 'Geçerli bir e-posta gir.'
                  : null,
            ),
            const SizedBox(height: 13),
            _AuthField(
              controller: _password,
              label: 'Şifre',
              hint: 'En az 6 karakter',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Şifre en az 6 karakter olmalı.'
                  : null,
            ),
            const SizedBox(height: 13),
            _AuthField(
              controller: _confirmation,
              label: 'Şifre tekrarı',
              hint: 'Şifreni yeniden gir',
              icon: Icons.lock_reset_rounded,
              obscureText: true,
              onSubmitted: (_) => _register(),
              validator: (value) =>
                  value != _password.text ? 'Şifreler aynı değil.' : null,
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: 'HESAP OLUŞTUR',
              busy: _busy,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetView extends StatefulWidget {
  const PasswordResetView({required this.service, super.key});

  final AccountRepository service;

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPage(
      title: 'Şifremi Unuttum',
      subtitle: _sent
          ? 'Sıfırlama bağlantısı gönderildi. E-posta kutunu kontrol et.'
          : 'Hesabına bağlı e-posta adresini gir.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.brandGreenDark,
              size: 54,
            ),
            const SizedBox(height: 18),
            _AuthField(
              controller: _email,
              label: 'E-posta',
              hint: 'bilgi@ornek.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _send(),
              validator: (value) => !(value?.contains('@') ?? false)
                  ? 'Geçerli bir e-posta gir.'
                  : null,
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: _sent ? 'TEKRAR GÖNDER' : 'SIFIRLAMA BAĞLANTISI GÖNDER',
              busy: _busy,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPage extends StatelessWidget {
  const _AuthPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.brandGreenDark,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AuthCard(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D10213A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF25364E),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: !obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4EE)),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsernameAvailabilityMessage extends StatelessWidget {
  const _UsernameAvailabilityMessage({
    required this.checking,
    required this.available,
  });

  final bool checking;
  final bool? available;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Row(
        children: [
          SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.7,
              color: Color(0xFF708099),
            ),
          ),
          SizedBox(width: 7),
          Text(
            'Kullanıcı adı kontrol ediliyor...',
            style: TextStyle(
              color: Color(0xFF708099),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final isAvailable = available == true;

    return Row(
      children: [
        Icon(
          isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: isAvailable ? AppColors.brandGreen : const Color(0xFFC94C43),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable
              ? 'Kullanıcı adı kullanılabilir.'
              : 'Bu kullanıcı adı alınmış.',
          style: TextStyle(
            color: isAvailable ? AppColors.brandGreen : const Color(0xFFC94C43),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: .55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('veya', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}

String _friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'E-posta veya şifre hatalı.',
      'email-already-in-use' => 'Bu e-posta zaten kullanılıyor.',
      'invalid-email' => 'Geçerli bir e-posta adresi gir.',
      'weak-password' => 'Daha güçlü bir şifre seç.',
      'network-request-failed' => 'İnternet bağlantını kontrol et.',
      'operation-not-allowed' =>
        'Bu giriş yöntemi Firebase panelinde etkin değil.',
      'configuration-not-found' => 'Firebase Authentication henüz etkin değil. Firebase panelinden bu giriş yöntemini açın.',
      _ => error.message ?? 'Giriş işlemi tamamlanamadı.',
    };
  }
  return '$error'
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Bad state: ', '');
}
