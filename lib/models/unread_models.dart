// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:meshcore_team/database/database.dart';

/// Contact with unread message count
class ContactWithUnread {
  final ContactData contact;
  final int unreadCount;

  ContactWithUnread({
    required this.contact,
    required this.unreadCount,
  });
}

/// Channel with unread message count
class ChannelWithUnread {
  final ChannelData channel;
  final int unreadCount;

  ChannelWithUnread({
    required this.channel,
    required this.unreadCount,
  });
}
