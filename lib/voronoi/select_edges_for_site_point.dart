part of voronoi;

Iterable<Edge> selectEdgesForSitePoint(Point<num> coord, List<Edge> edgesToTest) {
  bool myTest(Edge edge) => edge.leftSite.coord == coord || edge.rightSite.coord == coord;

  return edgesToTest.where(myTest);
}
