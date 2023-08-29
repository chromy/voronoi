part of voronoi;

List<LineSegment> delaunayLinesForEdges(List<Edge> edges) {
  final List<LineSegment> segments = <LineSegment>[];
  for (final Edge edge in edges) {
    segments.add(edge.delaunayLine());
  }
  return segments;
}
