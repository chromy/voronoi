part of voronoi;

// also known as heap
class HalfedgePriorityQueue {
  List<HalfEdge> _hash = <HalfEdge>[];
  int _count = 0;
  int _minBucket = 0;
  late int _hashsize;

  final num _ymin;
  final num _deltay;

  HalfedgePriorityQueue(this._ymin, this._deltay, int sqrtNSites) {
    _hashsize = 4 * sqrtNSites;
    _hash = List<HalfEdge>.filled(_hashsize, HalfEdge.createDummy());
  }

  /*
   void dispose() {
    // get rid of dummies
    for (var i:int = 0; i < _hashsize; ++i)
    {
      _hash[i].dispose();
      _hash[i] = null;
    }
    _hash = null;
  }
  */


  void insert(HalfEdge halfEdge) {
    HalfEdge? previous, next;
    final int insertionBucket = bucket(halfEdge);
    if (insertionBucket < _minBucket) {
      _minBucket = insertionBucket;
    }
    previous = _hash[insertionBucket];
    while ((next = previous?.nextInPriorityQueue) != null &&
        (halfEdge.yStar > next!.yStar ||
            (halfEdge.yStar == next.yStar &&
                halfEdge.vertex!.x > next.vertex!.x))) {
      previous = next;
    }
    halfEdge.nextInPriorityQueue = previous!.nextInPriorityQueue;
    previous.nextInPriorityQueue = halfEdge;
    ++_count;
  }

  void remove(HalfEdge halfEdge) {
    HalfEdge previous;
    final int removalBucket = bucket(halfEdge);

    if (halfEdge.vertex != null) {
      previous = _hash[removalBucket];
      while (previous.nextInPriorityQueue != halfEdge) {
        previous = previous.nextInPriorityQueue!;
      }
      previous.nextInPriorityQueue = halfEdge.nextInPriorityQueue;
      _count--;
      halfEdge..vertex = null
      ..nextInPriorityQueue = null;
      //halfEdge.dispose();
    }
  }

  int bucket(HalfEdge halfEdge) {
    int theBucket = ((halfEdge.yStar - _ymin) / _deltay * _hashsize).round();
    if (theBucket < 0) {
      theBucket = 0;
    }
    if (theBucket >= _hashsize) {
      theBucket = _hashsize - 1;
    }
    return theBucket;
  }

  bool isEmpty(int bucket) => _hash[bucket].nextInPriorityQueue == null;

  /// move _minBucket until it contains an actual Halfedge (not just the dummy at the top);
  ///
  void adjustMinBucket() {
    while (_minBucket < _hashsize - 1 && isEmpty(_minBucket)) {
      ++_minBucket;
    }
  }

  bool empty() => _count == 0;

  /// @return coordinates of the Halfedge's vertex in V*, the transformed Voronoi diagram
  ///
  Point<num> min() {
    adjustMinBucket();
    final HalfEdge? answer = _hash[_minBucket].nextInPriorityQueue;
    return Point<num>(answer!.vertex!.x, answer.yStar);
  }

  /// remove and return the min Halfedge
  /// @return
  ///
  HalfEdge extractMin() {
    HalfEdge answer;

    // get the first real Halfedge in _minBucket
    answer = _hash[_minBucket].nextInPriorityQueue!;

    _hash[_minBucket].nextInPriorityQueue = answer.nextInPriorityQueue;
    _count--;
    answer.nextInPriorityQueue = null;

    return answer;
  }
}
