part of voronoi;

List<LineSegment> visibleLineSegments(List<Edge> edges) {
  List<LineSegment> segments = [];

  for (Edge edge in edges) {
    if (edge.visible) {
      Point p1 = edge.clippedEnds[LR.LEFT];
      Point p2 = edge.clippedEnds[LR.RIGHT];
      segments.add(LineSegment(p1, p2));
    }
  }

  return segments;
}
