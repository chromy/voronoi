part of voronoi;

class SiteList<T extends num> extends ListBase<Site<T>> {
  final List<Site<T>> _sites = <Site<T>>[];
  int _currentIndex = 0;

  bool _sorted = false;

  SiteList();

  @override
  void add(Site<T> element) {
    _sorted = false;
    _sites.add(element);
  }

  @override
  int get length => _sites.length;

  @override
  set length(int newLength) => _sites.length = newLength;

  @override
  Site<T> operator [](int index) => _sites[index];

  @override
  void operator []=(int index, Site<T> value) => _sites[index] = value;

  Site<T>? next() {
    if (!_sorted) {
      throw StateError("Cannot call next() on an unsorted SiteList.");
    }
    if (_currentIndex < length) {
      return this[_currentIndex++];
    } else {
      return null;
    }
  }

  math.Rectangle<num> getSitesBounds() {
    if (isEmpty) {
      return const math.Rectangle<int>(0, 0, 0, 0);
    }

    if (!_sorted) {
      sort();
      _currentIndex = 0;
      _sorted = true;
    }

    final num xMin = reduce((Site<T> minSite, Site<T> site) => site.x < minSite.x ? site : minSite).x;
    final num xMax = reduce((Site<T> maxSite, Site<T> site) => site.x > maxSite.x ? site : maxSite).x;

    // here's where we assume that the sites have been sorted on y:
    final num yMin = this[0].y;
    final num yMax = this[length - 1].y;

    return math.Rectangle<num>(xMin, yMin, xMax - xMin, yMax - yMin);
  }

  /// @return the largest circle centered at each site that fits in its region;
  /// if the region is infinite, return no circle for that region.
  Iterable<Circle> circles() => map((Site<T> site) {
        final Edge nearestEdge = site.nearestEdge();
        if (!nearestEdge.isPartOfConvexHull()) {
          final num radius = nearestEdge.sitesDistance() * 0.5;
          return Circle(site, radius);
        }
      }).whereType<Circle>();

  Iterable<List<Point<num>>> regions(math.Rectangle<num> plotBounds) => map((Site<T> site) => site.region(plotBounds));
}
