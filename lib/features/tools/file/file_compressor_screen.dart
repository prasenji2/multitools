import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

// Import web utilities if available
import 'package:multi_utility_tools/features/tools/file/web_utils_export.dart';

class FileCompressorScreen extends StatefulWidget {
  const FileCompressorScreen({super.key});

  @override
  State<FileCompressorScreen> createState() => _FileCompressorScreenState();
}

class _FileCompressorScreenState extends State<FileCompressorScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<PlatformFile> _selectedFiles = [];
  Map<String, Uint8List> _compressedFiles = {}; // Map of filename to compressed bytes
  String _outputFilePath = '';
  bool _compressionComplete = false;

  // Compression options
  int _compressionLevel = 80; // 1-100, where 100 is best quality (least compression)

  // File size info
  int _totalOriginalSize = 0;
  int _totalCompressedSize = 0;

  // Supported file types
  final Set<String> _supportedImageFormats = {
    'jpg', 'jpeg', 'png', 'gif', 'bmp'
  };

  // Track unsupported files
  List<PlatformFile> _unsupportedFiles = [];

  Future<void> _pickFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _compressionComplete = false;
      _compressedFiles.clear();
      _outputFilePath = '';
      _totalOriginalSize = 0;
      _totalCompressedSize = 0;
      _unsupportedFiles.clear();
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb, // Load file data directly on web
      );

      if (result != null && result.files.isNotEmpty) {
        final supportedFiles = <PlatformFile>[];
        final unsupportedFiles = <PlatformFile>[];

        // Filter files by supported formats
        for (final file in result.files) {
          final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');
          if (_supportedImageFormats.contains(extension)) {
            supportedFiles.add(file);
          } else {
            unsupportedFiles.add(file);
          }
        }

        setState(() {
          _selectedFiles = supportedFiles;
          _unsupportedFiles = unsupportedFiles;

          // Calculate total original size
          for (final file in _selectedFiles) {
            _totalOriginalSize += file.size;
          }
        });

        if (_unsupportedFiles.isNotEmpty) {
          setState(() {
            _errorMessage = 'Some files are not supported for compression: ' +
                _unsupportedFiles.map((f) => f.name).join(', ') +
                '\nOnly images (JPG, PNG, GIF, BMP) are supported.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking files: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _compressFiles() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _errorMessage = 'Please select files first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _compressionComplete = false;
      _compressedFiles.clear();
      _totalCompressedSize = 0;
      _outputFilePath = '';
    });

    try {
      // Process each file individually to maintain its format
      for (final file in _selectedFiles) {
        final extension = path.extension(file.name).toLowerCase().replaceAll('.', '');

        // Get file bytes
        Uint8List? fileBytes;
        if (kIsWeb) {
          fileBytes = file.bytes;
        } else if (file.path != null) {
          fileBytes = await File(file.path!).readAsBytes();
        }

        if (fileBytes == null) {
          continue; // Skip if we can't get the file bytes
        }

        // Compress the image
        if (_supportedImageFormats.contains(extension)) {
          await _compressImage(file.name, fileBytes);
        }
      }

      setState(() {
        _compressionComplete = _compressedFiles.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error compressing files: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _compressImage(String fileName, Uint8List fileBytes) async {
    try {
      // Decode the image
      final image = img.decodeImage(fileBytes);
      if (image == null) {
        throw Exception('Failed to decode image: $fileName');
      }

      // Get file extension
      final extension = path.extension(fileName).toLowerCase().replaceAll('.', '');

      // Compress the image while maintaining format
      Uint8List compressedBytes;

      // Use different compression methods based on format
      if (extension == 'jpg' || extension == 'jpeg') {
        // For JPEG, use quality parameter (0-100)
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: _compressionLevel)
        );
      } else if (extension == 'png') {
        // For PNG, use level parameter (0-9)
        final level = (9 * (100 - _compressionLevel) / 100).round(); // Convert 0-100 to 9-0
        compressedBytes = Uint8List.fromList(
          img.encodePng(image, level: level)
        );
      } else {
        // For other formats, just re-encode with default settings
        switch (extension) {
          case 'gif':
            compressedBytes = Uint8List.fromList(img.encodeGif(image));
            break;
          case 'bmp':
            compressedBytes = Uint8List.fromList(img.encodeBmp(image));
            break;
          default:
            // Default to JPEG if format not recognized
            compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: _compressionLevel));
        }
      }

      // Create a filename for the compressed file
      final baseName = path.basenameWithoutExtension(fileName);
      final compressedFileName = '${baseName}_compressed.$extension';

      // Store the compressed file
      setState(() {
        _compressedFiles[compressedFileName] = compressedBytes;
        _totalCompressedSize += compressedBytes.length;
      });

      // For native platforms, also save to a temporary file for preview
      if (!kIsWeb && _selectedFiles.length == 1) {
        final directory = await getTemporaryDirectory();
        final outputFile = File('${directory.path}/$compressedFileName');
        await outputFile.writeAsBytes(compressedBytes);

        setState(() {
          _outputFilePath = outputFile.path;
        });
      }
    } catch (e) {
      print('Error compressing image $fileName: $e');
      rethrow;
    }
  }



  Future<void> _saveCompressedFile() async {
    if (_compressedFiles.isEmpty) {
      setState(() {
        _errorMessage = 'No compressed files available to save';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_compressedFiles.length == 1) {
        // If only one file, save it directly
        final fileName = _compressedFiles.keys.first;
        final fileBytes = _compressedFiles.values.first;

        if (kIsWeb) {
          // For web, use download API
          WebUtils.downloadFile(fileBytes, fileName);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File downloaded successfully'),
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

          final savedFile = File('${directory.path}/$fileName');

          // Save the compressed file
          await savedFile.writeAsBytes(fileBytes);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File saved to ${savedFile.path}'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // If multiple files, save them to a directory
        if (kIsWeb) {
          // For web, we can only download one file at a time
          // So we'll create a dialog to let the user choose which file to download
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Select a file to download'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _compressedFiles.length,
                    itemBuilder: (context, index) {
                      final fileName = _compressedFiles.keys.elementAt(index);
                      final fileBytes = _compressedFiles.values.elementAt(index);
                      final fileSize = _formatFileSize(fileBytes.length);

                      return ListTile(
                        title: Text(fileName),
                        subtitle: Text(fileSize),
                        onTap: () {
                          Navigator.of(context).pop();
                          WebUtils.downloadFile(fileBytes, fileName);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading $fileName'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
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
          final baseDirectory = await getDownloadsDirectory() ??
                               await getExternalStorageDirectory() ??
                               await getApplicationDocumentsDirectory();

          // Create a subdirectory for the compressed files
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final dirName = 'compressed_files_$timestamp';
          final directory = Directory('${baseDirectory.path}/$dirName');
          await directory.create(recursive: true);

          // Save each file to the directory
          for (final entry in _compressedFiles.entries) {
            final fileName = entry.key;
            final fileBytes = entry.value;

            final savedFile = File('${directory.path}/$fileName');
            await savedFile.writeAsBytes(fileBytes);
          }

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Files saved to ${directory.path}'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving file(s): $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCompressedFile() async {
    if (_compressedFiles.isEmpty) {
      setState(() {
        _errorMessage = 'No compressed files available to share';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_compressedFiles.length == 1) {
        // If only one file, share it directly
        final fileName = _compressedFiles.keys.first;
        final fileBytes = _compressedFiles.values.first;

        if (kIsWeb) {
          // For web, use download API since sharing isn't well supported
          WebUtils.downloadFile(fileBytes, fileName);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File downloaded for sharing'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          // For mobile/desktop platforms
          // Create a temporary file for sharing
          final directory = await getTemporaryDirectory();
          final tempFile = File('${directory.path}/$fileName');
          await tempFile.writeAsBytes(fileBytes);

          await Share.shareXFiles(
            [XFile(tempFile.path)],
            text: 'Sharing compressed file',
          );
        }
      } else {
        // If multiple files, we need to handle differently
        if (kIsWeb) {
          // For web, we can only download one file at a time
          // So we'll create a dialog to let the user choose which file to download
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Select a file to download'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _compressedFiles.length,
                    itemBuilder: (context, index) {
                      final fileName = _compressedFiles.keys.elementAt(index);
                      final fileBytes = _compressedFiles.values.elementAt(index);
                      final fileSize = _formatFileSize(fileBytes.length);

                      return ListTile(
                        title: Text(fileName),
                        subtitle: Text(fileSize),
                        onTap: () {
                          Navigator.of(context).pop();
                          WebUtils.downloadFile(fileBytes, fileName);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading $fileName'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          }
        } else {
          // For mobile/desktop platforms
          // Create temporary files for sharing
          final directory = await getTemporaryDirectory();
          final xFiles = <XFile>[];

          for (final entry in _compressedFiles.entries) {
            final fileName = entry.key;
            final fileBytes = entry.value;

            final tempFile = File('${directory.path}/$fileName');
            await tempFile.writeAsBytes(fileBytes);
            xFiles.add(XFile(tempFile.path));
          }

          await Share.shareXFiles(
            xFiles,
            text: 'Sharing compressed files',
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing file(s): $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  double _calculateCompressionRatio() {
    if (_totalOriginalSize == 0 || _totalCompressedSize == 0) {
      return 0;
    }
    return (_totalOriginalSize - _totalCompressedSize) / _totalOriginalSize * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Compressor'),
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
                      'Compress Files',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select files to compress them into a single archive file. Supports various file formats.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Selection
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickFiles,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select Files'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Files List
            if (_selectedFiles.isNotEmpty) ...[
              Text(
                'Selected Files (${_selectedFiles.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Total Size: ${_formatFileSize(_totalOriginalSize)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.name),
                      subtitle: Text(_formatFileSize(file.size)),
                      dense: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Compression Options
              Text(
                'Compression Options',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Quality Level
              Text(
                'Quality Level: ${_compressionLevel}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Higher quality means larger file size. Lower quality means smaller file size.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: _compressionLevel.toDouble(),
                min: 10,
                max: 100,
                divisions: 9,
                label: '$_compressionLevel%',
                onChanged: (value) {
                  setState(() {
                    _compressionLevel = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Compress Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _compressFiles,
                icon: const Icon(Icons.compress),
                label: const Text('Compress Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Compression Results
            if (_compressionComplete && _compressedFiles.isNotEmpty) ...[
              const Divider(),
              Text(
                'Compression Results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Original Size:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatFileSize(_totalOriginalSize),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Compressed Size:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _formatFileSize(_totalCompressedSize),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Compression Ratio:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${_calculateCompressionRatio().toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Files Compressed:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${_compressedFiles.length}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                      onPressed: _isLoading ? null : _saveCompressedFile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _shareCompressedFile,
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
