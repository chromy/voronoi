part of voronoi;

class OrientedPair<T> {
  T left;
  T right;

  OrientedPair(this.left, this.right);

  OrientedPair<T> reverse() => OrientedPair<T>(this.right, this.left);

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

  void operator []=(Direction direction, T newValue) {
    switch (direction) {
      case Direction.left:
        left = newValue;
        break;
      case Direction.right:
        right = newValue;
        break;
      case Direction.both:
        left = newValue;
        right = newValue;
        break;
      case Direction.none:
        throw ArgumentError("Can not set a value for the Direction.none direction.");
    }
  }

  /// Syntactical sugar for setting both values at once.
  // ignore: avoid_setters_without_getters
  set both(T newValue) => this[Direction.both] = newValue;

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

  @override
  String toString() => "(left: $left, right: $right)";
}
