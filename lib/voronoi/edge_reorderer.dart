part of voronoi;

class EdgeReorderer {
  List<Edge> _edges = <Edge>[];
  final List<Direction> _edgeOrientations = <Direction>[];
  List<Edge> get edges => _edges;
  List<Direction> get edgeOrientations => _edgeOrientations;

  EdgeReorderer(List<Edge> origEdges, String criterion) {
    if (criterion != "vertex" && criterion != "site") {
      throw ArgumentError("Edges: criterion must be vertex or site");
    }
    if (origEdges.isNotEmpty) {
      _edges = reorderEdges(origEdges, criterion);
    }
  }

  List<Edge> reorderEdges(List<Edge> origEdges, String criterion) {
    int i;
    final int n = origEdges.length;
    Edge edge;
    // we're going to reorder the edges in order of traversal
    final List<bool> done = List<bool>.filled(n, false);
    int nDone = 0;
    final List<Edge> newEdges = <Edge>[];

    i = 0;
    edge = origEdges[i];
    newEdges.add(edge);
    _edgeOrientations.add(Direction.left);

    Object? firstPoint = (criterion == "vertex") ? edge.leftVertex : edge.leftSite;
    Object? lastPoint = (criterion == "vertex") ? edge.rightVertex : edge.rightSite;

    if (firstPoint == Vertex.vertexAtInfinity ||
        lastPoint == Vertex.vertexAtInfinity) {
      return <Edge>[];
    }

    done[i] = true;
    ++nDone;

    while (nDone < n) {
      for (i = 1; i < n; ++i) {
        if (done[i]) {
          continue;
        }
        edge = origEdges[i];
        final Object? leftPoint =
            (criterion == "vertex") ? edge.leftVertex : edge.leftSite;
        final Object? rightPoint =
            (criterion == "vertex") ? edge.rightVertex : edge.rightSite;
        if (leftPoint == Vertex.vertexAtInfinity ||
            rightPoint == Vertex.vertexAtInfinity) {
          return <Edge>[];
        }
        if (leftPoint == lastPoint) {
          lastPoint = rightPoint;
          _edgeOrientations.add(Direction.left);
          newEdges.add(edge);
          done[i] = true;
        } else if (rightPoint == firstPoint) {
          firstPoint = leftPoint;
          _edgeOrientations.insert(0, Direction.left);
          newEdges.insert(0, edge);
          done[i] = true;
        } else if (leftPoint == firstPoint) {
          firstPoint = rightPoint;
          _edgeOrientations.insert(0, Direction.right);
          newEdges.insert(0, edge);
          done[i] = true;
        } else if (rightPoint == lastPoint) {
          lastPoint = leftPoint;
          _edgeOrientations.add(Direction.right);
          newEdges.add(edge);
          done[i] = true;
        }
        if (done[i]) {
          ++nDone;
        }
      }
    }

    return newEdges;
  }
}
