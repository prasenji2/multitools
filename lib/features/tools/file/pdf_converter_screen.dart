import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import web utilities
import 'package:multi_utility_tools/features/tools/file/web_utils_export.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

class PdfConverterScreen extends StatefulWidget {
  const PdfConverterScreen({super.key});

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  bool _isLoading = false;
  String _selectedFileName = '';
  String _selectedFilePath = '';
  String _outputFilePath = '';
  String _fileType = '';
  String _errorMessage = '';
  bool _conversionComplete = false;

  // For web platform
  Uint8List? _selectedFileBytes;
  Uint8List? _outputFileBytes;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _conversionComplete = false;
      _outputFilePath = '';
      _outputFileBytes = null;
      _selectedFileBytes = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'doc', 'docx'],
        withData: kIsWeb, // Get file bytes for web platform
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _fileType = file.extension?.toLowerCase() ?? '';
        });

        if (kIsWeb) {
          // For web, use bytes
          if (file.bytes != null) {
            setState(() {
              _selectedFileBytes = file.bytes!;
            });
          } else {
            throw Exception('Could not get file bytes');
          }
        } else {
          // For mobile/desktop, use path
          if (file.path != null) {
            setState(() {
              _selectedFilePath = file.path!;
            });
          } else {
            throw Exception('Could not get file path');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (kIsWeb && _selectedFileBytes == null || !kIsWeb && _selectedFilePath.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _conversionComplete = false;
    });

    try {
      final result = await _performConversion();

      if (result != null) {
        setState(() {
          _conversionComplete = true;

          if (kIsWeb) {
            // For web, store bytes
            _outputFileBytes = result as Uint8List;
          } else {
            // For mobile/desktop, store file path
            _outputFilePath = (result as File).path;
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Conversion failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during conversion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _performConversion() async {
    try {
      if (kIsWeb) {
        // For web, return bytes
        switch (_fileType) {
          case 'txt':
            return await _convertTextToPdfWeb();
          case 'doc':
          case 'docx':
            return await _convertDocToPdfWeb();
          default:
            throw Exception('Unsupported file type: $_fileType');
        }
      } else {
        // For mobile/desktop, return File
        final directory = await getTemporaryDirectory();
        final outputFileName = '${_selectedFileName.split('.').first}_converted.pdf';
        final outputFile = File('${directory.path}/$outputFileName');

        switch (_fileType) {
          case 'txt':
            return await _convertTextToPdf(outputFile);
          case 'doc':
          case 'docx':
            return await _convertDocToPdf(outputFile);
          default:
            throw Exception('Unsupported file type: $_fileType');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<File> _convertTextToPdf(File outputFile) async {
    // Read the text file content
    final inputFile = File(_selectedFilePath);
    final String text = await inputFile.readAsString();

    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page to the document
    final PdfPage page = document.pages.add();

    // Create a PDF text element and draw it
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfTextElement textElement = PdfTextElement(
      text: text,
      font: font,
    );

    // Get the page client size to calculate layout
    final Size pageSize = page.getClientSize();
    final PdfLayoutResult layoutResult = textElement.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    )!;

    // Save the document
    final List<int> bytes = await document.save();

    // Dispose the document
    document.dispose();

    // Write the PDF to the output file
    await outputFile.writeAsBytes(bytes);

    return outputFile;
  }

  Future<File> _convertDocToPdf(File outputFile) async {
    try {
      // Read the DOC/DOCX file as bytes
      final inputFile = File(_selectedFilePath);
      final Uint8List bytes = await inputFile.readAsBytes();

      // Extract text from the DOC/DOCX file
      String docText = '';
      try {
        // Use docx_to_text to extract text from the document
        docText = docxToText(bytes);
      } catch (e) {
        // If text extraction fails, provide a fallback message
        docText = 'Could not extract text from the document. The file may be corrupted or in an unsupported format.';
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Add a page to the document
      final PdfPage page = document.pages.add();

      // Create PDF font for document content
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

      // Add document content directly without title and file information
      if (docText.isNotEmpty) {
        final PdfTextElement contentElement = PdfTextElement(
          text: docText,
          font: regularFont,
        );

        contentElement.draw(
          page: page,
          bounds: Rect.fromLTWH(
            0,
            0, // Start from the top of the page
            page.getClientSize().width,
            page.getClientSize().height
          ),
        );
      } else {
        // If no text was extracted, show a message
        final PdfTextElement noContentElement = PdfTextElement(
          text: 'No text content could be extracted from this document.',
          font: regularFont,
        );

        noContentElement.draw(
          page: page,
          bounds: Rect.fromLTWH(
            0,
            0, // Start from the top of the page
            page.getClientSize().width,
            page.getClientSize().height
          ),
        );
      }

      // Save the document
      final List<int> pdfBytes = await document.save();

      // Dispose the document
      document.dispose();

      // Write the PDF to the output file
      await outputFile.writeAsBytes(pdfBytes);

      return outputFile;
    } catch (e) {
      // If an error occurs, create a simple error PDF
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

      // Add error information without title
      final PdfTextElement errorElement = PdfTextElement(
        text: 'An error occurred while converting the document:\n\n$e',
        font: regularFont,
      );

      errorElement.draw(
        page: page,
        bounds: Rect.fromLTWH(
          0,
          0, // Start from the top of the page
          page.getClientSize().width,
          page.getClientSize().height
        ),
      );

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();
      await outputFile.writeAsBytes(bytes);
      return outputFile;
    }
  }

  // Web platform conversion methods
  Future<Uint8List> _convertTextToPdfWeb() async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page to the document
    final PdfPage page = document.pages.add();

    // Create a PDF text element and draw it
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);

    // Convert bytes to string for text files
    final String text = String.fromCharCodes(_selectedFileBytes!);

    final PdfTextElement textElement = PdfTextElement(
      text: text,
      font: font,
    );

    // Get the page client size to calculate layout
    final Size pageSize = page.getClientSize();
    textElement.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );

    // Save the document
    final List<int> bytes = await document.save();

    // Dispose the document
    document.dispose();

    // Return the PDF bytes
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> _convertDocToPdfWeb() async {
    try {
      // Extract text from the DOC/DOCX file
      String docText = '';
      try {
        // Use docx_to_text to extract text from the document
        if (_selectedFileBytes != null) {
          docText = docxToText(_selectedFileBytes!);
        }
      } catch (e) {
        // If text extraction fails, provide a fallback message
        docText = 'Could not extract text from the document. The file may be corrupted or in an unsupported format.';
      }

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      // Add a page to the document
      final PdfPage page = document.pages.add();

      // Create PDF font for document content
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

      // Add document content directly without title and file information
      if (docText.isNotEmpty) {
        final PdfTextElement contentElement = PdfTextElement(
          text: docText,
          font: regularFont,
        );

        contentElement.draw(
          page: page,
          bounds: Rect.fromLTWH(
            0,
            0, // Start from the top of the page
            page.getClientSize().width,
            page.getClientSize().height
          ),
        );
      } else {
        // If no text was extracted, show a message
        final PdfTextElement noContentElement = PdfTextElement(
          text: 'No text content could be extracted from this document.',
          font: regularFont,
        );

        noContentElement.draw(
          page: page,
          bounds: Rect.fromLTWH(
            0,
            0, // Start from the top of the page
            page.getClientSize().width,
            page.getClientSize().height
          ),
        );
      }

      // Save the document
      final List<int> pdfBytes = await document.save();

      // Dispose the document
      document.dispose();

      // Return the PDF bytes
      return Uint8List.fromList(pdfBytes);
    } catch (e) {
      // If an error occurs, create a simple error PDF
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

      // Add error information without title
      final PdfTextElement errorElement = PdfTextElement(
        text: 'An error occurred while converting the document:\n\n$e',
        font: regularFont,
      );

      errorElement.draw(
        page: page,
        bounds: Rect.fromLTWH(
          0,
          0, // Start from the top of the page
          page.getClientSize().width,
          page.getClientSize().height
        ),
      );

      // Save the document
      final List<int> bytes = await document.save();
      document.dispose();
      return Uint8List.fromList(bytes);
    }
  }

  Future<void> _saveFile() async {
    if (!kIsWeb && _outputFilePath.isEmpty || kIsWeb && _outputFileBytes == null) {
      setState(() {
        _errorMessage = 'No converted file to save';
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
        final fileName = '${_selectedFileName.split('.').first}_converted.pdf';
        WebUtils.downloadFile(_outputFileBytes!, fileName);

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

        final fileName = '${_selectedFileName.split('.').first}_converted.pdf';
        final savedFile = File('${directory.path}/$fileName');

        // Copy the converted file to the downloads directory
        await File(_outputFilePath).copy(savedFile.path);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to ${savedFile.path}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => OpenFile.open(savedFile.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareFile() async {
    if (!kIsWeb && _outputFilePath.isEmpty || kIsWeb && _outputFileBytes == null) {
      setState(() {
        _errorMessage = 'No converted file to share';
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
        final fileName = '${_selectedFileName.split('.').first}_converted.pdf';
        WebUtils.downloadFile(_outputFileBytes!, fileName);

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
        await Share.shareXFiles(
          [XFile(_outputFilePath)],
          text: 'Sharing converted PDF file',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing file: $e';
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
        title: const Text('PDF Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select File',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a TXT, DOC, or DOCX file to convert to PDF',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedFileName.isNotEmpty
                              ? Text(
                                  _selectedFileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const Text(
                                  'No file selected',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Browse'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conversion Button
            ElevatedButton.icon(
              onPressed: _isLoading ||
                        (kIsWeb ? _selectedFileBytes == null : _selectedFilePath.isEmpty)
                        ? null : _convertToPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Convert to PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing...'),
                  ],
                ),
              ),

            // Error Message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade900,
                  ),
                ),
              ),

            // Conversion Complete Actions
            if (_conversionComplete)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Conversion Complete!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'What would you like to do with the converted PDF?',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveFile,
                              icon: const Icon(Icons.save),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _shareFile,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported File Types',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFileTypeInfo(
                      'TXT',
                      'Text files will be converted with their original content preserved.',
                      Icons.text_fields,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildFileTypeInfo(
                      'DOC/DOCX',
                      'Word documents will be converted to PDF format.',
                      Icons.description,
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeInfo(
    String type,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
