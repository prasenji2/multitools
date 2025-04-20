import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crop_your_image/crop_your_image.dart';

// Import web utilities if available
import 'package:multi_utility_tools/features/tools/file/web_utils_export.dart';

class ImageCropperScreen extends StatefulWidget {
  const ImageCropperScreen({super.key});

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  Uint8List? _selectedImageBytes;
  Uint8List? _croppedImageBytes;
  String _selectedImageName = '';
  String _outputFilePath = '';
  bool _cropComplete = false;
  
  // Crop controller
  final CropController _cropController = CropController();
  
  // Original image dimensions
  double? _originalWidth;
  double? _originalHeight;
  
  // Crop area
  Rect? _cropRect;
  
  // Preset crop sizes
  final List<Map<String, dynamic>> _presetSizes = [
    {'name': 'Custom', 'width': 0.0, 'height': 0.0, 'description': 'Crop freely'},
    {'name': 'Square (1:1)', 'width': 1.0, 'height': 1.0, 'description': 'Perfect for profile pictures'},
    {'name': 'Passport Photo (35×45mm)', 'width': 35.0, 'height': 45.0, 'description': 'Standard passport size'},
    {'name': 'ID Photo (2×2 inch)', 'width': 2.0, 'height': 2.0, 'description': 'Common ID photo size'},
    {'name': 'Visa Photo (2×2 inch)', 'width': 2.0, 'height': 2.0, 'description': 'Standard visa photo size'},
    {'name': 'Postage Stamp (0.87×0.98 inch)', 'width': 0.87, 'height': 0.98, 'description': 'Standard postage stamp size'},
    {'name': 'Instagram (1:1)', 'width': 1.0, 'height': 1.0, 'description': 'Square format for Instagram posts'},
    {'name': 'Facebook Cover (851×315)', 'width': 851.0, 'height': 315.0, 'description': 'Facebook cover photo'},
    {'name': 'Twitter Header (1500×500)', 'width': 1500.0, 'height': 500.0, 'description': 'Twitter header image'},
    {'name': 'LinkedIn Cover (1584×396)', 'width': 1584.0, 'height': 396.0, 'description': 'LinkedIn cover photo'},
    {'name': 'YouTube Thumbnail (1280×720)', 'width': 1280.0, 'height': 720.0, 'description': 'YouTube video thumbnail'},
    {'name': 'A4 Paper (210×297mm)', 'width': 210.0, 'height': 297.0, 'description': 'Standard A4 paper size'},
    {'name': 'Business Card (3.5×2 inch)', 'width': 3.5, 'height': 2.0, 'description': 'Standard business card size'},
  ];
  
  // Selected preset index
  int _selectedPresetIndex = 0; // 0 means custom/free crop
  
  // Crop aspect ratio
  double? _aspectRatio;

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _cropComplete = false;
      _croppedImageBytes = null;
      _outputFilePath = '';
      _cropRect = null;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        Uint8List imageBytes;
        
        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
        } else {
          final File imageFile = File(image.path);
          imageBytes = await imageFile.readAsBytes();
        }
        
        // Decode the image to get dimensions
        final decodedImage = img.decodeImage(imageBytes);
        
        if (decodedImage != null) {
          setState(() {
            _selectedImageBytes = imageBytes;
            _selectedImageName = image.name;
            _originalWidth = decodedImage.width.toDouble();
            _originalHeight = decodedImage.height.toDouble();
            
            // Reset crop area
            _cropRect = null;
            
            // Reset aspect ratio based on selected preset
            _updateAspectRatio();
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to decode the selected image.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateAspectRatio() {
    if (_selectedPresetIndex == 0) {
      // Custom/free crop
      setState(() {
        _aspectRatio = null;
      });
    } else {
      final preset = _presetSizes[_selectedPresetIndex];
      final width = preset['width'] as double;
      final height = preset['height'] as double;
      
      if (width > 0 && height > 0) {
        setState(() {
          _aspectRatio = width / height;
        });
      } else {
        setState(() {
          _aspectRatio = null;
        });
      }
    }
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _updateAspectRatio();
    });
  }

  void _cropImage() {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Trigger the crop operation
    _cropController.crop();
  }

  Future<void> _saveImage() async {
    if (_croppedImageBytes == null) {
      setState(() {
        _errorMessage = 'No cropped image available to save';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (kIsWeb) {
        // For web, use download API
        WebUtils.downloadFile(_croppedImageBytes!, 'cropped_${_selectedImageName}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // For mobile/desktop platforms
        // Request storage permission
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }

        // Get the downloads directory
        final directory = await getDownloadsDirectory() ??
                          await getExternalStorageDirectory() ??
                          await getApplicationDocumentsDirectory();

        final fileName = 'cropped_${_selectedImageName}';
        final savedFile = File('${directory.path}/$fileName');

        // Save the cropped image
        await savedFile.writeAsBytes(_croppedImageBytes!);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to ${savedFile.path}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareImage() async {
    if (_croppedImageBytes == null) {
      setState(() {
        _errorMessage = 'No cropped image available to share';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (kIsWeb) {
        // For web, we'll use the same download approach as save
        // since direct sharing isn't well supported across browsers
        WebUtils.downloadFile(_croppedImageBytes!, 'cropped_${_selectedImageName}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded for sharing'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        // For mobile/desktop platforms
        // Create a temporary file for sharing
        final directory = await getTemporaryDirectory();
        final fileName = 'cropped_${_selectedImageName}';
        final tempFile = File('${directory.path}/$fileName');
        await tempFile.writeAsBytes(_croppedImageBytes!);
        
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Sharing cropped image',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Images',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an image and choose from preset crop sizes or crop freely.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Selection
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Image and Crop Area
            if (_selectedImageBytes != null) ...[
              Text(
                'Selected Image: $_selectedImageName',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Original Size: ${_originalWidth?.round() ?? 0} × ${_originalHeight?.round() ?? 0} pixels',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Preset Crop Sizes
              Text(
                'Preset Crop Sizes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetSizes.length,
                  itemBuilder: (context, index) {
                    final preset = _presetSizes[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => _selectPreset(index),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedPresetIndex == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: _selectedPresetIndex == index ? 2.0 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                preset['name'],
                                style: TextStyle(
                                  fontWeight: _selectedPresetIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedPresetIndex == index
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset['description'],
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Crop Widget
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Crop(
                    image: _selectedImageBytes!,
                    controller: _cropController,
                    aspectRatio: _aspectRatio,
                    onCropped: (croppedData) {
                      setState(() {
                        _croppedImageBytes = croppedData;
                        _cropComplete = true;
                        _isLoading = false;
                      });
                    },
                    initialSize: 0.8,
                    withCircleUi: false,
                    maskColor: Colors.black.withOpacity(0.6),
                    cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
                    interactive: true,
                    fixArea: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Crop Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _cropImage,
                icon: const Icon(Icons.crop),
                label: const Text('Crop Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cropped Image Preview
            if (_croppedImageBytes != null && _cropComplete) ...[
              const Divider(),
              Text(
                'Cropped Image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.memory(
                    _croppedImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Save/Share)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveImage,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _shareImage,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],

            // Error Message
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Center(child: Text('Processing...')),
            ],
          ],
        ),
      ),
    );
  }
}
