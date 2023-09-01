part of voronoi;

class EdgeReorderer {
  late final Iterable<Edge> orderedEdges;
  final OrientedPair<Point<num>> Function(Edge edge) extractor;

  EdgeReorderer(Iterable<Edge> edges, this.extractor) {
    orderedEdges = reorderEdges(edges);
  }

  Iterable<Edge> reorderEdges(Iterable<Edge> edges) {
    if (edges.isEmpty) {
      return const Iterable<Edge>.empty();
    }

    final Edge firstEdge = edges.first..direction = Direction.left;
    final ListQueue<Edge> newEdges = ListQueue<Edge>.of(<Edge>[firstEdge]);

    Point<num> firstPoint = firstEdge.sites.left;
    Point<num> lastPoint = firstEdge.sites.right;
    for (final Edge edge in edges) {
      final OrientedPair<Point<num>> points = extractor(edge);
      if (points.left == lastPoint) {
        lastPoint = points.right;
        edge.direction = Direction.left;
        newEdges.addLast(edge);
      } else if (points.right == firstPoint) {
        firstPoint = points.left;
        edge.direction = Direction.left;
        newEdges.addFirst(edge);
      } else if (points.left == firstPoint) {
        firstPoint = points.right;
        edge.direction = Direction.right;
        newEdges.addFirst(edge);
      } else if (points.right == lastPoint) {
        lastPoint = points.left;
        edge.direction = Direction.right;
        newEdges.addLast(edge);
      } else {
        continue;
      }
    }

    return newEdges;
  }
}
