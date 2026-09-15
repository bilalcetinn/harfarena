import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/account/repositories/account_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_profile.dart';
import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/app_glass_card.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

class EditProfileResult {
  const EditProfileResult({
    required this.profile,
    required this.usernameChanged,
  });

  final PlayerProfile profile;
  final bool usernameChanged;
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({
    required this.playerId,
    required this.username,
    required this.initialAvatarUrl,
    required this.accounts,
    required this.profiles,
    super.key,
  });

  final String playerId;
  final String username;
  final String? initialAvatarUrl;
  final AccountRepository accounts;
  final PlayerProfileDetailsRepository profiles;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  static const _page = Color(0xFFF4F6F5);
  static const _text = Color(0xFF172019);
  static const _muted = Color(0xFF707873);
  static const _border = Color(0xFFDCE5DF);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _username;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  Uint8List? _pickedImage;
  String _pickedContentType = 'image/jpeg';
  bool _saving = false;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    _username.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 420,
        maxHeight: 420,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 420 * 1024) {
        throw ArgumentError(
          'Profil fotoğrafı çok büyük. Daha küçük bir fotoğraf seç.',
        );
      }
      if (!mounted) return;
      setState(() {
        _pickedImage = bytes;
        _pickedContentType =
            file.mimeType ??
            (file.path.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final wantsPasswordChange =
        _currentPassword.text.isNotEmpty ||
        _newPassword.text.isNotEmpty ||
        _confirmPassword.text.isNotEmpty;

    setState(() => _saving = true);
    try {
      if (wantsPasswordChange) {
        await widget.accounts.changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
      }

      String? avatarUrl;
      if (_pickedImage != null) {
        avatarUrl = await widget.profiles.uploadAvatar(
          playerId: widget.playerId,
          bytes: _pickedImage!,
          contentType: _pickedContentType,
        );
      }

      final cleanUsername = _username.text.trim();
      PlayerProfile? updatedProfile;
      if (normalizeUsername(cleanUsername).toLowerCase() !=
              normalizeUsername(widget.username).toLowerCase() ||
          cleanUsername != widget.username) {
        updatedProfile = await widget.accounts.changeUsername(cleanUsername);
      }

      final resultingProfile =
          updatedProfile ??
          PlayerProfile(id: widget.playerId, username: widget.username);
      final canonicalUsername = resultingProfile.username;
      await widget.profiles.updatePublicProfile(
        playerId: widget.playerId,
        displayName: canonicalUsername,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        EditProfileResult(
          profile: resultingProfile,
          usernameChanged: updatedProfile != null,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error) {
    final message = switch (error) {
      FirebaseAuthException(code: 'wrong-password') =>
        'Mevcut şifren doğru değil.',
      FirebaseAuthException(code: 'invalid-credential') =>
        'Mevcut şifren doğru değil.',
      FirebaseAuthException(code: 'weak-password') =>
        'Daha güçlü bir şifre seç.',
      FirebaseAuthException(code: 'requires-recent-login') =>
        'Güvenlik için yeniden giriş yapıp tekrar dene.',
      _ =>
        '$error'
            .replaceFirst('Invalid argument(s): ', '')
            .replaceFirst('Bad state: ', ''),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _page,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.brandGreenDark,
        body: ColoredBox(
          color: _page,
          child: Column(
            children: [
              MainSectionHeader(
                title: 'Profili Düzenle',
                subtitle:
                    'Profil fotoğrafını, kullanıcı adını ve şifreni güncelle.',
                icon: Icons.manage_accounts_rounded,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _EditableAvatar(
                        displayName: _username.text,
                        avatarUrl: widget.initialAvatarUrl,
                        imageBytes: _pickedImage,
                        onTap: _saving ? null : _pickPhoto,
                      ),
                      const SizedBox(height: 22),
                      AppGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle(
                              icon: Icons.person_outline_rounded,
                              title: 'PROFİL BİLGİLERİ',
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel(label: 'KULLANICI ADI'),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _username,
                              enabled: !_saving,
                              maxLength: 16,
                              textCapitalization: TextCapitalization.none,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              decoration: _fieldDecoration(
                                hintText: 'Kullanıcı adın',
                                prefixIcon: const Icon(
                                  Icons.alternate_email_rounded,
                                  color: AppColors.brandGreen,
                                  size: 18,
                                ),
                                suffixIcon: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.brandGreen,
                                  size: 18,
                                ),
                              ),
                              validator: (value) {
                                final clean = normalizeUsername(value ?? '');
                                if (!RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ0-9_]{3,16}$')
                                    .hasMatch(clean)) {
                                  return '3-16 karakter; harf, sayı ve _ kullan.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${normalizeUsername(_username.text)}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.accounts.currentUserCanChangePassword)
                        AppGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                icon: Icons.lock_outline_rounded,
                                title: 'ŞİFREYİ DEĞİŞTİR',
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Değiştirmek istemiyorsan bu alanları boş bırak.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _FieldLabel(label: 'MEVCUT ŞİFRE'),
                              const SizedBox(height: 7),
                              _passwordField(
                                controller: _currentPassword,
                                hidden: _hideCurrentPassword,
                                onToggle: () => setState(
                                  () => _hideCurrentPassword =
                                      !_hideCurrentPassword,
                                ),
                                validator: (value) {
                                  if (_newPassword.text.isNotEmpty &&
                                      (value == null || value.isEmpty)) {
                                    return 'Mevcut şifreni gir.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel(label: 'YENİ ŞİFRE'),
                              const SizedBox(height: 7),
                              _passwordField(
                                controller: _newPassword,
                                hidden: _hideNewPassword,
                                onToggle: () => setState(
                                  () => _hideNewPassword = !_hideNewPassword,
                                ),
                                validator: (value) {
                                  if ((value?.isNotEmpty ?? false) &&
                                      value!.length < 6) {
                                    return 'En az 6 karakter olmalı.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              const _FieldLabel(label: 'YENİ ŞİFRE TEKRAR'),
                              const SizedBox(height: 7),
                              _passwordField(
                                controller: _confirmPassword,
                                hidden: _hideConfirmPassword,
                                onToggle: () => setState(
                                  () => _hideConfirmPassword =
                                      !_hideConfirmPassword,
                                ),
                                validator: (value) {
                                  if (_newPassword.text.isNotEmpty &&
                                      value != _newPassword.text) {
                                    return 'Yeni şifreler aynı değil.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        const AppGlassCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.brandGreen,
                              ),
                              SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  'Google veya misafir hesaplarının şifresi HarfArena içinden değiştirilemez.',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _SaveArea(saving: _saving, onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      obscureText: hidden,
      enableSuggestions: false,
      autocorrect: false,
      validator: validator,
      decoration: _fieldDecoration(
        suffixIcon: IconButton(
          tooltip: hidden ? 'Şifreyi göster' : 'Şifreyi gizle',
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 19,
          ),
        ),
      ),
    );
  }

  static InputDecoration _fieldDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: '',
      filled: true,
      fillColor: const Color(0xCFF4F7F5),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFC94C43)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFC94C43), width: 1.5),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.displayName,
    required this.avatarUrl,
    required this.imageBytes,
    required this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cleanName = displayName.trim().isEmpty
        ? 'Oyuncu'
        : displayName.trim();
    final fallback = Center(
      child: Text(
        cleanName.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: AppColors.brandGreenDark,
          fontSize: 31,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    Widget image = fallback;
    if (imageBytes != null) {
      image = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      final source = avatarUrl!.trim();
      if (source.startsWith('data:image/') && source.contains(';base64,')) {
        try {
          final encoded = source.substring(source.indexOf(';base64,') + 8);
          image = Image.memory(
            base64Decode(encoded),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
        } catch (_) {
          image = fallback;
        }
      } else {
        image = Image.network(
          source,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }

    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: const Color(0xFFE4F1EA),
                    child: image,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 1,
                child: Material(
                  color: AppColors.brandGreenDark,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: const SizedBox.square(
                      dimension: 30,
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Profil Fotoğrafını Değiştir',
            style: TextStyle(
              color: AppColors.brandGreenDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandGreen, size: 18),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: _EditProfileViewState._text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF617067),
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.45,
      ),
    );
  }
}

class _SaveArea extends StatelessWidget {
  const _SaveArea({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: const Border(top: BorderSide(color: Color(0xFFE1E7E3))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreenDark,
              disabledBackgroundColor: AppColors.brandGreenDark.withValues(
                alpha: 0.52,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 19),
            label: Text(
              saving ? 'KAYDEDİLİYOR' : 'DEĞİŞİKLİKLERİ KAYDET',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
