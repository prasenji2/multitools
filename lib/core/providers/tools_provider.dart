import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToolsProvider extends ChangeNotifier {
  List<ToolCategory> _categories = [];
  List<Tool> _favoriteTools = [];
  List<Tool> _recentTools = [];

  List<ToolCategory> get categories => _categories;
  List<Tool> get favoriteTools => _favoriteTools;
  List<Tool> get recentTools => _recentTools;

  ToolsProvider() {
    _initializeTools();
    _loadFavorites();
    _loadRecentTools();
  }

  void _initializeTools() {
    // Text Tools
    final textTools = ToolCategory(
      id: 'text_tools',
      name: 'Text Tools',
      icon: Icons.text_fields,
      tools: [
        Tool(
          id: 'word_counter',
          name: 'Word Counter',
          description: 'Count words, characters, and paragraphs in your text',
          icon: Icons.format_list_numbered,
          color: Colors.blue,
          worksOffline: true,
          routePath: '/tools/text/word-counter',
        ),
        Tool(
          id: 'text_to_speech',
          name: 'Text to Speech',
          description: 'Convert your text to spoken words',
          icon: Icons.record_voice_over,
          color: Colors.orange,
          worksOffline: false,
          routePath: '/tools/text/text-to-speech',
        ),
        Tool(
          id: 'case_converter',
          name: 'Case Converter',
          description: 'Convert text between different cases',
          icon: Icons.text_format,
          color: Colors.purple,
          worksOffline: true,
          routePath: '/tools/text/case-converter',
        ),
      ],
    );

    // Image Tools
    final imageTools = ToolCategory(
      id: 'image_tools',
      name: 'Image Tools',
      icon: Icons.image,
      tools: [
        Tool(
          id: 'image_resizer',
          name: 'Image Resizer',
          description: 'Resize your images to specific dimensions',
          icon: Icons.photo_size_select_large,
          color: Colors.green,
          worksOffline: true,
          routePath: '/tools/image/image-resizer',
        ),
        Tool(
          id: 'image_to_pdf',
          name: 'Image to PDF',
          description: 'Convert images to PDF documents',
          icon: Icons.picture_as_pdf,
          color: Colors.red,
          worksOffline: true,
          routePath: '/tools/image/image-to-pdf',
        ),
        Tool(
          id: 'qr_generator',
          name: 'QR Code Generator',
          description: 'Generate QR codes from text or URLs',
          icon: Icons.qr_code,
          color: Colors.black,
          worksOffline: true,
          routePath: '/tools/image/qr-generator',
        ),
        Tool(
          id: 'image_cropper',
          name: 'Crop Image',
          description: 'Crop images with preset sizes like passport, stamp, etc.',
          icon: Icons.crop,
          color: Colors.purple,
          worksOffline: true,
          routePath: '/tools/image/image-cropper',
        ),
      ],
    );

    // File Tools
    final fileTools = ToolCategory(
      id: 'file_tools',
      name: 'File Tools',
      icon: Icons.folder,
      tools: [
        // Include both PDF tools
        Tool(
          id: 'pdf_converter',
          name: 'PDF Converter',
          description: 'Convert TXT, DOC, and DOCX files to PDF',
          icon: Icons.picture_as_pdf,
          color: Colors.red,
          isPremium: false,
          worksOffline: true,
          routePath: '/tools/file/pdf-converter',
        ),
        Tool(
          id: 'pdf_merger',
          name: 'PDF Merger',
          description: 'Merge multiple PDF files into one document',
          icon: Icons.merge_type,
          color: Colors.purple,
          worksOffline: true,
          routePath: '/tools/file/pdf-merger',
        ),
        Tool(
          id: 'file_compressor',
          name: 'File Compressor',
          description: 'Compress files of any format to reduce size',
          icon: Icons.compress,
          color: Colors.blue,
          worksOffline: true,
          routePath: '/tools/file/file-compressor',
        ),
        Tool(
          id: 'document_scanner',
          name: 'Document Scanner',
          description: 'Scan documents using your camera',
          icon: Icons.document_scanner,
          color: Colors.green,
          worksOffline: true,
          routePath: '/tools/file/document-scanner',
        ),
      ],
    );

    // Developer Tools
    final devTools = ToolCategory(
      id: 'dev_tools',
      name: 'Developer Tools',
      icon: Icons.code,
      tools: [
        // JSON formatter removed
        Tool(
          id: 'base64',
          name: 'Base64 Encoder/Decoder',
          description: 'Encode or decode Base64 strings',
          icon: Icons.transform,
          color: Colors.deepPurple,
          worksOffline: true,
          routePath: '/tools/dev/base64',
        ),
        Tool(
          id: 'color_picker',
          name: 'Color Picker',
          description: 'Pick and convert colors between formats',
          icon: Icons.color_lens,
          color: Colors.pink,
          worksOffline: true,
          routePath: '/tools/dev/color-picker',
        ),
      ],
    );

    // Finance Tools
    final financeTools = ToolCategory(
      id: 'finance_tools',
      name: 'Finance Tools',
      icon: Icons.attach_money,
      tools: [
        Tool(
          id: 'loan_calculator',
          name: 'Loan Calculator',
          description: 'Calculate loan payments and interest',
          icon: Icons.calculate,
          color: Colors.green,
          worksOffline: true,
          routePath: '/tools/finance/loan-calculator',
        ),
        Tool(
          id: 'currency_converter',
          name: 'Currency Converter',
          description: 'Convert between different currencies',
          icon: Icons.currency_exchange,
          color: Colors.amber,
          worksOffline: false,
          routePath: '/tools/finance/currency-converter',
        ),
      ],
    );

    // Unit Converters
    final unitConverters = ToolCategory(
      id: 'unit_converters',
      name: 'Unit Converters',
      icon: Icons.swap_horiz,
      tools: [
        Tool(
          id: 'length_converter',
          name: 'Length Converter',
          description: 'Convert between different length units',
          icon: Icons.straighten,
          color: Colors.blue,
          worksOffline: true,
          routePath: '/tools/unit/length-converter',
        ),
        Tool(
          id: 'weight_converter',
          name: 'Weight Converter',
          description: 'Convert between different weight units',
          icon: Icons.fitness_center,
          color: Colors.brown,
          worksOffline: true,
          routePath: '/tools/unit/weight-converter',
        ),
        Tool(
          id: 'temperature_converter',
          name: 'Temperature Converter',
          description: 'Convert between different temperature units',
          icon: Icons.thermostat,
          color: Colors.red,
          worksOffline: true,
          routePath: '/tools/unit/temperature-converter',
        ),
        Tool(
          id: 'speed_converter',
          name: 'Speed Converter',
          description: 'Convert between different speed units',
          icon: Icons.speed,
          color: Colors.orange,
          worksOffline: true,
          routePath: '/tools/unit/speed-converter',
        ),
      ],
    );

    // Daily Use Tools
    final dailyTools = ToolCategory(
      id: 'daily_tools',
      name: 'Daily Use Tools',
      icon: Icons.calendar_today,
      tools: [
        Tool(
          id: 'age_calculator',
          name: 'Age Calculator',
          description: 'Calculate age between two dates',
          icon: Icons.cake,
          color: Colors.pink,
          worksOffline: true,
          routePath: '/tools/daily/age-calculator',
        ),
        Tool(
          id: 'bmi_calculator',
          name: 'BMI Calculator',
          description: 'Calculate Body Mass Index',
          icon: Icons.monitor_weight,
          color: Colors.teal,
          worksOffline: true,
          routePath: '/tools/daily/bmi-calculator',
        ),
        Tool(
          id: 'stopwatch',
          name: 'Stopwatch',
          description: 'Time events with precision',
          icon: Icons.timer,
          color: Colors.deepOrange,
          worksOffline: true,
          routePath: '/tools/daily/stopwatch',
        ),
        Tool(
          id: 'notes',
          name: 'Notes',
          description: 'Take and save quick notes',
          icon: Icons.note,
          color: Colors.amber,
          worksOffline: true,
          routePath: '/tools/daily/notes',
        ),
      ],
    );

    _categories = [
      textTools,
      imageTools,
      fileTools,
      devTools,
      financeTools,
      unitConverters,
      dailyTools,
    ];
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favoriteTools') ?? [];

    _favoriteTools = [];
    for (final category in _categories) {
      for (final tool in category.tools) {
        if (favoriteIds.contains(tool.id)) {
          _favoriteTools.add(tool);
        }
      }
    }
    notifyListeners();
  }

  Future<void> _loadRecentTools() async {
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recentTools') ?? [];

    _recentTools = [];
    for (final id in recentIds) {
      final tool = _findToolById(id);
      if (tool != null) {
        _recentTools.add(tool);
      }
    }
    notifyListeners();
  }

  Tool? _findToolById(String id) {
    for (final category in _categories) {
      for (final tool in category.tools) {
        if (tool.id == id) {
          return tool;
        }
      }
    }
    return null;
  }

  Future<void> toggleFavorite(Tool tool) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favoriteTools') ?? [];

    if (_favoriteTools.any((t) => t.id == tool.id)) {
      _favoriteTools.removeWhere((t) => t.id == tool.id);
      favoriteIds.remove(tool.id);
    } else {
      _favoriteTools.add(tool);
      favoriteIds.add(tool.id);
    }

    await prefs.setStringList('favoriteTools', favoriteIds);
    notifyListeners();
  }

  bool isFavorite(Tool tool) {
    return _favoriteTools.any((t) => t.id == tool.id);
  }

  Future<void> addToRecent(Tool tool) async {
    final prefs = await SharedPreferences.getInstance();
    final recentIds = prefs.getStringList('recentTools') ?? [];

    // Remove if already exists to avoid duplicates
    _recentTools.removeWhere((t) => t.id == tool.id);
    recentIds.remove(tool.id);

    // Add to the beginning of the list
    _recentTools.insert(0, tool);
    recentIds.insert(0, tool.id);

    // Limit to 10 recent tools
    if (_recentTools.length > 10) {
      _recentTools = _recentTools.sublist(0, 10);
    }
    if (recentIds.length > 10) {
      final limitedIds = recentIds.sublist(0, 10);
      recentIds.clear();
      recentIds.addAll(limitedIds);
    }

    await prefs.setStringList('recentTools', recentIds);
    notifyListeners();
  }

  List<Tool> searchTools(String query) {
    if (query.isEmpty) {
      return [];
    }

    final results = <Tool>[];
    for (final category in _categories) {
      for (final tool in category.tools) {
        if (tool.name.toLowerCase().contains(query.toLowerCase()) ||
            tool.description.toLowerCase().contains(query.toLowerCase())) {
          results.add(tool);
        }
      }
    }
    return results;
  }
}
