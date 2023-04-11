import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:denah_test/functions/functions.dart';
import 'package:denah_test/functions/mappainter.dart';
import 'package:denah_test/models/mapobject.dart';
import 'package:denah_test/models/nodeinfo.dart';
import 'package:flutter/material.dart';

class _ImageViewportState extends State<ImageViewport> {
  late double _zoomLevel;
  late ImageProvider _imageProvider;
  ui.Image? _image;
  late bool _resolved;
  late Offset _centerOffset;
  double _maxHorizontalDelta = 0.0;
  double _maxVerticalDelta = 0.0;
  late Offset _normalized;
  bool _denormalize = false;
  late Size _actualImageSize;
  late Size _viewportSize;

  late List<MapObject> _objects;

  late String _mode;

  double abs(double value) {
    return value < 0 ? value * (-1) : value;
  }

  void _updateActualImageDimensions() {
    _actualImageSize = Size((_image!.width / window.devicePixelRatio) * _zoomLevel, (_image!.height / ui.window.devicePixelRatio) * _zoomLevel);
  }

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.zoomLevel;
    _imageProvider = widget.imageProvider;
    _resolved = false;
    _centerOffset = Offset(0, 0);
    _objects = widget.objects;
    _mode = widget.mode;
  }

  void _resolveImageProvider(){
    ImageStream stream = _imageProvider.resolve(createLocalImageConfiguration(context));
    // stream.addListener((info, _) {
    //   _image = info.image;
    //   _resolved = true;
    //   _updateActualImageDimensions();
    //   setState(() {});
    // });

    stream.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        _image = image.image;
        _resolved = true;
        _updateActualImageDimensions();
        setState(() {});
    }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageProvider();
  }

  @override
  void didUpdateWidget(ImageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.imageProvider != _imageProvider) {
      _imageProvider = widget.imageProvider;
      _resolveImageProvider();
    }
    double normalizedDx = _maxHorizontalDelta == 0 ? 0 : _centerOffset.dx / _maxHorizontalDelta;
    double normalizedDy = _maxVerticalDelta == 0 ? 0 : _centerOffset.dy / _maxVerticalDelta;
    _normalized = Offset(normalizedDx, normalizedDy);
    _denormalize = true;
    _zoomLevel = widget.zoomLevel;
    _updateActualImageDimensions();
  }

  ///This is used to convert map objects relative global offsets from the map center
  ///to the local viewport offset from the top left viewport corner.
  Offset _globaltoLocalOffset(Offset value) {
    double hDelta = (_actualImageSize.width / 2) * value.dx;
    double vDelta = (_actualImageSize.height / 2) * value.dy;
    double dx = (hDelta - _centerOffset.dx) + (_viewportSize.width / 2);
    double dy = (vDelta - _centerOffset.dy) + (_viewportSize.height / 2);
    return Offset(dx, dy);
  }

  ///This is used to convert global coordinates of long press event on the map to relative global offsets from the map center
  Offset _localToGlobalOffset(Offset value) {
    double dx = value.dx - _viewportSize.width / 2;
    double dy = value.dy - _viewportSize.height / 2;
    double dh = dx + _centerOffset.dx;
    double dv = dy + _centerOffset.dy;
    return Offset(
      dh / (_actualImageSize.width / 2),
      dv / (_actualImageSize.height / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    void handleDrag(DragUpdateDetails updateDetails) {
      Offset newOffset = _centerOffset.translate(-updateDetails.delta.dx, -updateDetails.delta.dy);
      if (abs(newOffset.dx) <= _maxHorizontalDelta && abs(newOffset.dy) <= _maxVerticalDelta) {
        setState(() {
          _centerOffset = newOffset;
        });
      }
    }

    void addMapObject(MapObject object) => setState(() {
          // _objects.add(object);
        });

    void removeMapObject(MapObject object) => setState(() {
          _objects.remove(object);
        });

    List<Widget> buildObjects() {
      return _objects
          .map(
            (MapObject object) => Positioned(
                  left: _globaltoLocalOffset(object.offset).dx - (object.size == null ? 0 : (object.size.width * _zoomLevel) / 2),
                  top: _globaltoLocalOffset(object.offset).dy - (object.size == null ? 0 : (object.size.height * _zoomLevel) / 2),
                  child: GestureDetector(
                    onTapUp: (TapUpDetails details) {
                      MapObject info;
                      info = MapObject(
                        id: "2",
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              border: Border.all(
                            width: 1,
                          )),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text("Close me"),
                              SizedBox(
                                width: 5,
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                // onPressed: () => removeMapObject(info),
                                onPressed: () =>{},
                              ),
                            ],
                          ),
                        ),
                        offset: object.offset, 
                        size: Size(0, 0), 
                        angle: 0, 
                        level: '', 
                        tooltip: NodeInfo(message: '', status: false),
                      );
                      // addMapObject(info);
                    },
                    child: Transform.rotate(
                      angle: object.angle,
                      child: 
                      InkWell(
                        onTap: object.tooltip.status ? (){
                          _mode == "2" ? showPlaceDialog(context, object, true) : showPlaceDialog(context, object, false);
                        } : (){},
                        child: Container(
                          width: object.size == null ? null : object.size.width * _zoomLevel,
                          height: object.size == null ? null : object.size.height * _zoomLevel,
                          child: object.child,
                        ),
                      ),
                        
                        // object.tooltip.status ? Tooltip(
                        //   message: object.tooltip.message,
                        //   preferBelow: true,
                        //   verticalOffset: 10,
                        //   padding: const EdgeInsets.all(10),
                        //   decoration: BoxDecoration(
                        //       color: Colors.blueAccent.withOpacity(0.6),
                        //       borderRadius: BorderRadius.circular(22)),
                        //   textStyle: const TextStyle(
                        //       fontSize: 15,
                        //       fontStyle: FontStyle.italic,
                        //       color: Colors.white),
                        //   child: Container(
                        //     width: object.size == null ? null : object.size.width * _zoomLevel,
                        //     height: object.size == null ? null : object.size.height * _zoomLevel,
                        //     child: object.child,
                        //   ),
                        // ) : Container(
                        //   width: object.size == null ? null : object.size.width * _zoomLevel,
                        //   height: object.size == null ? null : object.size.height * _zoomLevel,
                        //   child: object.child,
                        // ),
                    ),
                  ),
                ),
          )
          .toList();
    }

    return _resolved
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _viewportSize = Size(min(constraints.maxWidth, _actualImageSize.width), min(constraints.maxHeight, _actualImageSize.height));
              _maxHorizontalDelta = (_actualImageSize.width - _viewportSize.width) / 2;
              _maxVerticalDelta = (_actualImageSize.height - _viewportSize.height) / 2;
              bool reactOnHorizontalDrag = _maxHorizontalDelta > _maxVerticalDelta;
              bool reactOnPan = (_maxHorizontalDelta > 0 && _maxVerticalDelta > 0);
              if (_denormalize) {
                _centerOffset = Offset(_maxHorizontalDelta * _normalized.dx, _maxVerticalDelta * _normalized.dy);
                _denormalize = false;
              }

              return GestureDetector(
                onPanUpdate: reactOnPan ? handleDrag : null,
                onHorizontalDragUpdate: reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                onVerticalDragUpdate: !reactOnHorizontalDrag && !reactOnPan ? handleDrag : null,
                // onLongPressEnd: (LongPressEndDetails details) {
                //   RenderBox box = context.findRenderObject() as RenderBox;
                //   Offset localPosition = box.globalToLocal(details.globalPosition);
                //   Offset newObjectOffset = _localToGlobalOffset(localPosition);
                //   print(newObjectOffset);
                //   MapObject newObject = MapObject(
                //     id: "2",
                //     child: const Icon(Icons.circle_sharp, size: 15,),
                //     offset: newObjectOffset,
                //     size: Size(5, 5),
                //     angle: 0,
                //     level: "1",
                //     tooltip: NodeInfo(message: '',status: false),
                //   );
                //   addMapObject(newObject);
                // },
                child: Stack(
                  children: <Widget>[
                        CustomPaint(
                          size: _viewportSize,
                          painter: MapPainter(_image!, _zoomLevel, _centerOffset),
                        ),
                      ] +
                      buildObjects(),
                ),
              );
            },
          )
        : SizedBox();
  }
}

class ImageViewport extends StatefulWidget {
  final double zoomLevel;
  final ImageProvider imageProvider;
  final List<MapObject> objects;
  final String mode;

  ImageViewport({
    required this.zoomLevel,
    required this.imageProvider,
    required this.objects,
    required this.mode,
  });

  @override
  State<StatefulWidget> createState() => _ImageViewportState();
}