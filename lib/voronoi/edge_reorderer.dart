part of voronoi;

class EdgeReorderer<T extends Point<num>> {
  List<Edge> _edges = <Edge>[];
  final List<Direction> _edgeOrientations = <Direction>[];

  List<Edge> get edges => _edges;

  List<Direction> get edgeOrientations => _edgeOrientations;

  EdgeReorderer(List<Edge> origEdges) {
    if (origEdges.isNotEmpty) {
      _edges = reorderEdges(origEdges);
    }
  }

  List<Edge> reorderEdges(List<Edge> origEdges) {
    int i = 0;
    int nDone = 0;
    final int n = origEdges.length;
    // we're going to reorder the edges in order of traversal
    final List<bool> done = List<bool>.filled(n, false);
    final List<Edge> newEdges = <Edge>[];

    Edge edge = origEdges[i];
    newEdges.add(edge);
    _edgeOrientations.add(Direction.left);

    Object? firstPoint, lastPoint, rightPoint, leftPoint;

    switch (T) {
      case const (Site<num>):
        firstPoint = edge.sites.left;
        lastPoint = edge.sites.right;
        break;
      case const (Vertex<num>):
        firstPoint = edge.vertices.left;
        lastPoint = edge.vertices.right;
        if (firstPoint == Vertex.vertexAtInfinity || lastPoint == Vertex.vertexAtInfinity) {
          return <Edge>[];
        }
        break;
    }

    done[i] = true;
    ++nDone;

    while (nDone < n) {
      for (i = 1; i < n; ++i) {
        if (done[i]) {
          continue;
        }
        edge = origEdges[i];
        switch (T) {
          case const (Site<num>):
            leftPoint = edge.sites.left;
            rightPoint = edge.sites.right;
            break;
          case const (Vertex<num>):
            leftPoint = edge.vertices.left;
            rightPoint = edge.vertices.right;
            if (leftPoint == Vertex.vertexAtInfinity || rightPoint == Vertex.vertexAtInfinity) {
              return <Edge>[];
            }
            break;
        }
        if (leftPoint == lastPoint) {
          lastPoint = rightPoint;
          _edgeOrientations.add(Direction.left);
          newEdges.add(edge);
        } else if (rightPoint == firstPoint) {
          firstPoint = leftPoint;
          _edgeOrientations.insert(0, Direction.left);
          newEdges.insert(0, edge);
        } else if (leftPoint == firstPoint) {
          firstPoint = rightPoint;
          _edgeOrientations.insert(0, Direction.right);
          newEdges.insert(0, edge);
        } else if (rightPoint == lastPoint) {
          lastPoint = leftPoint;
          _edgeOrientations.add(Direction.right);
          newEdges.add(edge);
        } else {
          continue;
        }
        ++nDone;
      }
    }

    return newEdges;
  }
}
