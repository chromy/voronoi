part of voronoi;

class Triangle {
  late List<Site<num>> _sites;
  List<Site<num>> get sites => _sites;

  Triangle(Site<num> a, Site<num> b, Site<num> c) {
    _sites = <Site<num>>[a, b, c];
  }
}
