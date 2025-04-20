import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

// Import web utilities if available
import 'package:multi_utility_tools/features/tools/file/web_utils_export.dart';

class ImageResizerScreen extends StatefulWidget {
  const ImageResizerScreen({super.key});

  @override
  State<ImageResizerScreen> createState() => _ImageResizerScreenState();
}

class _ImageResizerScreenState extends State<ImageResizerScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  Uint8List? _selectedImageBytes;
  Uint8List? _resizedImageBytes;
  String _selectedImageName = '';
  String _outputFilePath = '';
  bool _resizeComplete = false;
  
  // Resize options
  double _customWidth = 800;
  double _customHeight = 600;
  bool _maintainAspectRatio = true;
  double _quality = 80; // 0-100
  
  // Preset sizes
  final List<Map<String, dynamic>> _presetSizes = [
    {'name': 'Small (480 × 360)', 'width': 480.0, 'height': 360.0},
    {'name': 'Medium (800 × 600)', 'width': 800.0, 'height': 600.0},
    {'name': 'Large (1280 × 960)', 'width': 1280.0, 'height': 960.0},
    {'name': 'HD (1280 × 720)', 'width': 1280.0, 'height': 720.0},
    {'name': 'Full HD (1920 × 1080)', 'width': 1920.0, 'height': 1080.0},
    {'name': '4K (3840 × 2160)', 'width': 3840.0, 'height': 2160.0},
    {'name': 'Social Media (1200 × 630)', 'width': 1200.0, 'height': 630.0},
    {'name': 'Instagram Post (1080 × 1080)', 'width': 1080.0, 'height': 1080.0},
    {'name': 'Instagram Story (1080 × 1920)', 'width': 1080.0, 'height': 1920.0},
    {'name': 'Twitter Header (1500 × 500)', 'width': 1500.0, 'height': 500.0},
    {'name': 'Facebook Cover (851 × 315)', 'width': 851.0, 'height': 315.0},
    {'name': 'LinkedIn Cover (1584 × 396)', 'width': 1584.0, 'height': 396.0},
  ];
  
  // Selected preset index
  int _selectedPresetIndex = -1; // -1 means custom size
  
  // Original image dimensions
  double? _originalWidth;
  double? _originalHeight;
  double? _aspectRatio;

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _resizeComplete = false;
      _resizedImageBytes = null;
      _outputFilePath = '';
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
            _aspectRatio = _originalWidth! / _originalHeight!;
            
            // Reset custom dimensions to match original aspect ratio
            _customWidth = 800;
            _customHeight = _maintainAspectRatio 
                ? 800 / _aspectRatio!
                : 600;
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

  Future<void> _resizeImage() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _resizeComplete = false;
    });

    try {
      // Get target dimensions
      int targetWidth = _customWidth.round();
      int targetHeight = _customHeight.round();
      
      // Decode the image
      final decodedImage = img.decodeImage(_selectedImageBytes!);
      
      if (decodedImage == null) {
        throw Exception('Failed to decode the image');
      }
      
      // Resize the image
      final resizedImage = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );
      
      // Encode the image with the specified quality
      final encodedImage = img.encodeJpg(resizedImage, quality: _quality.round());
      
      // Convert to Uint8List
      final resizedBytes = Uint8List.fromList(encodedImage);
      
      if (!kIsWeb) {
        // For mobile/desktop platforms, save to temporary file
        final directory = await getTemporaryDirectory();
        final outputFileName = 'resized_${_selectedImageName}';
        final outputFile = File('${directory.path}/$outputFileName');
        await outputFile.writeAsBytes(resizedBytes);
        
        setState(() {
          _resizedImageBytes = resizedBytes;
          _outputFilePath = outputFile.path;
          _resizeComplete = true;
        });
      } else {
        // For web, just store the bytes
        setState(() {
          _resizedImageBytes = resizedBytes;
          _resizeComplete = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error resizing image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_resizedImageBytes == null) {
      setState(() {
        _errorMessage = 'No resized image available to save';
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
        WebUtils.downloadFile(_resizedImageBytes!, 'resized_${_selectedImageName}');

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

        final fileName = 'resized_${_selectedImageName}';
        final savedFile = File('${directory.path}/$fileName');

        // Save the resized image
        await savedFile.writeAsBytes(_resizedImageBytes!);

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
    if (_resizedImageBytes == null) {
      setState(() {
        _errorMessage = 'No resized image available to share';
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
        WebUtils.downloadFile(_resizedImageBytes!, 'resized_${_selectedImageName}');

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
        final fileName = 'resized_${_selectedImageName}';
        final tempFile = File('${directory.path}/$fileName');
        await tempFile.writeAsBytes(_resizedImageBytes!);
        
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Sharing resized image',
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

  void _updateCustomHeight() {
    if (_maintainAspectRatio && _aspectRatio != null) {
      setState(() {
        _customHeight = _customWidth / _aspectRatio!;
      });
    }
  }

  void _updateCustomWidth() {
    if (_maintainAspectRatio && _aspectRatio != null) {
      setState(() {
        _customWidth = _customHeight * _aspectRatio!;
      });
    }
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      if (index >= 0) {
        _customWidth = _presetSizes[index]['width'];
        _customHeight = _presetSizes[index]['height'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Resizer'),
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
                      'Resize Images',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an image and choose from preset sizes or enter custom dimensions.',
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

            // Selected Image Preview
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
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preset Sizes
              Text(
                'Preset Sizes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Custom size chip
                  ChoiceChip(
                    label: const Text('Custom Size'),
                    selected: _selectedPresetIndex == -1,
                    onSelected: (selected) {
                      if (selected) {
                        _selectPreset(-1);
                      }
                    },
                  ),
                  // Preset size chips
                  for (int i = 0; i < _presetSizes.length; i++)
                    ChoiceChip(
                      label: Text(_presetSizes[i]['name']),
                      selected: _selectedPresetIndex == i,
                      onSelected: (selected) {
                        if (selected) {
                          _selectPreset(i);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Custom Size Controls
              if (_selectedPresetIndex == -1) ...[
                Text(
                  'Custom Size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Width (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: _customWidth.round().toString()),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _customWidth = double.parse(value);
                              _updateCustomHeight();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Height (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: _customHeight.round().toString()),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _customHeight = double.parse(value);
                              _updateCustomWidth();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _maintainAspectRatio,
                      onChanged: (value) {
                        setState(() {
                          _maintainAspectRatio = value ?? true;
                          if (_maintainAspectRatio) {
                            _updateCustomHeight();
                          }
                        });
                      },
                    ),
                    const Text('Maintain aspect ratio'),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Quality Slider
              Text(
                'Quality: ${_quality.round()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _quality,
                min: 10,
                max: 100,
                divisions: 9,
                label: '${_quality.round()}%',
                onChanged: (value) {
                  setState(() {
                    _quality = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Resize Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _resizeImage,
                icon: const Icon(Icons.photo_size_select_large),
                label: const Text('Resize Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Resized Image Preview
            if (_resizedImageBytes != null && _resizeComplete) ...[
              const Divider(),
              Text(
                'Resized Image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'New Size: ${_customWidth.round()} × ${_customHeight.round()} pixels',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.memory(
                    _resizedImageBytes!,
                    fit: BoxFit.contain,
                    height: 200,
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
