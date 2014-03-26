part of voronoi;

List<Edge> selectEdgesForSitePoint(Point coord, List<Edge> edgesToTest) {
  bool myTest(Edge edge) {
    return ((edge.leftSite && edge.leftSite.coord == coord)
        ||  (edge.rightSite && edge.rightSite.coord == coord));
  }
  return edgesToTest.where(myTest);
}