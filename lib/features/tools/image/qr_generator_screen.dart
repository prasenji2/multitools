import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final TextEditingController _dataController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  
  String _qrData = '';
  QrDataModuleShape _moduleShape = QrDataModuleShape.square;
  QrEyeShape _eyeShape = QrEyeShape.square;
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _size = 200;
  bool _isLoading = false;

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    setState(() {
      _qrData = _dataController.text;
    });
  }

  Future<void> _shareQrCode() async {
    if (_qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a QR code first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Capture QR code as image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_code.png');
        await file.writeAsBytes(pngBytes);
        
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QR Code for: $_qrData',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR code: $e')),
      );
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
        title: const Text('QR Code Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _qrData.isNotEmpty ? _shareQrCode : null,
            tooltip: 'Share QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Data',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dataController,
                      decoration: InputDecoration(
                        hintText: 'Text, URL, or any data...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _dataController.text.isNotEmpty ? _generateQrCode : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Generate QR Code'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_qrData.isNotEmpty) ...[
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: _size,
                    backgroundColor: _backgroundColor,
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: _moduleShape,
                      color: _qrColor,
                    ),
                    eyeStyle: QrEyeStyle(
                      eyeShape: _eyeShape,
                      color: _qrColor,
                    ),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customize QR Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('QR Size'),
                      Slider(
                        value: _size,
                        min: 100,
                        max: 300,
                        divisions: 10,
                        label: _size.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _size = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Module Shape'),
                      DropdownButton<QrDataModuleShape>(
                        value: _moduleShape,
                        isExpanded: true,
                        onChanged: (QrDataModuleShape? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _moduleShape = newValue;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: QrDataModuleShape.square,
                            child: Text('Square'),
                          ),
                          DropdownMenuItem(
                            value: QrDataModuleShape.circle,
                            child: Text('Circle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Eye Shape'),
                      DropdownButton<QrEyeShape>(
                        value: _eyeShape,
                        isExpanded: true,
                        onChanged: (QrEyeShape? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _eyeShape = newValue;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: QrEyeShape.square,
                            child: Text('Square'),
                          ),
                          DropdownMenuItem(
                            value: QrEyeShape.circle,
                            child: Text('Circle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('QR Color'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final Color? color = await showDialog<Color>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Select QR Color'),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              color: _qrColor,
                                              onColorChanged: (Color color) {
                                                Navigator.of(context).pop(color);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    if (color != null) {
                                      setState(() {
                                        _qrColor = color;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _qrColor,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Background Color'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final Color? color = await showDialog<Color>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Select Background Color'),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              color: _backgroundColor,
                                              onColorChanged: (Color color) {
                                                Navigator.of(context).pop(color);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    if (color != null) {
                                      setState(() {
                                        _backgroundColor = color;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _backgroundColor,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((Color c) {
        return GestureDetector(
          onTap: () => onColorChanged(c),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              border: Border.all(
                color: c == color ? Colors.blue : Colors.grey,
                width: c == color ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }).toList(),
    );
  }
}
