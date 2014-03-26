part of voronoi;

class SiteList {
  List<Site> _sites;
  int _currentIndex;
  
  bool _sorted;
  
  SiteList() {
    _sites = [];
    _sorted = false;
  }
  
  void add(Site site) {
    _sorted = false;
    _sites.add(site);
  }
  
  int get length => _sites.length;
  
  Site next() {
    if (!_sorted) {
      //"SiteList::next():  sites have not been sorted"
      throw new Error();
    }
    if (_currentIndex < _sites.length) {
      return _sites[_currentIndex++];
    } else {
      return null;
    }
  }
  
  Rectangle getSitesBounds() {
    if (!_sorted) {
      Site.sortSites(_sites);
      _currentIndex = 0;
      _sorted = true;
    }
    num xmin, xmax, ymin, ymax;
    if (_sites.length == 0) {
      return new Rectangle(0, 0, 0, 0);
    }
    xmin = double.MAX_FINITE;
    xmax = double.NEGATIVE_INFINITY;
    for (Site site in _sites) {
      if (site.x < xmin) {
        xmin = site.x;
      }
      if (site.x > xmax) {
        xmax = site.x;
      }
    }
    // here's where we assume that the sites have been sorted on y:
    ymin = _sites[0].y;
    ymax = _sites[_sites.length - 1].y;
    
    return new Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
  }
  
  List<Point> siteCoords() {
    List<Point> coords = [];
    for (Site site in _sites) {
      coords.add(site.coord);
    }
    return coords;
  }
  
  /**
   * 
   * @return the largest circle centered at each site that fits in its region;
   * if the region is infinite, return a circle of radius 0.
   * 
   */
  List<Circle> circles() {
    List<Circle> circles = [];
    for (Site site in _sites) {
      num radius = 0;
      Edge nearestEdge = site.nearestEdge();
      
      !nearestEdge.isPartOfConvexHull() && (radius = nearestEdge.sitesDistance() * 0.5);
      circles.add(new Circle(site.x, site.y, radius));
    }
    return circles;
  }
  
  List<List<Point>> regions(Rectangle plotBounds) {
    var regions = [];
    for (Site site in _sites) {
      regions.add(site.region(plotBounds));
    }
    return regions;
  }
}