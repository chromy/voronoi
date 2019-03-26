part of voronoi;

class EdgeReorderer {
  List<Edge> _edges;
  List<LR> _edgeOrientations;
  List<Edge> get edges => _edges;
  List<LR> get edgeOrientations => _edgeOrientations;

  EdgeReorderer(List<Edge> origEdges, String criterion) {
    if (criterion != "vertex" && criterion != "site") {
      throw ArgumentError("Edges: criterion must be vertex or site");
    }
    _edges = [];
    _edgeOrientations = [];
    if (origEdges.length > 0) {
      _edges = reorderEdges(origEdges, criterion);
    }
  }

  List<Edge> reorderEdges(List<Edge> origEdges, String criterion) {
    int i;
    int n = origEdges.length;
    Edge edge;
    // we're going to reorder the edges in order of traversal
    List<bool> done = List.filled(n, false);
    int nDone = 0;
    List<Edge> newEdges = [];

    i = 0;
    edge = origEdges[i];
    newEdges.add(edge);
    _edgeOrientations.add(LR.LEFT);

    var firstPoint = (criterion == "vertex") ? edge.leftVertex : edge.leftSite;
    var lastPoint = (criterion == "vertex") ? edge.rightVertex : edge.rightSite;

    if (firstPoint == Vertex.VERTEX_AT_INFINITY ||
        lastPoint == Vertex.VERTEX_AT_INFINITY) {
      return [];
    }

    done[i] = true;
    ++nDone;

    while (nDone < n) {
      for (i = 1; i < n; ++i) {
        if (done[i]) {
          continue;
        }
        edge = origEdges[i];
        var leftPoint =
            (criterion == "vertex") ? edge.leftVertex : edge.leftSite;
        var rightPoint =
            (criterion == "vertex") ? edge.rightVertex : edge.rightSite;
        if (leftPoint == Vertex.VERTEX_AT_INFINITY ||
            rightPoint == Vertex.VERTEX_AT_INFINITY) {
          return [];
        }
        if (leftPoint == lastPoint) {
          lastPoint = rightPoint;
          _edgeOrientations.add(LR.LEFT);
          newEdges.add(edge);
          done[i] = true;
        } else if (rightPoint == firstPoint) {
          firstPoint = leftPoint;
          _edgeOrientations.insert(0, LR.LEFT);
          newEdges.insert(0, edge);
          done[i] = true;
        } else if (leftPoint == firstPoint) {
          firstPoint = rightPoint;
          _edgeOrientations.insert(0, LR.RIGHT);
          newEdges.insert(0, edge);
          done[i] = true;
        } else if (rightPoint == lastPoint) {
          lastPoint = leftPoint;
          _edgeOrientations.add(LR.RIGHT);
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
