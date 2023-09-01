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
    siteList.sort();

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
    final EdgeReorderer reorderer = EdgeReorderer(hullEdges, (Edge edge) => edge.sites);
    final Iterable<Edge> reorderedEdges = reorderer.orderedEdges;

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

    void pushHalfEdge(HalfEdge halfEdge, Edge bisectorEdge, Site<num> site) {
      final Point<num>? intersection = halfEdge.edge?.intersect(bisectorEdge);
      if (intersection != null) {
        heap.remove(halfEdge.sortHash);
        halfEdge
          ..vertex = intersection
          ..yStar = intersection.y + site.distanceTo(intersection);
        heap[halfEdge.sortHash] = halfEdge;
      }
    }

    void handleSmallestSite(Site<num> newSite) {
      final HalfEdge lbnd = edgeList.edgeListLeftNeighbor(newSite); // the HalfEdge just to the left of newSite
      final Edge? rbndEdge = lbnd.edgeListRightNeighbor!.edge; // the Edge just to the right

      final Site<num> bottomSite = rbndEdge?.sites[rbndEdge.direction] ?? bottommostSite;

      final Edge edge = Edge.createBisectingEdge(bottomSite, newSite);
      edges.add(edge);

      final HalfEdge leftBisector = HalfEdge(Edge.fromOther(edge)..direction = Direction.left);
      final HalfEdge rightBisector = HalfEdge(Edge.fromOther(edge)..direction = Direction.right);
      edgeList
        ..insertToRightOfHalfEdge(lbnd, leftBisector)
        ..insertToRightOfHalfEdge(leftBisector, rightBisector);
      pushHalfEdge(lbnd, leftBisector.edge!, newSite);
      if (rbndEdge != null) {
        pushHalfEdge(rightBisector, rbndEdge, newSite);
      }
    }

    void handleSmallestIntersection() {
      final HalfEdge lbnd = heap[heap.firstKey()]!;
      final HalfEdge rbnd = lbnd.edgeListRightNeighbor!;
      final HalfEdge llbnd = lbnd.edgeListLeftNeighbor!;
      final Edge? rrbndEdge = rbnd.edgeListRightNeighbor!.edge;

      Site<num> bottomSite = lbnd.edge?.sites[lbnd.edge!.direction] ?? bottommostSite;
      Site<num> topSite = rbnd.edge?.sites[rbnd.edge!.direction.other] ?? bottommostSite;
      Direction direction = Direction.left;
      if (bottomSite.y > topSite.y) {
        (bottomSite, topSite) = (topSite, bottomSite);
        direction = Direction.right;
      }

      lbnd.edge!.vertices[lbnd.edge!.direction] = lbnd.vertex;
      rbnd.edge!.vertices[rbnd.edge!.direction] = lbnd.vertex;
      heap.remove(lbnd.sortHash);
      edgeList.remove(lbnd);
      heap.remove(rbnd.sortHash);
      edgeList.remove(rbnd);

      final Edge edge = Edge.createBisectingEdge(bottomSite, topSite);
      edges.add(edge);
      edge.vertices[direction.other] = lbnd.vertex;

      final HalfEdge bisector = HalfEdge(Edge.fromOther(edge)..direction = direction);
      edgeList.insertToRightOfHalfEdge(llbnd, bisector);
      pushHalfEdge(llbnd, bisector.edge!, bottomSite);
      if (rrbndEdge != null) {
        pushHalfEdge(bisector, rrbndEdge, bottomSite);
      }
    }

    Site<num>? newSite = siteList.next();
    for (;;) {
      if (newSite != null && (heap.isEmpty || newSite.hashCode.compareTo(heap.firstKey()!) < 0)) {
        handleSmallestSite(newSite);
        newSite = siteList.next();
      } else if (heap.isNotEmpty) {
        handleSmallestIntersection();
      } else {
        break;
      }
    }

    clipEdges();
  }

  void clipEdges() {
    for (final Edge edge in edges) {
      edge.clipVertices(_plotBounds);
    }
  }
}
