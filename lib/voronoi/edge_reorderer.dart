part of voronoi;

class EdgeReorderer {
    List<Edge> _edges;
    List<LR> _edgeOrientations;
    List<Edge> get edges => _edges;
    
    List<LR> get edgeOrientations => _edgeOrientations;
    
    EdgeReorderer(List<Edge> origEdges, var criterion) {
      if (criterion != Vertex && criterion != Site) {
        throw new ArgumentError("Edges: criterion must be Vertex or Site");
      }
      _edges = [];
      _edgeOrientations = [];
      if (origEdges.length > 0) {
        _edges = reorderEdges(origEdges, criterion);
      }
    }

    List<Edge> reorderEdges(List<Edge> origEdges, var criterion) {
      int i, j;
      int n = origEdges.length;
      Edge edge;
      // we're going to reorder the edges in order of traversal
      List<bool> done = new List(n);
      int nDone = 0;
      for (bool b in done) {
        b = false;
      }
      List<Edge> newEdges = [];
      
      i = 0;
      edge = origEdges[i];
      newEdges.add(edge);
      _edgeOrientations.add(LR.LEFT);
      Point firstPoint = (criterion == Vertex) ? edge.leftVertex : edge.leftSite;
      Point lastPoint = (criterion == Vertex) ? edge.rightVertex : edge.rightSite;
      
      if (firstPoint == Vertex.VERTEX_AT_INFINITY || lastPoint == Vertex.VERTEX_AT_INFINITY) {
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
          Point leftPoint = (criterion == Vertex) ? edge.leftVertex : edge.leftSite;
          Point rightPoint = (criterion == Vertex) ? edge.rightVertex : edge.rightSite;
          if (leftPoint == Vertex.VERTEX_AT_INFINITY || rightPoint == Vertex.VERTEX_AT_INFINITY) {
            return [];
          }
          if (leftPoint == lastPoint) {
            lastPoint = rightPoint;
            _edgeOrientations.add(LR.LEFT);
            newEdges.add(edge);
            done[i] = true;
          } else if (rightPoint == firstPoint) {
            firstPoint = leftPoint;
            _edgeOrientations.remove(LR.LEFT);
            newEdges.remove(edge);
            done[i] = true;
          } else if (leftPoint == firstPoint) {
            firstPoint = rightPoint;
            _edgeOrientations.remove(LR.RIGHT);
            newEdges.remove(edge);
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