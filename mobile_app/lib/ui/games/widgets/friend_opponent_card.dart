import 'package:flutter/material.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/player_avatar.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';

enum FriendLookupStatus {
  idle,
  tooShort,
  checking,
  found,
  notFound,
  self,
  error,
}

class FriendOpponentCard extends StatelessWidget {
  const FriendOpponentCard({
    required this.selected,
    required this.controller,
    required this.lookupStatus,
    required this.foundUsername,
    required this.message,
    required this.onTap,
    required this.onUsernameChanged,
    super.key,
  });

  final bool selected;
  final TextEditingController controller;
  final FriendLookupStatus lookupStatus;
  final String? foundUsername;
  final String? message;
  final VoidCallback onTap;
  final ValueChanged<String> onUsernameChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brandGreen : const Color(0xFFE1E7E3),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FriendCardHeader(selected: selected),
            if (selected) ...[
              const SizedBox(height: 13),
              const Divider(height: 1, color: Color(0xFFE5EAE7)),
              const SizedBox(height: 13),
              const Text(
                'Arkadaşının kullanıcı adı',
                style: TextStyle(
                  color: Color(0xFF5E6D64),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              _FriendSearchField(
                controller: controller,
                onChanged: onUsernameChanged,
              ),
              const SizedBox(height: 8),
              _LookupResult(
                status: lookupStatus,
                username: foundUsername,
                message: message,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendCardHeader extends StatelessWidget {
  const _FriendCardHeader({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4EA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.group_rounded,
            color: AppColors.brandGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arkadaşınla Oyna',
                style: TextStyle(
                  color: Color(0xFF17251C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Arkadaşını ara ve oyuna davet et.',
                style: TextStyle(color: Color(0xFF7A857F), fontSize: 11.5),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandGreen : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.brandGreen : const Color(0xFFCDD5D0),
              width: 1.3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : null,
        ),
      ],
    );
  }
}

class _FriendSearchField extends StatelessWidget {
  const _FriendSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(
        color: Color(0xFF27342C),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Kullanıcı adı ara',
        hintStyle: const TextStyle(
          color: Color(0xFF9AA49E),
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF8A958E),
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F5F4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1E6E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.4),
        ),
      ),
    );
  }
}

class _LookupResult extends StatelessWidget {
  const _LookupResult({
    required this.status,
    required this.username,
    required this.message,
  });

  final FriendLookupStatus status;
  final String? username;
  final String? message;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case FriendLookupStatus.idle:
        return const SizedBox.shrink();

      case FriendLookupStatus.checking:
        return const _StatusRow(
          icon: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandGreen,
            ),
          ),
          text: 'Kullanıcı kontrol ediliyor...',
          backgroundColor: Color(0xFFF3F6F4),
          textColor: Color(0xFF68756D),
        );

      case FriendLookupStatus.found:
        if (username == null) {
          return const SizedBox.shrink();
        }

        return _SelectedFriendRow(username: username!);

      case FriendLookupStatus.tooShort:
        return _StatusRow(
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFF8A958E),
          ),
          text: message ?? 'En az 3 karakter yaz.',
          backgroundColor: const Color(0xFFF3F6F4),
          textColor: const Color(0xFF68756D),
        );

      case FriendLookupStatus.notFound:
        return _StatusRow(
          icon: const Icon(
            Icons.person_off_outlined,
            size: 17,
            color: Color(0xFFC54B45),
          ),
          text: message ?? 'Bu kullanıcı bulunamadı.',
          backgroundColor: const Color(0xFFFFEEEC),
          textColor: const Color(0xFFA53C37),
        );

      case FriendLookupStatus.self:
        return _StatusRow(
          icon: const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFF9A6D00),
          ),
          text: message ?? 'Kendini seçemezsin.',
          backgroundColor: const Color(0xFFFFF5D8),
          textColor: const Color(0xFF7A5900),
        );

      case FriendLookupStatus.error:
        return _StatusRow(
          icon: const Icon(
            Icons.wifi_off_rounded,
            size: 17,
            color: Color(0xFFC54B45),
          ),
          text: message ?? 'Kullanıcı kontrol edilemedi.',
          backgroundColor: const Color(0xFFFFEEEC),
          textColor: const Color(0xFFA53C37),
        );
    }
  }
}

class _SelectedFriendRow extends StatelessWidget {
  const _SelectedFriendRow({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCECE1)),
      ),
      child: Row(
        children: [
          PlayerAvatar(
            username: username,
            radius: 17,
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
            borderWidth: 0,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF26352C),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A958E),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F3E7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: AppColors.brandGreen,
                  size: 13,
                ),
                SizedBox(width: 3),
                Text(
                  'Seçildi',
                  style: TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final Widget icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
