part of voronoi;

enum LR {
  left, right, none;

  LR get other {
    switch (this) {
      case LR.left:
        return LR.right;
      case LR.right:
        return LR.left;
      case LR.none:
        return LR.none;
    }
  }
}
