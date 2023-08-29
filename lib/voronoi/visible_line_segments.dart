part of voronoi;

List<LineSegment> visibleLineSegments(List<Edge> edges) {
  final List<LineSegment> segments = <LineSegment>[];

  for (final Edge edge in edges) {
    if (edge.visible) {
      final Point<num> p1 = edge.clippedEnds![Direction.left]!;
      final Point<num> p2 = edge.clippedEnds![Direction.right]!;
      segments.add(LineSegment(p1, p2));
    }
  }

  return segments;
}
