import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/repositories/game_audio_repository.dart';
import 'package:kelime_analiz_mobile/domain/notifications/repositories/app_notification_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/models/player_settings.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/local_settings_repository.dart';
import 'package:kelime_analiz_mobile/domain/profile/repositories/player_profile_details_repository.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    required this.onLogout,
    required this.playerId,
    required this.preferencesService,
    required this.profiles,
    required this.notifications,
    required this.audio,
    super.key,
  });

  final VoidCallback onLogout;
  final String playerId;
  final LocalSettingsRepository preferencesService;
  final PlayerProfileDetailsRepository profiles;
  final AppNotificationRepository notifications;
  final GameAudioRepository audio;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const _page = Color(0xFFF4F6F5);
  static const _text = Color(0xFF172019);
  static const _muted = Color(0xFF707873);
  static const _border = Color(0xFFE3E8E4);
  static const _loss = Color(0xFFC94C43);

  late final LocalSettingsRepository _preferences;

  bool _loading = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _turnNotificationsEnabled = true;
  bool _inviteNotificationsEnabled = true;
  bool _resultNotificationsEnabled = true;
  int _defaultTurnDurationSeconds = 120;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferencesService;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferences.load();
    if (!mounted) return;

    setState(() {
      _soundEnabled = settings.soundEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
      _turnNotificationsEnabled = settings.turnNotificationsEnabled;
      _inviteNotificationsEnabled = settings.inviteNotificationsEnabled;
      _resultNotificationsEnabled = settings.resultNotificationsEnabled;
      _defaultTurnDurationSeconds = settings.defaultTurnDurationSeconds;
      _loading = false;
    });
    await _syncRemote(showError: false);
  }

  PlayerSettings get _remoteSettings => PlayerSettings(
    soundEffects: _soundEnabled,
    vibration: _vibrationEnabled,
    turnNotifications: _turnNotificationsEnabled,
    inviteNotifications: _inviteNotificationsEnabled,
    resultNotifications: _resultNotificationsEnabled,
    defaultTurnDurationSeconds: _defaultTurnDurationSeconds,
  );

  Future<void> _syncRemote({bool showError = true}) async {
    try {
      await widget.profiles.updateSettings(widget.playerId, _remoteSettings);
    } catch (_) {
      if (showError) {
        _showMessage('Ayarlar telefona kaydedildi, sunucuya aktarılamadı.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundEnabled = value);
    await widget.audio.setEnabled(value);
    if (value) await widget.audio.play(GameSound.uiTap);
    await _syncRemote();
  }

  Future<void> _setVibration(bool value) async {
    setState(() => _vibrationEnabled = value);
    await _preferences.setVibrationEnabled(value);
    if (value) await HapticFeedback.mediumImpact();
    await _syncRemote();
  }

  Future<void> _setTurnNotifications(bool value) async {
    final enabled = await _resolveNotificationValue(value);
    if (!mounted) return;
    setState(() => _turnNotificationsEnabled = enabled);
    await _preferences.setTurnNotificationsEnabled(enabled);
    await _syncRemote();
  }

  Future<void> _setInviteNotifications(bool value) async {
    final enabled = await _resolveNotificationValue(value);
    if (!mounted) return;
    setState(() => _inviteNotificationsEnabled = enabled);
    await _preferences.setInviteNotificationsEnabled(enabled);
    await _syncRemote();
  }

  Future<void> _setResultNotifications(bool value) async {
    final enabled = await _resolveNotificationValue(value);
    if (!mounted) return;
    setState(() => _resultNotificationsEnabled = enabled);
    await _preferences.setResultNotificationsEnabled(enabled);
    await _syncRemote();
  }

  Future<bool> _resolveNotificationValue(bool value) async {
    if (!value) return false;
    final granted = await widget.notifications.registerForPlayer(
      widget.playerId,
    );
    if (!granted) {
      _showMessage('Telefon bildirim izni verilmedi.');
    }
    return granted;
  }

  Future<void> _chooseDefaultDuration() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Varsayılan hamle süresi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
            for (final seconds in kTurnDurationOptions)
              ListTile(
                title: Text(formatTurnDuration(seconds)),
                trailing: seconds == _defaultTurnDurationSeconds
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brandGreen,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        color: Color(0xFF9AA7B8),
                      ),
                onTap: () => Navigator.of(sheetContext).pop(seconds),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _defaultTurnDurationSeconds = selected);
    await _preferences.setDefaultTurnDurationSeconds(selected);
    await _syncRemote();
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
        body: SafeArea(
          top: false,
          bottom: false,
          child: ColoredBox(
            color: _page,
            child: Column(
              children: [
                MainSectionHeader(
                  title: 'Ayarlar',
                  subtitle:
                      'Oyun, bildirim ve uygulama tercihlerini buradan yönet.',
                  icon: Icons.settings_rounded,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandGreen,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          children: [
                            const _SectionLabel(label: 'OYUN'),
                            const SizedBox(height: 7),
                            _SettingsGroup(
                              children: [
                                _SettingsSwitchTile(
                                  icon: Icons.volume_up_rounded,
                                  iconColor: const Color(0xFFE99A18),
                                  iconBackground: const Color(0xFFFFF5DD),
                                  title: 'Ses Efektleri',
                                  value: _soundEnabled,
                                  onChanged: _setSound,
                                ),
                                const _SettingsDivider(),
                                _SettingsSwitchTile(
                                  icon: Icons.vibration_rounded,
                                  iconColor: const Color(0xFF5279ED),
                                  iconBackground: const Color(0xFFEDF2FF),
                                  title: 'Titreşim',
                                  value: _vibrationEnabled,
                                  onChanged: _setVibration,
                                ),
                                const _SettingsDivider(),
                                _SettingsValueTile(
                                  icon: Icons.schedule_rounded,
                                  title: 'Varsayılan Hamle Süresi',
                                  value: formatTurnDuration(
                                    _defaultTurnDurationSeconds,
                                  ),
                                  onTap: _chooseDefaultDuration,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _SectionLabel(label: 'BİLDİRİMLER'),
                            const SizedBox(height: 7),
                            _SettingsGroup(
                              children: [
                                _SettingsSwitchTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Sıra Bildirimleri',
                                  subtitle: 'Bir oyunda sıra sana geçtiğinde haber ver.',
                                  value: _turnNotificationsEnabled,
                                  onChanged: _setTurnNotifications,
                                ),
                                const _SettingsDivider(indent: 14),
                                _SettingsSwitchTile(
                                  icon: Icons.mark_email_unread_outlined,
                                  title: 'Oyun Davetleri',
                                  subtitle: 'Yeni oyun davetlerini bildir.',
                                  value: _inviteNotificationsEnabled,
                                  onChanged: _setInviteNotifications,
                                ),
                                const _SettingsDivider(indent: 14),
                                _SettingsSwitchTile(
                                  icon: Icons.emoji_events_outlined,
                                  title: 'Oyun Sonuçları',
                                  subtitle: 'Tamamlanan maç sonucunu bildir.',
                                  value: _resultNotificationsEnabled,
                                  onChanged: _setResultNotifications,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _SectionLabel(label: 'UYGULAMA'),
                            const SizedBox(height: 7),
                            const _SettingsGroup(
                              children: [
                                _SettingsValueTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'HarfArena',
                                  value: 'Sürüm 0.10.6',
                                  showChevron: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    14 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text('ÇIKIŞ YAP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _loss,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFF0C2BE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Çıkış yapılsın mı?',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'HarfArena hesabından çıkış yapacaksın.',
          style: TextStyle(color: _muted, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _loss),
            child: const Text('ÇIKIŞ YAP'),
          ),
        ],
      ),
    );

    if (confirmed == true) widget.onLogout();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF18A957),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.55,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _SettingsViewState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.iconColor = AppColors.brandGreen,
    this.iconBackground = const Color(0xFFEAF6ED),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _SettingsViewState._text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: _SettingsViewState._muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.brandGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsValueTile extends StatelessWidget {
  const _SettingsValueTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFF56657A), size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _SettingsViewState._text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
            ),
            if (showChevron) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFF9AA7B8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({this.indent = 59});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: indent,
      endIndent: 12,
      color: _SettingsViewState._border,
    );
  }
}
