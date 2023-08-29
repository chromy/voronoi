part of voronoi;

class VertexPair<T extends Point<num>?> {
  T left;
  T right;

  VertexPair(this.left, this.right);

  T? operator [](Direction direction) {
    switch (direction) {
      case Direction.left:
        return left;
      case Direction.right:
        return right;
      case Direction.none:
      case Direction.both:
        return null;
    }
  }

  void operator []=(Direction direction, T newVertex) {
    switch (direction) {
      case Direction.left:
        left = newVertex;
        break;
      case Direction.right:
        right = newVertex;
        break;
      case Direction.both:
        left = newVertex;
        right = newVertex;
        break;
      case Direction.none:
        throw ArgumentError("Can not set the vertex for the Direction.none direction.");
    }
  }

  bool isDefined(Direction direction) {
    switch (direction) {
      case Direction.left:
        return left != null;
      case Direction.right:
        return right != null;
      case Direction.both:
        return left != null && right != null;
      case Direction.none:
        return left == null && right == null;
    }
  }

  bool isUndefined(Direction direction) {
    switch (direction) {
      case Direction.left:
        return left == null;
      case Direction.right:
        return right == null;
      case Direction.both:
        return left == null && right == null;
      case Direction.none:
        return left != null && right != null;
    }
  }
}
