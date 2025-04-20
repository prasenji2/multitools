import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WordCounterScreen extends StatefulWidget {
  const WordCounterScreen({super.key});

  @override
  State<WordCounterScreen> createState() => _WordCounterScreenState();
}

class _WordCounterScreenState extends State<WordCounterScreen> {
  final TextEditingController _textController = TextEditingController();
  int _wordCount = 0;
  int _charCount = 0;
  int _charNoSpaceCount = 0;
  int _paragraphCount = 0;
  int _sentenceCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCounts);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _textController.text;
    
    setState(() {
      // Word count
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      
      // Character count
      _charCount = text.length;
      
      // Character count without spaces
      _charNoSpaceCount = text.replaceAll(RegExp(r'\s'), '').length;
      
      // Paragraph count
      _paragraphCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\n\s*\n')).length;
      
      // Sentence count
      _sentenceCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'[.!?]+\s')).length;
    });
  }

  void _clearText() {
    _textController.clear();
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  void _pasteText() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _textController.text = clipboardData.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyText,
            tooltip: 'Copy Text',
          ),
          IconButton(
            icon: const Icon(Icons.paste),
            onPressed: _pasteText,
            tooltip: 'Paste Text',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearText,
            tooltip: 'Clear Text',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Type or paste your text here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildCountRow('Words', _wordCount),
                    const Divider(),
                    _buildCountRow('Characters', _charCount),
                    const Divider(),
                    _buildCountRow('Characters (no spaces)', _charNoSpaceCount),
                    const Divider(),
                    _buildCountRow('Paragraphs', _paragraphCount),
                    const Divider(),
                    _buildCountRow('Sentences', _sentenceCount),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
