/*
 * The author of this software is Steven Fortune.  Copyright (c) 1994 by AT&T
 * Bell Laboratories.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR AT&T MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 */

library voronoi;

import 'dart:collection';
import 'dart:math' as math;

part 'geom/circle.dart';
part 'geom/line_segment.dart';
part 'geom/point.dart';
part 'geom/polygon.dart';
part 'geom/triangle.dart';
part 'geom/winding.dart';
part 'voronoi/direction.dart';
part 'voronoi/edge.dart';
part 'voronoi/edge_list.dart';
part 'voronoi/edge_reorderer.dart';
part 'voronoi/half_edge.dart';
part 'voronoi/oriented_pair.dart';
part 'voronoi/site.dart';
part 'voronoi/site_list.dart';
part 'voronoi/vertex.dart';

class Voronoi {
  late final SiteList<num> siteList = SiteList<num>();

  List<Site<num>> get sites => siteList.toList();

  final Map<math.Point<num>, Site<num>> siteMap = <Point<num>, Site<num>>{};

  final List<Edge> edges = <Edge>[];

  // TODO generalize this so it doesn't have to be a rectangle;
  // then we can make the fractal voronois-within-voronois
  final math.Rectangle<num> _plotBounds;

  math.Rectangle<num> get plotBounds => _plotBounds;

  Voronoi(Iterable<math.Point<num>> points, this._plotBounds) {
    for (final math.Point<num> point in points) {
      final Site<num> site = Site<num>(point.x, point.y);
      siteList.add(site);
      siteMap[point] = site;
    }

    fortunesAlgorithm();
  }

  List<Point<num>> region(math.Point<num> point) => siteMap[point]?.region(_plotBounds) ?? <Point<num>>[];

  Iterable<Point<num>> neighborSitesForSite(math.Point<num> point) =>
      siteMap[point]?.neighborSites() ?? const Iterable<Site<num>>.empty();

  Iterable<Circle> circles() => siteList.circles();

  Iterable<LineSegment<Point<num>>> voronoiBoundaryForSite(math.Point<num> point) =>
      visibleLineSegments(selectEdgesForSitePoint(point, edges));

  Iterable<LineSegment<Point<num>>> delaunayLinesForSite(math.Point<num> point) =>
      delaunayLinesForEdges(selectEdgesForSitePoint(point, edges));

  Iterable<LineSegment<Point<num>>> voronoiDiagram() => visibleLineSegments(edges);

  Iterable<LineSegment<Point<num>>> delaunayTriangulation() => delaunayLinesForEdges(edges);

  Iterable<LineSegment<Point<num>>> hull() => delaunayLinesForEdges(hullEdges);

  Iterable<LineSegment<Point<num>>> delaunayLinesForEdges(Iterable<Edge> edges) =>
      edges.map((Edge edge) => edge.delaunayLine());

  Iterable<Edge> selectEdgesForSitePoint(math.Point<num> point, Iterable<Edge> edgesToTest) =>
      edgesToTest.where((Edge edge) => edge.sites.left == point || edge.sites.right == point);

  Iterable<LineSegment<Point<num>>> visibleLineSegments(Iterable<Edge> edges) =>
      edges.map((Edge edge) => edge.voronoiEdge()).whereType<LineSegment<Point<num>>>();

  Iterable<Edge> get hullEdges => edges.where((Edge edge) => edge.isPartOfConvexHull());

  Iterable<Point<num>> hullPointsInOrder() {
    final EdgeReorderer<Site<num>> reorderer = EdgeReorderer<Site<num>>(hullEdges);
    final Iterable<Edge> reorderedEdges = reorderer.edges;

    return reorderedEdges.map((Edge edge) => edge.sites[edge.direction]).whereType<Site<num>>();
  }

  Iterable<List<Point<num>>> regions() => siteList.regions(_plotBounds);

  void fortunesAlgorithm() {
    if (siteList.isEmpty) {
      return;
    }

    final SplayTreeMap<int, HalfEdge> heap = SplayTreeMap<int, HalfEdge>();
    final math.Rectangle<num> dataBounds = siteList.getSitesBounds();
    final EdgeList edgeList = EdgeList(dataBounds.left, dataBounds.width, siteList.length);

    final Site<num> bottommostSite = siteList.next()!;
    Site<num>? newSite = siteList.next();

    for (;;) {
      if (newSite != null && (heap.isEmpty || newSite.hashCode.compareTo(heap.firstKey()!) < 0)) {
        /* new site is smallest */

        // Step 8:
        HalfEdge lbnd = edgeList.edgeListLeftNeighbor(newSite); // the HalfEdge just to the left of newSite
        final HalfEdge rbnd = lbnd.edgeListRightNeighbor!; // the HalfEdge just to the right
        final Site<num> bottomSite = rbnd.edge?.sites[rbnd.direction] ?? bottommostSite;
        // this Site determines the region containing the new site

        // Step 9:
        final Edge edge = Edge.createBisectingEdge(bottomSite, newSite);
        edges.add(edge);

        final HalfEdge leftBisector = HalfEdge(edge, Direction.left);
        // inserting two HalfEdges into edgeList constitutes Step 10:
        // insert leftBisector to the right of lbnd:
        edgeList.insertToRightOfHalfEdge(lbnd, leftBisector);

        // first half of Step 11:
        Vertex<num>? vertex = Vertex.intersect(leftBisector, lbnd);
        if (vertex != null) {
          heap.remove(lbnd.sortHash);
          lbnd
            ..vertex = vertex
            ..yStar = vertex.y + newSite.distanceTo(vertex);
          heap[lbnd.sortHash] = lbnd;
        }

        lbnd = leftBisector;

        final HalfEdge rightBisector = HalfEdge(edge, Direction.right);
        // second HalfEdge for Step 10:
        // insert rightBisector to the right of lbnd:
        edgeList.insertToRightOfHalfEdge(lbnd, rightBisector);

        // second half of Step 11:
        vertex = Vertex.intersect(rightBisector, rbnd);
        if (vertex != null) {
          rightBisector
            ..vertex = vertex
            ..yStar = vertex.y + newSite.distanceTo(vertex);
          heap[rightBisector.sortHash] = rightBisector;
        }

        newSite = siteList.next();
      } else if (heap.isNotEmpty) {
        /* intersection is smallest */
        final HalfEdge lbnd = heap[heap.firstKey()]!;
        heap.remove(lbnd.sortHash);
        final HalfEdge llbnd = lbnd.edgeListLeftNeighbor!;
        final HalfEdge rbnd = lbnd.edgeListRightNeighbor!;
        final HalfEdge rrbnd = rbnd.edgeListRightNeighbor!;
        Site<num> bottomSite = lbnd.edge?.sites[lbnd.direction] ?? bottommostSite;
        Site<num> topSite = rbnd.edge?.sites[rbnd.direction.other] ?? bottommostSite;
        // these three sites define a Delaunay triangle
        // (not actually using these for anything...)
        //_triangles.push(new Triangle(bottomSite, topSite, rightRegion(lbnd)));

        final Vertex<num> v = lbnd.vertex!..setIndex();
        lbnd.edge!.vertices[lbnd.direction] = v;
        rbnd.edge!.vertices[rbnd.direction] = v;
        edgeList.remove(lbnd);
        heap.remove(rbnd.sortHash);
        edgeList.remove(rbnd);
        Direction direction = Direction.left;
        if (bottomSite.y > topSite.y) {
          (bottomSite, topSite) = (topSite, bottomSite);
          direction = Direction.right;
        }
        final Edge edge = Edge.createBisectingEdge(bottomSite, topSite);
        edges.add(edge);
        final HalfEdge bisector = HalfEdge(edge, direction);
        edgeList.insertToRightOfHalfEdge(llbnd, bisector);
        edge.vertices[direction.other] = v;
        Vertex<num>? vertex = Vertex.intersect(llbnd, bisector);
        if (vertex != null) {
          heap.remove(llbnd.sortHash);
          llbnd
            ..vertex = vertex
            ..yStar = vertex.y + bottomSite.distanceTo(vertex);
          heap[llbnd.sortHash] = llbnd;
        }
        vertex = Vertex.intersect(bisector, rrbnd);
        if (vertex != null) {
          bisector
            ..vertex = vertex
            ..yStar = vertex.y + bottomSite.distanceTo(vertex);
          heap[bisector.sortHash] = bisector;
        }
      } else {
        break;
      }
    }

    for (final Edge edge in edges) {
      edge.clipVertices(_plotBounds);
    }
  }
}
