import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  bool _isLoading = false;
  bool _hasScannedDocument = false;
  String _scannedDocumentPath = '';
  Uint8List? _webImage; // For web platform
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Skip permission check on web as it's handled differently
    if (kIsWeb) return;

    try {
      // Check camera permission on mobile platforms
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required to scan documents')),
          );
        }
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _scanDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check camera permission first
      if (!kIsWeb) {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera permission is required to scan documents')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Use image picker to open camera directly
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (photo != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await photo.readAsBytes();
          setState(() {
            _hasScannedDocument = true;
            _webImage = bytes;
            _scannedDocumentPath = photo.path; // Still store the path for consistency
          });
        } else {
          // For mobile platforms
          setState(() {
            _hasScannedDocument = true;
            _scannedDocumentPath = photo.path;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document scanning was cancelled')),
          );
        }
      }
    } catch (e) {
      print('Error scanning document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning document: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareDocument() async {
    if (!_hasScannedDocument) return;

    try {
      if (kIsWeb) {
        // For web platform, we need to handle sharing differently
        // Web doesn't support direct sharing, so we'll show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is not supported on web. Please download the image instead.')),
        );
      } else {
        // For mobile platforms
        await Share.shareXFiles(
          [XFile(_scannedDocumentPath)],
          text: 'Scanned Document',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing document: $e')),
        );
      }
    }
  }

  Future<void> _viewDocument() async {
    if (!_hasScannedDocument) return;

    try {
      if (kIsWeb) {
        // For web platform, we're already viewing the image in the UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is already displayed on screen')),
        );
      } else {
        // For mobile platforms
        await OpenFile.open(_scannedDocumentPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  Future<void> _scanNewDocument() async {
    setState(() {
      _hasScannedDocument = false;
      _scannedDocumentPath = '';
      _webImage = null;
    });
    await _scanDocument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasScannedDocument
              ? _buildScannedDocumentView()
              : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan a Document',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Capture documents, receipts, notes, or any paper document with your camera',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanDocument,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Camera to Scan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedDocumentView() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? _webImage != null
                      ? Image.memory(
                          _webImage!,
                          fit: BoxFit.contain,
                        )
                      : const Center(child: Text('No image available'))
                  : Image.file(
                      File(_scannedDocumentPath),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewDocument,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareDocument,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scanNewDocument,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('New Scan'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
