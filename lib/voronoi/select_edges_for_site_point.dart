part of voronoi;

Iterable<Edge> selectEdgesForSitePoint(Point coord, List<Edge> edgesToTest) {
  bool myTest(Edge edge) {
    return edge.leftSite.coord == coord || edge.rightSite.coord == coord;
  }

  return edgesToTest.where(myTest);
}
