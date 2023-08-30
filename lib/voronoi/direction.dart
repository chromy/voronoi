part of voronoi;

enum Direction {
  left, right, none, both;

  Direction get other {
    switch (this) {
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
      case Direction.none:
        return Direction.both;
      case Direction.both:
        return Direction.none;
    }
  }
}
