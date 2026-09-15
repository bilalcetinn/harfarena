import 'package:kelime_analiz_mobile/domain/gameplay/models/online_room.dart';

abstract interface class GameInviteActionsRepository {
  Future<void> cancelOrRejectInvite(OnlineRoom room);
}
