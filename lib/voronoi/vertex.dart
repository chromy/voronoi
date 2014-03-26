part of voronoi;

class Vertex {
  static int _nvertices = 0;
  
  static final Vertex VERTEX_AT_INFINITY = new Vertex(double.NAN, double.NAN);
  // TODO: make x and y unsetable
  // TODO: fix coord/vertex
  num x, y;
  Point coord;
  int _vertexIndex;
  
  Vertex(num x, num y) {
    this.x = x;
    this.y = y;
    coord = new Point(x, y);
  }
  
  factory Vertex.create(num x, num y) {
    if (x.isNaN || y.isNaN) {
      return VERTEX_AT_INFINITY;
    }
    return new Vertex(x, y);
  }
  
  String toString() {
    return "Vertex($x, $y)";
  }
  
  /**
   * This is the only way to make a Vertex
   * 
   * @param halfedge0
   * @param halfedge1
   * @return 
   * 
   */
   factory Vertex.intersect(Halfedge halfedge0, Halfedge halfedge1) {
    Edge edge0, edge1, edge;
    Halfedge halfedge;
    num determinant, intersectionX, intersectionY;
    bool rightOfSite;
    
    edge0 = halfedge0.edge;
    edge1 = halfedge1.edge;
    
    if (edge0 == null || edge1 == null) {
      return null;
    }
    
    if (edge0.rightSite == edge1.rightSite) {
      return null;
    }
    
    determinant = edge0.a * edge1.b - edge0.b * edge1.a;
    if (-1.0e-10 < determinant && determinant < 1.0e-10) {
      // the edges are parallel
      return null;
    }
    
    intersectionX = (edge0.c * edge1.b - edge1.c * edge0.b)/determinant;
    intersectionY = (edge1.c * edge0.a - edge0.c * edge1.a)/determinant;
    
    if (Voronoi.compareByYThenX(edge0.rightSite, edge1.rightSite) < 0) {
      halfedge = halfedge0; edge = edge0;
    } else {
      halfedge = halfedge1; edge = edge1;
    }
    rightOfSite = intersectionX >= edge.rightSite.x;
    if ((rightOfSite && halfedge.leftRight == LR.LEFT)
        ||(!rightOfSite && halfedge.leftRight == LR.RIGHT)) {
      return null;
    }
    
    return new Vertex.create(intersectionX, intersectionY);
  }
   
  void setIndex() {
     _vertexIndex = _nvertices++;
  }
}