// Hand-built real constellations — v2.
//
// SUPERSEDED as a live feature by the in-app hand-drawn constellation
// editor (see `constellation_editor_screen.dart`/`CustomConstellationRepository`)
// — every project now gets its own drawn-by-the-user shape instead of one
// of these 20 assigned automatically by icon. `constellationShapes` below
// is kept only as one-time migration/seed data: `legacy_constellation_migration.dart`
// reads it to backfill a real `CustomConstellation` for any project that
// predates the editor (or was created by the debug seed tool), so it's
// still real, load-bearing data — just no longer read by
// `ConstellationScreen` or exposed as a user-facing choice. Don't delete it
// without migrating anything that still depends on it.
//
// Not icon silhouettes: each shape below is one of a small set of
// well-known real constellations (Orion, Cassiopeia, the Dippers, ...),
// built from scratch as a graph of keypoints (`points`) and the line
// segments connecting them (`edges`, index pairs into `points`) — real
// constellations branch (a figure's arms and legs, a teapot's handle),
// so this isn't restricted to a single path or closed loop the way the
// old icon-outline shapes were.
//
// Overflow stars beyond `points.length` are NOT stored here:
// `buildConstellationLayout` (constellation_layout.dart) grows the graph
// by repeatedly bisecting its current longest edge, so the pattern
// thickens evenly instead of piling stars along one branch.
import 'dart:ui';

class ConstellationShape {
  final List<Offset> points;
  final List<(int, int)> edges;
  const ConstellationShape({required this.points, required this.edges});
}

const _orion = ConstellationShape(
  points: [Offset(0.30, 0.05), Offset(0.70, 0.08), Offset(0.38, 0.45), Offset(0.50, 0.48), Offset(0.62, 0.51), Offset(0.28, 0.95), Offset(0.68, 0.92), Offset(0.50, 0.65)],
  edges: [(0, 1), (0, 2), (1, 4), (2, 3), (3, 4), (2, 5), (4, 6), (3, 7)],
);

const _ursaMajor = ConstellationShape(
  points: [Offset(0.10, 0.55), Offset(0.28, 0.45), Offset(0.45, 0.40), Offset(0.62, 0.42), Offset(0.62, 0.62), Offset(0.85, 0.65), Offset(0.82, 0.40)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)],
);

const _ursaMinor = ConstellationShape(
  points: [Offset(0.15, 0.15), Offset(0.30, 0.28), Offset(0.45, 0.38), Offset(0.60, 0.42), Offset(0.75, 0.35), Offset(0.80, 0.55), Offset(0.62, 0.60)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 3)],
);

const _cassiopeia = ConstellationShape(
  points: [Offset(0.05, 0.60), Offset(0.28, 0.20), Offset(0.50, 0.65), Offset(0.72, 0.15), Offset(0.95, 0.55)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4)],
);

const _cygnus = ConstellationShape(
  points: [Offset(0.50, 0.05), Offset(0.50, 0.95), Offset(0.50, 0.50), Offset(0.15, 0.35), Offset(0.85, 0.65)],
  edges: [(0, 2), (2, 1), (2, 3), (2, 4)],
);

const _lyra = ConstellationShape(
  points: [Offset(0.50, 0.05), Offset(0.35, 0.35), Offset(0.30, 0.70), Offset(0.55, 0.85), Offset(0.65, 0.55)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 1)],
);

const _leo = ConstellationShape(
  points: [Offset(0.15, 0.30), Offset(0.20, 0.15), Offset(0.32, 0.08), Offset(0.40, 0.18), Offset(0.30, 0.35), Offset(0.60, 0.45), Offset(0.85, 0.35), Offset(0.68, 0.62)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (5, 7)],
);

const _draco = ConstellationShape(
  points: [Offset(0.05, 0.85), Offset(0.15, 0.65), Offset(0.28, 0.75), Offset(0.40, 0.55), Offset(0.35, 0.35), Offset(0.50, 0.25), Offset(0.65, 0.35), Offset(0.80, 0.20), Offset(0.90, 0.10), Offset(0.78, 0.08)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 7)],
);

const _sagittarius = ConstellationShape(
  points: [Offset(0.20, 0.30), Offset(0.35, 0.35), Offset(0.60, 0.25), Offset(0.75, 0.35), Offset(0.85, 0.55), Offset(0.75, 0.70), Offset(0.55, 0.75), Offset(0.35, 0.65)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)],
);

const _gemini = ConstellationShape(
  points: [Offset(0.20, 0.10), Offset(0.20, 0.40), Offset(0.15, 0.75), Offset(0.55, 0.08), Offset(0.55, 0.38), Offset(0.50, 0.72), Offset(0.35, 0.90)],
  edges: [(0, 1), (1, 2), (3, 4), (4, 5), (2, 6), (5, 6)],
);

const _taurus = ConstellationShape(
  points: [Offset(0.50, 0.55), Offset(0.30, 0.35), Offset(0.65, 0.35), Offset(0.15, 0.15), Offset(0.85, 0.12)],
  edges: [(0, 1), (0, 2), (1, 3), (2, 4)],
);

const _pegasus = ConstellationShape(
  points: [Offset(0.55, 0.20), Offset(0.85, 0.25), Offset(0.80, 0.55), Offset(0.50, 0.50), Offset(0.35, 0.10), Offset(0.15, 0.05)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (4, 5)],
);

const _andromeda = ConstellationShape(
  points: [Offset(0.10, 0.20), Offset(0.30, 0.35), Offset(0.50, 0.30), Offset(0.68, 0.45), Offset(0.85, 0.40), Offset(0.95, 0.60)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)],
);

const _perseus = ConstellationShape(
  points: [Offset(0.15, 0.15), Offset(0.30, 0.30), Offset(0.45, 0.45), Offset(0.35, 0.65), Offset(0.60, 0.60), Offset(0.75, 0.75)],
  edges: [(0, 1), (1, 2), (2, 3), (2, 4), (4, 5)],
);

const _aquila = ConstellationShape(
  points: [Offset(0.50, 0.15), Offset(0.50, 0.45), Offset(0.50, 0.75), Offset(0.20, 0.50), Offset(0.80, 0.50)],
  edges: [(0, 1), (1, 2), (1, 3), (1, 4)],
);

const _bootes = ConstellationShape(
  points: [Offset(0.50, 0.10), Offset(0.30, 0.35), Offset(0.70, 0.35), Offset(0.50, 0.55), Offset(0.40, 0.85), Offset(0.60, 0.85)],
  edges: [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4), (3, 5)],
);

const _coronaBorealis = ConstellationShape(
  points: [Offset(0.10, 0.55), Offset(0.25, 0.35), Offset(0.42, 0.22), Offset(0.58, 0.18), Offset(0.74, 0.24), Offset(0.88, 0.40), Offset(0.92, 0.60)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)],
);

const _auriga = ConstellationShape(
  points: [Offset(0.50, 0.10), Offset(0.78, 0.35), Offset(0.68, 0.75), Offset(0.32, 0.75), Offset(0.22, 0.35)],
  edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)],
);

const _canisMajor = ConstellationShape(
  points: [Offset(0.50, 0.15), Offset(0.30, 0.35), Offset(0.65, 0.40), Offset(0.20, 0.70), Offset(0.75, 0.75), Offset(0.50, 0.55)],
  edges: [(0, 1), (1, 3), (0, 2), (2, 4), (1, 5), (5, 2)],
);

const _scorpius = ConstellationShape(
  points: [Offset(0.10, 0.20), Offset(0.22, 0.15), Offset(0.30, 0.30), Offset(0.42, 0.35), Offset(0.55, 0.45), Offset(0.65, 0.55), Offset(0.72, 0.68), Offset(0.68, 0.82), Offset(0.55, 0.90), Offset(0.42, 0.85)],
  edges: [(0, 2), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9)],
);

/// Every icon slug a legacy project could carry, mapped to one of the 20
/// constellations above (round-robin — the assignment carried no meaning
/// beyond giving each icon a fixed, deterministic shape). Migration-only
/// now — see the file-level comment above. The live, user-facing set of
/// icon-badge slugs is `availableIconSlugs` in `icon_for_slug.dart`, not
/// this map's keys.
const Map<String, ConstellationShape> constellationShapes = {
  'account_balance': _orion,
  'account_balance_wallet': _ursaMajor,
  'air': _ursaMinor,
  'all_inclusive': _cassiopeia,
  'badge': _cygnus,
  'bolt': _lyra,
  'brightness_4': _leo,
  'brightness_5': _draco,
  'business_center': _sagittarius,
  'campaign': _gemini,
  'checklist': _taurus,
  'church': _pegasus,
  'connect_without_contact': _andromeda,
  'corporate_fare': _perseus,
  'credit_score': _aquila,
  'diversity_3': _bootes,
  'eco': _coronaBorealis,
  'emoji_objects': _auriga,
  'engineering': _canisMajor,
  'explore': _scorpius,
  'family_restroom': _orion,
  'favorite': _ursaMajor,
  'fitness_center': _ursaMinor,
  'flag': _cassiopeia,
  'forum': _cygnus,
  'group_add': _lyra,
  'groups': _leo,
  'groups_2': _draco,
  'healing': _sagittarius,
  'laptop_mac': _gemini,
  'local_florist': _taurus,
  'military_tech': _pegasus,
  'monitor_heart': _andromeda,
  'mood': _perseus,
  'mosque': _aquila,
  'nightlight': _bootes,
  'paid': _coronaBorealis,
  'park': _auriga,
  'payments': _canisMajor,
  'pie_chart': _scorpius,
  'pool': _orion,
  'psychology': _ursaMajor,
  'psychology_alt': _ursaMinor,
  'real_estate_agent': _cassiopeia,
  'recycling': _cygnus,
  'redeem': _lyra,
  'request_quote': _leo,
  'rocket_launch': _draco,
  'savings': _sagittarius,
  'school': _gemini,
  'spa': _taurus,
  'sports_gymnastics': _pegasus,
  'star': _andromeda,
  'synagogue': _perseus,
  'temple_buddhist': _aquila,
  'trending_up': _bootes,
  'volunteer_activism': _coronaBorealis,
  'work': _auriga,
  'work_history': _canisMajor,
};

/// Still fully live (unlike [constellationShapes] above) — per-area icon
/// suggestions for `NewProjectScreen`'s badge picker, unrelated to
/// constellation shapes.
const Map<String, List<String>> suggestedIconsByArea = {
  'physical': ['bolt', 'favorite', 'fitness_center', 'monitor_heart', 'pool', 'sports_gymnastics'],
  'psychological': ['air', 'brightness_5', 'healing', 'mood', 'nightlight', 'psychology', 'psychology_alt', 'spa'],
  'professional': ['badge', 'business_center', 'corporate_fare', 'engineering', 'laptop_mac', 'rocket_launch', 'school', 'trending_up', 'work', 'work_history'],
  'financial': ['account_balance', 'account_balance_wallet', 'credit_score', 'paid', 'payments', 'pie_chart', 'real_estate_agent', 'request_quote', 'savings'],
  'personal': ['checklist', 'emoji_objects', 'explore', 'flag', 'local_florist', 'military_tech', 'rocket_launch', 'star'],
  'social': ['connect_without_contact', 'diversity_3', 'family_restroom', 'favorite', 'forum', 'group_add', 'groups', 'groups_2'],
  'spiritual': ['all_inclusive', 'brightness_4', 'church', 'mosque', 'nightlight', 'spa', 'synagogue', 'temple_buddhist'],
  'philanthropical': ['campaign', 'diversity_3', 'eco', 'favorite', 'groups', 'park', 'recycling', 'redeem', 'volunteer_activism'],
};
