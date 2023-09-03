part of voronoi;

class SiteList<T extends num> extends ListBase<Site<T>> {
  final List<Site<T>> _sites = <Site<T>>[];
  int _currentIndex = 0;

  SiteList();

  @override
  void add(Site<T> element) {
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
    if (_currentIndex < length) {
      return this[_currentIndex++];
    } else {
      return null;
    }
  }

  ({num min, num max}) getXRange() => (
        min: reduce((Site<T> minSite, Site<T> site) => site.x < minSite.x ? site : minSite).x,
        max: reduce((Site<T> maxSite, Site<T> site) => site.x > maxSite.x ? site : maxSite).x
      );

  /// @return the largest circle centered at each site that fits in its region;
  /// if the region is infinite, return no circle for that region.
  Iterable<Circle> circles() => map((Site<T> site) {
        final Edge nearestEdge = site.nearestEdge();
        if (!nearestEdge.isPartOfConvexHull()) {
          return Circle(site, nearestEdge.sitesDistance() / 2);
        }
      }).whereType<Circle>();

  Iterable<List<Point<num>>> regions(math.Rectangle<num> plotBounds) => map((Site<T> site) => site.region(plotBounds));
}
