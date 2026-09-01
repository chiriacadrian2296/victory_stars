import 'package:flutter/widgets.dart';

/// Below this width the app renders exactly as it always has (phone chrome,
/// edge-to-edge content). At or above it, [RootScreen] switches to a side
/// nav rail and screen content centers in a capped-width column via
/// `ResponsiveContent` — see both for why. Matches Material 3's "expanded"
/// window-size-class threshold, so a resized browser window or a tablet
/// held in portrait stays on the phone-tuned layout rather than flip-
/// flopping between chrome styles.
const double kWideLayoutBreakpoint = 840;

/// Reacts to actual available width, not platform — the same check applies
/// whether this is Chrome resized narrow, the native Windows build snapped
/// to half-screen, or a phone.
bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
