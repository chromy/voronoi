part of voronoi;

List<Edge> selectNonIntersectingEdges(var keepOutMask, List<Edge> edgesToTest) {
  if (keepOutMask == null) {
    return edgesToTest;
  }

  //Not sure what should be here, but dartanalyzer is complaining about a lack of return in this function. Looks like there was a return, but it was commented out, and I'm not sure why. Returning the passed in array seems the least destructive fix for the time being.
  return edgesToTest;

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
