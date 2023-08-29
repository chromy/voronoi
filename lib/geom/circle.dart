part of voronoi;

class Circle {
  Point center;
  num radius;

  Circle(this.center, this.radius);

  String toString() {
    return "Circle (center: $center radius: $radius)";
  }
}
