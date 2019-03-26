part of voronoi;

class Circle {
  Point center;
  num radius;

  Circle(num centerX, num centerY, num radius) {
    this.center = new Point(centerX, centerY);
    this.radius = radius;
  }

  String toString() {
    return "Circle (center: $center radius: $radius)";
  }
}
