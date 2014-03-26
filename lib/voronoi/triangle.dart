part of voronoi;

class Triangle {
  List<Site> _sites;
  List<Site> get sites => _sites;

  Triangle(Site a, Site b, Site c) {
    _sites = [ a, b, c ];
  }
}