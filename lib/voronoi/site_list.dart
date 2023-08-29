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
      //"SiteList::next():  sites have not been sorted"
      throw Error();
    }
    if (_currentIndex < length) {
      return this[_currentIndex++];
    } else {
      return null;
    }
  }

  Rectangle<num> getSitesBounds() {
    if (!_sorted) {
      Site.sortSites(this);
      _currentIndex = 0;
      _sorted = true;
    }
    num xMin, xMax, yMin, yMax;
    if (isEmpty) {
      return const Rectangle<int>(0, 0, 0, 0);
    }
    xMin = double.maxFinite;
    xMax = double.negativeInfinity;
    for (final Site<T> site in this) {
      if (site.x < xMin) {
        xMin = site.x;
      }
      if (site.x > xMax) {
        xMax = site.x;
      }
    }
    // here's where we assume that the sites have been sorted on y:
    yMin = this[0].y;
    yMax = this[length - 1].y;

    return Rectangle<num>(xMin, yMin, xMax - xMin, yMax - yMin);
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

  Iterable<List<Point<num>>> regions(Rectangle<num> plotBounds) => map((Site<T> site) => site.region(plotBounds));
}
