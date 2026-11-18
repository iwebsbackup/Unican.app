import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../services/media_service.dart';
import 'geotag_data.dart';
import 'geotag_overlay.dart';

/// Composites the geo-tag badge onto the freshly captured photo and saves it
/// automatically (no manual Save step). Returns the saved PNG path through
/// `Navigator.pop`; backing out returns `null`.
class GeoTagCaptureScreen extends StatefulWidget {
  final String rawImagePath;
  final GeoTagData data;

  const GeoTagCaptureScreen({
    super.key,
    required this.rawImagePath,
    required this.data,
  });

  @override
  State<GeoTagCaptureScreen> createState() => _GeoTagCaptureScreenState();
}

class _GeoTagCaptureScreenState extends State<GeoTagCaptureScreen> {
  static const double _logicalWidth = 360;
  static const double _horizontalMargin = 12;
  static const double _bottomMargin = 14;

  final GlobalKey _boundaryKey = GlobalKey();
  final MediaService _mediaService = MediaService();

  ui.Image? _image;
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  double get _logicalHeight {
    final image = _image;
    if (image == null || image.width == 0) return _logicalWidth;
    return _logicalWidth * image.height / image.width;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.rawImagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image = frame.image;
        _loading = false;
      });
      // Auto-save once the composition has been laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) => _save());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _image == null) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Boundary unavailable');

      final ratio =
          (_image!.width / _logicalWidth).clamp(1.5, 2.5).toDouble();
      final captured = await boundary.toImage(pixelRatio: ratio);
      final byteData = await captured.toByteData(
        format: ui.ImageByteFormat.png,
      );
      captured.dispose();
      if (byteData == null) throw StateError('Encode failed');

      final path = await _mediaService.saveImageBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      if (path == null) throw StateError('Save failed');
      if (!mounted) return;
      Navigator.of(context).pop(path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the geo-tagged photo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Geo-Tagged Photo'),
        actions: [
          if (_failed && _image != null)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _image == null
              ? const Center(
                  child: Text(
                    'Photo unavailable',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Stack(
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _boundaryKey,
                          child: _composition(_image!),
                        ),
                      ),
                    ),
                    if (_saving)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _composition(ui.Image image) {
    return SizedBox(
      width: _logicalWidth,
      height: _logicalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RawImage(image: image, fit: BoxFit.cover),
          Positioned(
            left: _horizontalMargin,
            right: _horizontalMargin,
            bottom: _bottomMargin,
            child: GeoTagOverlay(data: widget.data),
          ),
        ],
      ),
    );
  }
}
