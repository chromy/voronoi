part of voronoi;

class EdgeList extends ListBase<Halfedge?> {
  num _deltaX;
  final num _xMin;
  late int _hashSize;

  late List<Halfedge?> _hash;

  late Halfedge _leftEnd;
  Halfedge get leftEnd => _leftEnd;

  late Halfedge _rightEnd;
  Halfedge get rightEnd => _rightEnd;

  EdgeList(this._xMin, this._deltaX, int sqrtNSites) {
    // TODO: fix hack
    _deltaX = _deltaX == 0 ? 1 : _deltaX;

    _hashSize = 2 * sqrtNSites;
    _hash = List<Halfedge?>.filled(_hashSize, null);

    // two dummy HalfEdges:
    _leftEnd = Halfedge.createDummy();
    _rightEnd = Halfedge.createDummy();
    _leftEnd..edgeListLeftNeighbor = null
    ..edgeListRightNeighbor = _rightEnd;
    _rightEnd..edgeListLeftNeighbor = _leftEnd
    ..edgeListRightNeighbor = null;
    this[0] = _leftEnd;
    this[_hashSize - 1] = _rightEnd;
  }

  @override
  int get length => _hash.length;

  @override
  set length(int newLength) => _hash.length = newLength;

  @override
  Halfedge? operator [](int index) => _hash[index];

  @override
  void operator []=(int index, Halfedge? value) => _hash[index] = value;

  /// Insert newHalfEdge to the right of a given other edge.
  void insertToRightOfHalfEdge(Halfedge leftNeighbor, Halfedge newHalfEdge) {
    newHalfEdge..edgeListLeftNeighbor = leftNeighbor
    ..edgeListRightNeighbor = leftNeighbor.edgeListRightNeighbor;
    leftNeighbor.edgeListRightNeighbor!.edgeListLeftNeighbor = newHalfEdge;
    leftNeighbor.edgeListRightNeighbor = newHalfEdge;
  }

  /// This function only removes the HalfEdge from the left-right list.
  /// We cannot dispose it yet because we are still using it.
  @override
  bool remove(Object? halfEdge) {
    if (halfEdge == null || halfEdge is! Halfedge) {
      return false;
    }

    halfEdge.edgeListLeftNeighbor!.edgeListRightNeighbor = halfEdge.edgeListRightNeighbor;
    halfEdge.edgeListRightNeighbor!.edgeListLeftNeighbor = halfEdge.edgeListLeftNeighbor;
    halfEdge..edge = Edge.deleted
    ..edgeListLeftNeighbor = halfEdge.edgeListRightNeighbor = null;

    return true;
  }

  /// Find the rightmost HalfEdge that is still left of the given point.
  Halfedge edgeListLeftNeighbor(Point<num> point) {
    int bucket;
    Halfedge? halfEdge;

    /* Use hash table to get close to desired halfEdge */
    bucket = ((point.x - _xMin) / _deltaX * _hashSize).round();
    if (bucket < 0) {
      bucket = 0;
    }
    if (bucket >= _hashSize) {
      bucket = _hashSize - 1;
    }
    halfEdge = getHash(bucket);
    if (halfEdge == null) {
      for (int i = 1; i<_hashSize; ++i) {
        if ((halfEdge = getHash(bucket - i)) != null) {
          break;
        }
        if ((halfEdge = getHash(bucket + i)) != null) {
          break;
        }
      }
    }

    /* Now search linear list of halfEdges for the correct one */
    if (halfEdge == leftEnd || (halfEdge != rightEnd && halfEdge!.isLeftOf(point))) {
      do {
        halfEdge = halfEdge!.edgeListRightNeighbor!;
      } while (halfEdge != rightEnd && halfEdge.isLeftOf(point));
      halfEdge = halfEdge.edgeListLeftNeighbor!;
    } else {
      do {
        halfEdge = halfEdge!.edgeListLeftNeighbor!;
      } while (halfEdge != leftEnd && !halfEdge.isLeftOf(point));
    }

    /* Update hash table and reference counts */
    if (bucket > 0 && bucket < _hashSize - 1) {
      this[bucket] = halfEdge;
    }
    return halfEdge;
  }

  /* Get entry from hash table, pruning any deleted nodes */
  Halfedge? getHash(int b) {
    if (b < 0 || b >= _hashSize) {
      return null;
    }

    final Halfedge? halfEdge = this[b];
    if (halfEdge != null && halfEdge.edge == Edge.deleted) {
      /* Hash table points to deleted halfEdge.  Patch as necessary. */
      this[b] = null;
      // still can't dispose halfEdge yet!
      return null;
    } else {
      return halfEdge;
    }
  }
}
