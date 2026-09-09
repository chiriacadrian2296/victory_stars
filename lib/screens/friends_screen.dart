import 'package:flutter/material.dart';

import '../l10n/strings_scope.dart';
import 'placeholder_screen.dart';

/// The social side of the sky: constellations you share with someone else,
/// messages, celebrating each other's wins. None of it exists yet — this
/// is the menu entry for it, wired to [PlaceholderScreen] until there's a
/// real screen to open.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return PlaceholderScreen(
      icon: Icons.people,
      title: strings.menuFriends,
      body: strings.friendsBody,
    );
  }
}
