import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({
    required this.service,
    required this.onVerified,
    required this.onSignedOut,
    super.key,
  });

  final AccountRepository service;
  final ValueChanged<PlayerProfile> onVerified;
  final VoidCallback onSignedOut;

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  String get _email => widget.service.currentUserEmail ?? 'e-posta adresin';

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_checking) return;

    setState(() {
      _checking = true;
    });

    try {
      final profile = await widget.service.refreshVerifiedProfile();

      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-posta henüz doğrulanmamış. Maildeki bağlantıya dokunduktan sonra tekrar dene.',
            ),
          ),
        );
        return;
      }

      widget.onVerified(profile);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_verificationError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;

    setState(() {
      _resending = true;
    });

    try {
      await widget.service.sendVerificationEmail();

      if (!mounted) return;

      _startCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Doğrulama bağlantısı $_email adresine tekrar gönderildi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_verificationError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();

    setState(() {
      _resendCooldown = 30;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
        return;
      }

      setState(() {
        _resendCooldown--;
      });
    });
  }

  Future<void> _useDifferentAccount() async {
    await widget.service.signOut();

    if (!mounted) return;

    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF4F7F9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('E-posta Doğrulama'),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.brandGreenDark,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
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
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF6ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 38,
                          color: AppColors.brandGreenDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'E-postanı doğrula',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF10213A),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hesabını güvenceye almak ve ileride şifreni sıfırlayabilmek için e-posta adresini doğrulaman gerekiyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.45,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              size: 19,
                              color: AppColors.brandGreen,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF25364E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _checking ? null : _checkVerification,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: _checking
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_rounded, size: 19),
                        label: const Text(
                          'DOĞRULADIM, DEVAM ET',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _resending || _resendCooldown > 0
                            ? null
                            : _resend,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Tekrar Gönder ($_resendCooldown sn)'
                              : _resending
                              ? 'Gönderiliyor...'
                              : 'Doğrulama Mailini Tekrar Gönder',
                        ),
                      ),
                      TextButton(
                        onPressed: _checking || _resending
                            ? null
                            : _useDifferentAccount,
                        child: const Text(
                          'Farklı Hesap Kullan',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
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

String _verificationError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'too-many-requests' =>
        'Çok fazla doğrulama isteği gönderildi. Biraz sonra tekrar dene.',
      'network-request-failed' => 'İnternet bağlantını kontrol et.',
      'user-token-expired' ||
      'user-disabled' => 'Oturum süren dolmuş. Yeniden giriş yap.',
      _ => error.message ?? 'E-posta doğrulama işlemi tamamlanamadı.',
    };
  }

  return '$error'
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Bad state: ', '');
}
