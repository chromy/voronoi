part of voronoi;

class EdgeList {
  num _deltax;
  num _xmin;

  late int _hashsize;
  late List<Halfedge?> _hash;
  late Halfedge _leftEnd;

  Halfedge get leftEnd => _leftEnd;
  late Halfedge _rightEnd;

  Halfedge get rightEnd => _rightEnd;

  EdgeList(this._xmin, this._deltax, int sqrt_nsites) {
    // TODO: fix hack
    _deltax = _deltax == 0 ? 1 : _deltax;
    _hashsize = 2 * sqrt_nsites;

    _hash = List.filled(_hashsize, null);

    // two dummy Halfedges:
    _leftEnd = Halfedge.createDummy();
    _rightEnd = Halfedge.createDummy();
    _leftEnd.edgeListLeftNeighbor = null;
    _leftEnd.edgeListRightNeighbor = _rightEnd;
    _rightEnd.edgeListLeftNeighbor = _leftEnd;
    _rightEnd.edgeListRightNeighbor = null;
    _hash[0] = _leftEnd;
    _hash[_hashsize - 1] = _rightEnd;
  }

  /// Insert newHalfedge to the right of lb
  /// @param lb
  /// @param newHalfedge
  ///
  void insert(Halfedge lb, Halfedge newHalfedge) {
    newHalfedge.edgeListLeftNeighbor = lb;
    newHalfedge.edgeListRightNeighbor = lb.edgeListRightNeighbor;
    lb.edgeListRightNeighbor!.edgeListLeftNeighbor = newHalfedge;
    lb.edgeListRightNeighbor = newHalfedge;
  }

  /// This function only removes the Halfedge from the left-right list.
  /// We cannot dispose it yet because we are still using it.
  /// @param halfEdge
  ///
  void remove(Halfedge halfEdge) {
    halfEdge.edgeListLeftNeighbor!.edgeListRightNeighbor = halfEdge.edgeListRightNeighbor;
    halfEdge.edgeListRightNeighbor!.edgeListLeftNeighbor = halfEdge.edgeListLeftNeighbor;
    halfEdge.edge = Edge.DELETED;
    halfEdge.edgeListLeftNeighbor = halfEdge.edgeListRightNeighbor = null;
  }

  /// Find the rightmost Halfedge that is still left of p
  /// @param p
  /// @return
  ///
  Halfedge edgeListLeftNeighbor(Point<num> p) {
    int bucket;
    Halfedge? halfEdge;

    /* Use hash table to get close to desired halfedge */
    bucket = ((p.x - _xmin) / _deltax * _hashsize).round();
    if (bucket < 0) {
      bucket = 0;
    }
    if (bucket >= _hashsize) {
      bucket = _hashsize - 1;
    }
    halfEdge = getHash(bucket);
    if (halfEdge == null) {
      for (int i = 1; true; ++i) {
        if ((halfEdge = getHash(bucket - i)) != null) break;
        if ((halfEdge = getHash(bucket + i)) != null) break;
      }
    }

    /* Now search linear list of halfedges for the correct one */
    if (halfEdge == leftEnd || (halfEdge != rightEnd && halfEdge!.isLeftOf(p))) {
      do {
        halfEdge = halfEdge!.edgeListRightNeighbor!;
      } while (halfEdge != rightEnd && halfEdge.isLeftOf(p));
      halfEdge = halfEdge.edgeListLeftNeighbor!;
    } else {
      do {
        halfEdge = halfEdge!.edgeListLeftNeighbor!;
      } while (halfEdge != leftEnd && !halfEdge.isLeftOf(p));
    }

    /* Update hash table and reference counts */
    if (bucket > 0 && bucket < _hashsize - 1) {
      _hash[bucket] = halfEdge;
    }
    return halfEdge;
  }

  /* Get entry from hash table, pruning any deleted nodes */
  Halfedge? getHash(int b) {
    Halfedge? halfEdge;

    if (b < 0 || b >= _hashsize) {
      return null;
    }
    halfEdge = _hash[b];
    if (halfEdge != null && halfEdge.edge == Edge.DELETED) {
      /* Hash table points to deleted halfedge.  Patch as necessary. */
      _hash[b] = null;
      // still can't dispose halfEdge yet!
      return null;
    } else {
      return halfEdge;
    }
  }
}
