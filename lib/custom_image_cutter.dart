library custom_image_cutter;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The view for the [CustomImageCutter]
class CustomImageCutter extends StatefulWidget {
  /// [Globalkey] uset to got reference when cut image
  final GlobalKey cropperKey;

  /// By default is [Colors.white]
  final Color overlayColor;

  /// By default is [Colors.transparent]
  final Color backgroundColor;

  /// Can be a [Image.network], [Image.assets], [Image.file], [Image.memory], etc.
  final Image image;

  /// Used to detect when image changes and reset all internal controls
  final String imagePath;
  final double maxScale;

  /// Holds the current state of the [scale], image [position], and allow to [crop] the image
  final CustomImageCutterController controller;

  const CustomImageCutter({
    super.key,
    required this.cropperKey,
    required this.image,
    required this.imagePath,
    required this.controller,
    this.maxScale = 5.0,
    this.backgroundColor = Colors.transparent,
    this.overlayColor = Colors.white,
  });

  @override
  State<CustomImageCutter> createState() => _CustomImageCutterState();
}

class _CustomImageCutterState extends State<CustomImageCutter> {
  String imagePath = '';
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
    widget.controller._maxScale = widget.maxScale;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    Completer<ui.Image> completer = Completer<ui.Image>();
    widget.image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
            (ImageInfo info, bool _) => completer.complete(info.image)));

    return FutureBuilder<ui.Image>(
        future: completer.future,
        builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
          if (snapshot.hasData &&
              widget.imagePath != imagePath &&
              completer.isCompleted) {
            imagePath = widget.imagePath;
            controller._initImageOriginalSize(
                height: snapshot.data!.height.toDouble(),
                width: snapshot.data!.width.toDouble());
          }
          return Stack(
            children: [
              GestureDetector(
                  onScaleUpdate: (ScaleUpdateDetails details) {
                    switch (details.pointerCount) {
                      case 1:
                        controller._onDrag(details);
                        break;
                      case 2:
                        controller._onScale(details.scale);
                        break;
                      default:
                        return;
                    }
                  },
                  child: ClipRect(
                    clipBehavior: Clip.antiAlias,
                    child: ColoredBox(
                      color: widget.backgroundColor,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            child: RepaintBoundary(
                              key: widget.cropperKey,
                              child: Stack(
                                children: [
                                  LayoutBuilder(
                                    builder: (_, constraint) {
                                      controller._initContainerSize(
                                          constraint.biggest.width);
                                      return AspectRatio(
                                        aspectRatio: 1,
                                        child: ClipOval(
                                            clipBehavior: Clip.none,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Transform.translate(
                                                    offset: controller._offset,
                                                    child: Transform.scale(
                                                        scale: controller
                                                            ._imageScale,
                                                        child: widget.image)),
                                              ],
                                            )),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: controller._containerSize * 1.2,
                            width: controller._containerSize * 1.2,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                  widget.overlayColor.withOpacity(0.5),
                                  BlendMode.srcOut),
                              child: Stack(
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          backgroundBlendMode:
                                              BlendMode.dstOut)),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      height: controller._containerSize * 0.9,
                                      width: controller._containerSize * 0.9,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(360)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        });
  }
}

/// Responsable to keep expose current state of [CustomImageCutter], and allow to cut the image
class CustomImageCutterController extends ChangeNotifier {
  double _containerSize = 0;
  double _imageHeight = 0;
  double _imageWidth = 0;
  double _imageScaledHeight = 0;
  double _imageScaledWidth = 0;
  double _imageScale = 1.0;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  double _maxScale = 5.0;
  double _lastScaleValue = 0.0;
  double _minScale = 0.0;

  /// Exposes the [maximum] [scale] to the view
  double get maxScale => _maxScale;

  /// Exposes the [minimum] [scale] to the view
  double get minScale => _minScale;

  /// Exposes the [actual] [scale] as a [ValueNotifier] to use on view
  ValueNotifier<double> scaleNotifier = ValueNotifier<double>(0.0);

  /// Exposes the [actual] [scale] to use on view
  double get scale => scaleNotifier.value;

  /// Get the [maxDisplacement] to [Y] axis from the current image
  double get _maxYDisplacement => _maxDisplacement(isXAxis: false);

  /// Get the [maxDisplacement] to [X] axis from the current image
  double get _maxXDisplacement => _maxDisplacement(isXAxis: true);

  /// Responsable for calculating the resized image size, which is used for get [maxDisplacement]
  double _calculateNewResizedSize(
      {required double originalBiggerSide,
      required double originalSmallerSide,
      required double newWidth}) {
    double ratio = newWidth / originalSmallerSide;
    double newSize = ratio * originalBiggerSide;
    if (_isSmallPicture) newSize = originalBiggerSide * ratio;
    return newSize;
  }

  double _maxDisplacement({required bool isXAxis}) {
    final scale = _imageScale / _minScale;
    final displacement = isXAxis
        ? _imageScaledWidth * scale - _containerSize
        : _imageScaledHeight * scale - _containerSize;
    final diference = displacement / 2;
    return diference;
  }

  /// Returns true if the [Y] axis offset is inside of the [maxDisplacement] from this axis
  bool get _isInsideOfYOffset =>
      _yOffset >= -_maxYDisplacement && _yOffset <= _maxYDisplacement;

  /// Returns true if the [X] axis offset is inside of the [maxDisplacement] from this axis
  bool get _isInsideOfXOffset =>
      _xOffset >= -_maxXDisplacement && _xOffset <= _maxXDisplacement;

  /// Should return true if the image has [portrait] format
  bool get _isPortrait => _imageHeight > _imageWidth;

  /// Should return true if the image is a [square]
  bool get _isSquare => _imageHeight == _imageWidth;

  /// Should return true when the image is smaller than the [_containerSize]
  bool get _isSmallPicture =>
      _imageHeight < _containerSize && _imageWidth < _containerSize;

  /// Holds the image offset
  Offset get _offset => Offset(_xOffset, _yOffset);

  /// Define [container] size to use for cut image
  void _initContainerSize(double size) => _containerSize = size;

  /// Set image size to calculate the boudaries for [maxDisplacement]
  void _initImageOriginalSize({required double height, required double width}) {
    _imageWidth = width;
    _imageHeight = height;
    if (_isPortrait) {
      _imageScaledWidth = _containerSize;
      _imageScaledHeight = _calculateNewResizedSize(
          originalBiggerSide: _imageHeight,
          originalSmallerSide: _imageWidth,
          newWidth: _containerSize);
    }
    if (!_isPortrait) {
      _imageScaledHeight = _containerSize;
      _imageScaledWidth = _calculateNewResizedSize(
          originalBiggerSide: _imageWidth,
          originalSmallerSide: _imageHeight,
          newWidth: _containerSize);
    }

    if (_containerSize > height && _containerSize > width) {
      _setScaleToSmallPicture(height: height, width: width);
    } else {
      _setScaleToPicture(height: height, width: width);
    }
    scaleNotifier.value = _imageScale;
  }

  /// Set the [scale] when the image is smaller than the [_containerSize]
  void _setScaleToSmallPicture(
      {required double height, required double width}) {
    if (height > width) {
      _setImageScale(_containerSize / width);
    } else {
      _setImageScale(_containerSize / height);
    }
  }

  /// Set the [scale] when the image is bigger than the [_containerSize]
  void _setScaleToPicture({required double height, required double width}) {
    if (_isSquare) {
      _setImageScale(1.0);
      return;
    }
    if (height > width) {
      _setImageScale(height / width);
    } else {
      _setImageScale(width / height);
    }
  }

  void _setImageScale(double scale) {
    _imageScale = scale;
    _minScale = scale;
    _maxScale = scale + _maxScale;
  }

  /// Reset all values when replace a image with a new one
  void reset() {
    _xOffset = 0.0;
    _yOffset = 0.0;
    _imageScaledHeight = 0;
    _imageScaledWidth = 0;
    _imageHeight = 0;
    _imageWidth = 0;
    _imageScale = _minScale;
    scaleNotifier.value = _imageScale;

    notifyListeners();
  }

  /// Return a [Uint8List] containing the cropped image
  Future<Uint8List?> crop(
      {required GlobalKey cropperKey, double pixelRatio = 3}) async {
    /// Get cropped image
    final renderObject = cropperKey.currentContext!.findRenderObject();
    final boundary = renderObject as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);

    /// Convert image to bytes in PNG format and return
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    return pngBytes;
  }

  /// Apply [scale] to image using [button] ou [slider]
  void updateScale(double newValue) {
    double scale = newValue;
    if (scale < _minScale) scale = _minScale;
    if (newValue > _maxScale) scale = maxScale;
    _setScale(scale);
  }

  /// Recognizes  gestures to apply [scale] to image using [gestures]
  void _onScale(double newValue) {
    double scaleFactor = newValue > _lastScaleValue
        ? newValue - _lastScaleValue
        : newValue - _lastScaleValue;
    _lastScaleValue = newValue;

    /// This verification is responsible for preventing a very large and abrupt variation in the zoom
    if (scaleFactor > 0.2 || scaleFactor < -0.2) return;

    scaleFactor = scaleFactor < 0 ? scaleFactor * 2 : scaleFactor;
    double scale = _imageScale + scaleFactor;
    if (scale < _minScale) return;
    if (scale > _maxScale) return;
    _setScale(scale);
  }

  /// Update [scale] from [_onScale] or [updateScale] methods
  void _setScale(double scale) {
    if (_imageScale > scale) {
      final zoomOutInteractions = _imageScale - scale;
      for (int interaction = 0;
          interaction < zoomOutInteractions;
          interaction++) {
        _updateOffsetInsideBoundaries();
        _imageScale = scale;
        scaleNotifier.value = _imageScale;
      }
      _updateOffsetInsideBoundaries();
    } else {
      _imageScale = scale;
      scaleNotifier.value = _imageScale;
      notifyListeners();
    }
  }

  /// Recognizes  gestures to apply [translation] to the image
  void _onDrag(ScaleUpdateDetails details) {
    final xOffsetTemp = _xOffset + details.focalPointDelta.dx;
    final yOffsetTemp = _yOffset + details.focalPointDelta.dy;

    _updateOffset(xOffsetTemp: xOffsetTemp, yOffsetTemp: yOffsetTemp);
  }

  /// Move the image inside the boudaries
  void _updateOffset(
      {required double yOffsetTemp, required double xOffsetTemp}) {
    if (yOffsetTemp >= -_maxYDisplacement && yOffsetTemp <= _maxYDisplacement) {
      _yOffset = yOffsetTemp;
    }

    if (xOffsetTemp >= -_maxXDisplacement && xOffsetTemp <= _maxXDisplacement) {
      _xOffset = xOffsetTemp;
    }
    notifyListeners();
  }

  /// Keep the image inside the boudaries when is applying zoom in or out
  void _updateOffsetInsideBoundaries() {
    if (!_isInsideOfYOffset && _yOffset != 0) {
      _yOffset =
          _yOffset > _maxYDisplacement ? _maxYDisplacement : -_maxYDisplacement;
    }
    if (!_isInsideOfXOffset && _xOffset != 0) {
      _xOffset =
          _xOffset > _maxXDisplacement ? _maxXDisplacement : -_maxXDisplacement;
    }
    notifyListeners();
  }
}
