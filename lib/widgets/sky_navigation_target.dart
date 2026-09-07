import '../models/life_area.dart';
import '../models/project.dart';

/// What a "take me there" tap inside [SkyExplorerView] resolved to — an
/// area, a whole project/constellation, or a single star/goal/dead
/// star/pulsar within one (which has no sky position of its own beyond its
/// constellation's, so it centers on the same spot a [SkyProjectTarget]
/// for that project would — only the zoom-to-fit level differs, see
/// `NebulaScreen._zoomFor`). Turning this into an actual camera position
/// is left to whoever receives it — `NebulaScreen`, the only place that
/// already builds the placed constellations an area's/project's sky
/// position depends on.
sealed class SkyNavigationTarget {
  const SkyNavigationTarget();
}

class SkyAreaTarget extends SkyNavigationTarget {
  const SkyAreaTarget(this.area);
  final LifeArea area;
}

class SkyProjectTarget extends SkyNavigationTarget {
  const SkyProjectTarget(this.project);
  final Project project;
}

/// A single star/goal/dead star/pulsar inside [project]'s constellation —
/// zooms all the way in (see `NebulaScreen._zoomFor`), unlike
/// [SkyProjectTarget]'s "fit the whole constellation" zoom.
class SkyStarTarget extends SkyNavigationTarget {
  const SkyStarTarget(this.project);
  final Project project;
}
