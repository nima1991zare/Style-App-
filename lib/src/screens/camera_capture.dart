import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// In-app camera with live preview, shutter and camera flip.
/// Returns the captured photo's file path, or null if cancelled.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  static Future<String?> capture(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
  }

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _initializing = true;
  bool _taking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {
      _cameras = [];
    }
    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.\nUse "Choose from gallery" instead.';
        });
      }
      return;
    }
    // Prefer the back camera for outfit photos.
    _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _startCamera();
  }

  Future<void> _startCamera() async {
    final previous = _controller;
    _controller = null;
    if (mounted) setState(() => _initializing = true);
    await previous?.dispose();

    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
        _error = null;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = e.code == 'CameraAccessDenied'
              ? 'Camera permission was denied.\nAllow camera access in your settings.'
              : 'Could not start the camera.\nUse "Choose from gallery" instead.';
        });
      }
    }
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _initializing) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || _taking || !controller.value.isInitialized) return;
    setState(() => _taking = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (_) {
      if (mounted) {
        setState(() => _taking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take the photo. Try again.')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take a photo'),
        titleTextStyle: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _initializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.no_photography_outlined,
                                  color: Colors.white54, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : controller != null && controller.value.isInitialized
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CameraPreview(controller),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 56),
                  // Shutter
                  GestureDetector(
                    onTap: _error == null ? _shoot : null,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _taking || _error != null
                              ? Colors.white38
                              : Colors.white,
                        ),
                        child: _taking
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black54),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Flip camera
                  SizedBox(
                    width: 56,
                    child: _cameras.length > 1
                        ? IconButton(
                            onPressed: _flip,
                            icon: const Icon(Icons.flip_camera_ios_outlined,
                                color: Colors.white, size: 30),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
