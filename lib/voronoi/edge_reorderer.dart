part of voronoi;

class EdgeReorderer<T extends Point<num>> {
  late final Iterable<Edge> edges;

  EdgeReorderer(Iterable<Edge> edges) {
    edges = reorderEdges(edges);
  }

  Iterable<Edge> reorderEdges(Iterable<Edge> edges) {
    if (edges.isEmpty) {
      return const Iterable<Edge>.empty();
    }

    final Edge firstEdge = edges.first..direction = Direction.left;
    final ListQueue<Edge> newEdges = ListQueue<Edge>.of(<Edge>[firstEdge]);

    T firstPoint, lastPoint;

    switch (T) {
      case const (Site<num>):
        firstPoint = firstEdge.sites.left as T;
        lastPoint = firstEdge.sites.right as T;
        break;
      case const (Vertex<num>):
        firstPoint = firstEdge.vertices.left as T;
        lastPoint = firstEdge.vertices.right as T;
        if (firstPoint == Vertex.vertexAtInfinity || lastPoint == Vertex.vertexAtInfinity) {
          return <Edge>[];
        }
        break;
      default:
        throw TypeError();
    }
    for (final Edge edge in edges) {
      OrientedPair<T> points;
      switch (T) {
        case const (Site<num>):
          points = edge.sites as OrientedPair<T>;
          break;
        case const (Vertex<num>):
          points = edge.vertices as OrientedPair<T>;
          if (points.left == Vertex.vertexAtInfinity || points.right == Vertex.vertexAtInfinity) {
            return <Edge>[];
          }
          break;
        default:
          throw TypeError();
      }
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
