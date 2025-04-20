import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_utility_tools/core/models/tool_model.dart';
import 'package:multi_utility_tools/features/dashboard/dashboard_screen.dart';
import 'package:multi_utility_tools/features/settings/settings_screen.dart';
import 'package:multi_utility_tools/features/tools/text/word_counter_screen.dart';
import 'package:multi_utility_tools/features/tools/text/text_to_speech_screen.dart';
import 'package:multi_utility_tools/features/tools/text/case_converter_screen.dart';
import 'package:multi_utility_tools/features/tools/image/qr_generator_screen.dart';
import 'package:multi_utility_tools/features/tools/image/image_resizer_screen.dart';
import 'package:multi_utility_tools/features/tools/image/image_cropper_screen.dart';
// JSON formatter removed
import 'package:multi_utility_tools/features/tools/unit/length_converter_screen.dart';
import 'package:multi_utility_tools/features/tools/daily/bmi_calculator_screen.dart';
import 'package:multi_utility_tools/features/tools/file/pdf_converter_screen.dart';
import 'package:multi_utility_tools/features/tools/file/pdf_merger_screen.dart';
import 'package:multi_utility_tools/features/tools/file/file_compressor_screen.dart';
import 'package:multi_utility_tools/features/tools/file/document_scanner_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Text Tools
      GoRoute(
        path: '/tools/text/word-counter',
        builder: (context, state) => const WordCounterScreen(),
      ),
      GoRoute(
        path: '/tools/text/text-to-speech',
        builder: (context, state) => const TextToSpeechScreen(),
      ),
      GoRoute(
        path: '/tools/text/case-converter',
        builder: (context, state) => const CaseConverterScreen(),
      ),

      // Image Tools
      GoRoute(
        path: '/tools/image/qr-generator',
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: '/tools/image/image-resizer',
        builder: (context, state) => const ImageResizerScreen(),
      ),
      GoRoute(
        path: '/tools/image/image-cropper',
        builder: (context, state) => const ImageCropperScreen(),
      ),

      // Developer Tools
      // JSON formatter route removed

      // Unit Converters
      GoRoute(
        path: '/tools/unit/length-converter',
        builder: (context, state) => const LengthConverterScreen(),
      ),

      // Daily Use Tools
      GoRoute(
        path: '/tools/daily/bmi-calculator',
        builder: (context, state) => const BmiCalculatorScreen(),
      ),

      // File Tools
      GoRoute(
        path: '/tools/file/pdf-converter',
        builder: (context, state) => const PdfConverterScreen(),
      ),
      GoRoute(
        path: '/tools/file/pdf-merger',
        builder: (context, state) => const PdfMergerScreen(),
      ),
      GoRoute(
        path: '/tools/file/file-compressor',
        builder: (context, state) => const FileCompressorScreen(),
      ),
      GoRoute(
        path: '/tools/file/document-scanner',
        builder: (context, state) => const DocumentScannerScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Text('No route defined for ${state.uri.path}'),
      ),
    ),
  );
}
