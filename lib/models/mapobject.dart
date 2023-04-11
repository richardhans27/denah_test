import 'package:denah_test/models/nodeinfo.dart';
import 'package:flutter/material.dart';

class MapObject {
  Widget child;

  ///relative offset from the center of the map for this map object. From -1 to 1 in each dimension.
  Offset offset;

  ///size of this object for the zoomLevel == 1
  final Size size;

  String id, level, mag;
  double angle;
  NodeInfo tooltip;
  int type;
  bool status, room, path, stairs, lift;

  MapObject({
    required this.id,
    required this.child,
    required this.offset,
    required this.size,
    required this.angle,
    required this.level,
    required this.tooltip,
    this.type = 0,
    this.status = true,
    this.room = false,
    this.path = false,
    this.stairs = false,
    this.lift = false,
    this.mag = "0",
  });
}