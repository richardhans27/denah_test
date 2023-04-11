import 'package:denah_test/functions/imageviewport.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:flutter/material.dart';

class ZoomContainerState extends State<ZoomContainer> {
  late double _zoomLevel;
  late ImageProvider _imageProvider;
  late List<MapObject> _objects;
  late Widget _child;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _imageProvider = widget.imageProvider;
    _objects = widget.objects;
    _child =  widget.child;
    _mode = widget.mode;
  }

  @override
  void didUpdateWidget(ZoomContainer oldWidget){
    super.didUpdateWidget(oldWidget);
    if(widget.imageProvider != _imageProvider) _imageProvider = widget.imageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ImageViewport(
          zoomLevel: _zoomLevel,
          imageProvider: _imageProvider,
          objects: _objects,
          mode: _mode,
        ),
        Row(
          children: <Widget>[
            IconButton(
              color: Colors.red,
              icon: Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = _zoomLevel * 2;
                });
              },
            ),
            SizedBox(
              width: 5,
            ),
            IconButton(
              color: Colors.red,
              icon: Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _zoomLevel = _zoomLevel / 2;
                });
              },
            ),
          ],
        ),
        Stack(children: [_child],)
      ],
    );
  }
}

class ZoomContainer extends StatefulWidget {
  final double zoomLevel;
  final ImageProvider imageProvider;
  final List<MapObject> objects;
  final Widget child;
  final String mode;

  ZoomContainer({
    this.zoomLevel = 1,
    required this.imageProvider,
    this.objects = const [],
    this.child = const SizedBox(),
    this.mode = "2",
  });

  @override
  State<StatefulWidget> createState() => ZoomContainerState();
}