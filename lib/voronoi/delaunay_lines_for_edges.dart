part of voronoi;

List<LineSegment> delaunayLinesForEdges(List<Edge> edges) {
  List<LineSegment> segments = [];
  for (Edge edge in edges) {
    segments.add(edge.delaunayLine());
  }
  return segments;
}
