import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CaseConverterScreen extends StatefulWidget {
  const CaseConverterScreen({super.key});

  @override
  State<CaseConverterScreen> createState() => _CaseConverterScreenState();
}

class _CaseConverterScreenState extends State<CaseConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _selectedConversion = 'UPPERCASE';

  final List<String> _conversionTypes = [
    'UPPERCASE',
    'lowercase',
    'Title Case',
    'Sentence case',
    'camelCase',
    'snake_case',
    'kebab-case',
    'PascalCase',
    'Alternating Case',
    'Reverse',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _convertText() {
    final input = _inputController.text;
    String output = '';

    switch (_selectedConversion) {
      case 'UPPERCASE':
        output = input.toUpperCase();
        break;
      case 'lowercase':
        output = input.toLowerCase();
        break;
      case 'Title Case':
        output = input.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
        break;
      case 'Sentence case':
        output = input.split('. ').map((sentence) {
          if (sentence.isEmpty) return sentence;
          return sentence[0].toUpperCase() + sentence.substring(1).toLowerCase();
        }).join('. ');
        break;
      case 'camelCase':
        output = input.split(' ').asMap().entries.map((entry) {
          final word = entry.value.trim();
          if (word.isEmpty) return '';
          return entry.key == 0
              ? word.toLowerCase()
              : word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join('');
        break;
      case 'snake_case':
        output = input.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        break;
      case 'kebab-case':
        output = input.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        break;
      case 'PascalCase':
        output = input.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join('');
        break;
      case 'Alternating Case':
        output = input.split('').asMap().entries.map((entry) {
          return entry.key % 2 == 0
              ? entry.value.toUpperCase()
              : entry.value.toLowerCase();
        }).join('');
        break;
      case 'Reverse':
        output = input.split('').reversed.join('');
        break;
      default:
        output = input;
    }

    setState(() {
      _outputController.text = output;
    });
  }

  void _copyOutput() {
    Clipboard.setData(ClipboardData(text: _outputController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _clearText() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearText,
            tooltip: 'Clear',
          ),
        ],
      ),
      body: Padding(
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
                      'Input Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inputController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter text to convert...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conversion Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedConversion,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: _conversionTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedConversion = newValue;
                          });
                          if (_inputController.text.isNotEmpty) {
                            _convertText();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _convertText,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Convert'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Result',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _outputController.text.isNotEmpty
                              ? _copyOutput
                              : null,
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _outputController,
                      maxLines: 5,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Converted text will appear here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
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
}
