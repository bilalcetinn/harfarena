import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kelime_analiz_mobile/core/theme/app_colors.dart';
import 'package:kelime_analiz_mobile/domain/gameplay/constants/game_time_control.dart';
import 'package:kelime_analiz_mobile/ui/common_widgets/main_section_header.dart';

import 'widgets/arena_background.dart';
import 'widgets/duration_section.dart';
import 'widgets/friend_opponent_card.dart';
import 'widgets/new_game_continue_button.dart';
import 'widgets/new_game_intro.dart';
import 'widgets/opponent_card.dart';

enum GameOpponentType { friend, random }

class NewGameView extends StatefulWidget {
  const NewGameView({
    required this.currentUsername,
    required this.onFindFriend,
    required this.onCreateFriendGame,
    required this.onRandomContinue,
    this.initialTurnDurationSeconds = 120,
    super.key,
  });

  final String currentUsername;

  final Future<String?> Function(String username) onFindFriend;

  final Future<void> Function(String username, int turnDurationSeconds)
  onCreateFriendGame;

  final VoidCallback onRandomContinue;
  final int initialTurnDurationSeconds;

  @override
  State<NewGameView> createState() => _NewGameViewState();
}

class _NewGameViewState extends State<NewGameView> {
  final TextEditingController _friendController = TextEditingController();

  GameOpponentType _selectedType = GameOpponentType.friend;

  late int _selectedDuration;

  Timer? _searchDebounce;
  int _searchRequestId = 0;

  FriendLookupStatus _lookupStatus = FriendLookupStatus.idle;

  String? _foundUsername;
  String? _lookupMessage;

  bool _creatingGame = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration =
        kTurnDurationOptions.contains(widget.initialTurnDurationSeconds)
        ? widget.initialTurnDurationSeconds
        : 120;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _friendController.dispose();
    super.dispose();
  }

  void _selectFriend() {
    setState(() {
      _selectedType = GameOpponentType.friend;
    });
  }

  void _selectRandom() {
    _searchDebounce?.cancel();

    setState(() {
      _selectedType = GameOpponentType.random;
    });
  }

  void _onUsernameChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    final requestId = ++_searchRequestId;

    setState(() {
      _selectedType = GameOpponentType.friend;
      _foundUsername = null;
      _lookupMessage = null;
    });

    if (query.isEmpty) {
      setState(() {
        _lookupStatus = FriendLookupStatus.idle;
      });

      return;
    }

    if (query.length < 3) {
      setState(() {
        _lookupStatus = FriendLookupStatus.tooShort;
        _lookupMessage = 'En az 3 karakter yaz.';
      });

      return;
    }

    if (query.toLowerCase() == widget.currentUsername.toLowerCase()) {
      setState(() {
        _lookupStatus = FriendLookupStatus.self;
        _lookupMessage = 'Kendine oyun daveti gönderemezsin.';
      });

      return;
    }

    setState(() {
      _lookupStatus = FriendLookupStatus.checking;
      _lookupMessage = 'Kullanıcı kontrol ediliyor...';
    });

    _searchDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final username = await widget.onFindFriend(query);

        if (!mounted || requestId != _searchRequestId) {
          return;
        }

        setState(() {
          if (username == null) {
            _lookupStatus = FriendLookupStatus.notFound;

            _lookupMessage = 'Bu kullanıcı bulunamadı.';

            _foundUsername = null;
          } else {
            _lookupStatus = FriendLookupStatus.found;

            _lookupMessage = null;

            _foundUsername = username;
          }
        });
      } catch (_) {
        if (!mounted || requestId != _searchRequestId) {
          return;
        }

        setState(() {
          _lookupStatus = FriendLookupStatus.error;

          _lookupMessage =
              'Kullanıcı kontrol edilemedi. '
              'Bağlantını kontrol et.';

          _foundUsername = null;
        });
      }
    });
  }

  void _onDurationSelected(int seconds) {
    setState(() {
      _selectedDuration = seconds;
    });
  }

  Future<void> _continue() async {
    if (_creatingGame) {
      return;
    }

    if (_selectedType == GameOpponentType.random) {
      widget.onRandomContinue();
      return;
    }

    final username = _foundUsername;

    if (_lookupStatus != FriendLookupStatus.found || username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce geçerli bir arkadaş seç.')),
      );

      return;
    }

    setState(() {
      _creatingGame = true;
    });

    try {
      await widget.onCreateFriendGame(username, _selectedDuration);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('$username kullanıcısına oyun daveti gönderildi.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = '$error'
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Bad state: ', '');

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _creatingGame = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFriendSelected = _selectedType == GameOpponentType.friend;

    final canCreateFriendGame =
        isFriendSelected &&
        _lookupStatus == FriendLookupStatus.found &&
        _foundUsername != null &&
        !_creatingGame;

    final buttonEnabled = isFriendSelected
        ? canCreateFriendGame
        : !_creatingGame;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.brandGreenDark,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF7F8F6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7F4),

        // Klavye açılınca da layout düzgün kalsın.
        resizeToAvoidBottomInset: true,

        body: Stack(
          children: [
            const Positioned.fill(child: ArenaBackground()),

            Column(
              children: [
                MainSectionHeader(
                  title: 'Yeni Oyun',
                  subtitle: 'Arkadaşına meydan oku veya rastgele bir rakiple arenaya çık.',
                  icon: Icons.sports_esports_rounded,
                  onBack: () => Navigator.of(context).pop(),
                ),

                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const NewGameIntro(),

                          const SizedBox(height: 20),

                          FriendOpponentCard(
                            selected: isFriendSelected,
                            controller: _friendController,
                            lookupStatus: _lookupStatus,
                            foundUsername: _foundUsername,
                            message: _lookupMessage,
                            onTap: _selectFriend,
                            onUsernameChanged: _onUsernameChanged,
                          ),

                          const SizedBox(height: 12),

                          OpponentCard(
                            selected: !isFriendSelected,
                            icon: Icons.casino_rounded,
                            title: 'Rastgele Rakip',
                            subtitle: 'Sana uygun bir rakiple otomatik eşleş.',
                            badge: 'EŞLEŞ',
                            onTap: _selectRandom,
                          ),

                          const SizedBox(height: 24),

                          DurationSection(
                            selectedDuration: _selectedDuration,
                            onSelected: _onDurationSelected,
                          ),

                          // Buton artık burada değil.
                          // Aşağıda sabit duruyor.
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // BUTON HER ZAMAN EKRANIN ALTINDA SABİT
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            color: const Color(0xFFF7F8F6),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: NewGameContinueButton(
              isFriend: isFriendSelected,
              isLoading: _creatingGame,
              enabled: buttonEnabled,
              onPressed: _continue,
            ),
          ),
        ),
      ),
    );
  }
}
