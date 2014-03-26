part of voronoi;

List<Edge> selectNonIntersectingEdges(var keepOutMask, List<Edge> edgesToTest) {
  if (keepOutMask == null) {
    return edgesToTest;
  }

  /*var zeroPoint:Point = new Point();
  return edgesToTest.filter(myTest);

  function myTest(edge:Edge, index:int, vector:Vector.<Edge>):Boolean
  {
    var delaunayLineBmp:BitmapData = edge.makeDelaunayLineBmp();
    var notIntersecting:Boolean = !(keepOutMask.hitTest(zeroPoint, 1, delaunayLineBmp, zeroPoint, 1));
    delaunayLineBmp.dispose();
    return notIntersecting;
  }*/
}