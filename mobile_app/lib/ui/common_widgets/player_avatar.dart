import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:kelime_analiz_mobile/domain/profile/utils/username_utils.dart';

/// Kullanıcı adından gerçek oyuncu profilini çözüp profil fotoğrafını gösterir.
///
/// Fotoğraf yoksa eski davranış gibi kullanıcı adının ilk harfine düşer.
/// HarfArena profil fotoğrafları Firestore'da data URL olarak tutulduğu için
/// hem data:image/...;base64 hem de normal http(s) URL desteklenir.
class PlayerAvatar extends StatefulWidget {
  const PlayerAvatar({
    required this.username,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFE8F0FF),
    this.foregroundColor = const Color(0xFF23352B),
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.boxShadow = const [],
    super.key,
  });

  final String username;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> boxShadow;

  @override
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar> {
  late Future<String?> _avatarFuture;

  @override
  void initState() {
    super.initState();
    _avatarFuture = _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant PlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username.toLowerCase() != widget.username.toLowerCase()) {
      _avatarFuture = _loadAvatar();
    }
  }

  Future<String?> _loadAvatar() async {
    final username = normalizeUsername(widget.username);
    if (username.isEmpty) return null;

    try {
      final firestore = FirebaseFirestore.instance;
      final usernameDoc = await firestore
          .collection('usernames')
          .doc(profileDocumentCode(username))
          .get();

      final playerId = usernameDoc.data()?['playerId'] as String?;
      if (playerId == null || playerId.isEmpty) return null;

      final player = await firestore.collection('players').doc(playerId).get();
      final source = (player.data()?['avatarUrl'] as String?)?.trim();
      return source == null || source.isEmpty ? null : source;
    } catch (_) {
      // Avatar yüklenememesi profil gösterimini bozmamalı.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;

    return FutureBuilder<String?>(
      future: _avatarFuture,
      builder: (context, snapshot) {
        final source = snapshot.data;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
            boxShadow: widget.boxShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: _AvatarContent(
            source: source,
            username: widget.username,
            foregroundColor: widget.foregroundColor,
            fontSize: widget.radius * 0.72,
          ),
        );
      },
    );
  }
}

class _AvatarContent extends StatefulWidget {
  const _AvatarContent({
    required this.source,
    required this.username,
    required this.foregroundColor,
    required this.fontSize,
  });

  final String? source;
  final String username;
  final Color foregroundColor;
  final double fontSize;

  @override
  State<_AvatarContent> createState() => _AvatarContentState();
}

class _AvatarContentState extends State<_AvatarContent> {
  Uint8List? _memoryBytes;

  @override
  void initState() {
    super.initState();
    _decodeMemoryImage();
  }

  @override
  void didUpdateWidget(covariant _AvatarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _decodeMemoryImage();
    }
  }

  void _decodeMemoryImage() {
    _memoryBytes = null;
    final value = widget.source?.trim();
    if (value == null || !value.startsWith('data:image/')) return;

    try {
      final comma = value.indexOf(',');
      if (comma > 0) {
        _memoryBytes = base64Decode(value.substring(comma + 1));
      }
    } catch (_) {
      _memoryBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.source?.trim();

    if (value != null && value.isNotEmpty) {
      if (value.startsWith('data:image/')) {
        final bytes = _memoryBytes;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
      } else if (value.startsWith('http://') || value.startsWith('https://')) {
        return Image.network(
          value,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
    }

    return _fallback();
  }

  Widget _fallback() {
    final firstLetter = widget.username.trim().isEmpty
        ? '?'
        : widget.username.trim().substring(0, 1).toUpperCase();

    return Center(
      child: Text(
        firstLetter,
        style: TextStyle(
          color: widget.foregroundColor,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
