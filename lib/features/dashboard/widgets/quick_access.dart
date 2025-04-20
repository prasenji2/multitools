import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_utility_tools/core/models/tool_model.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:provider/provider.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    // Define quick access tools (most commonly used tools)
    final List<Tool> quickTools = [];

    // Find the PDF tools and document scanner first
    Tool? pdfMergerTool;
    Tool? pdfConverterTool;
    Tool? documentScannerTool;
    for (final category in toolsProvider.categories) {
      if (category.id == 'file_tools') {
        for (final tool in category.tools) {
          if (tool.id == 'pdf_merger') {
            pdfMergerTool = tool;
          } else if (tool.id == 'pdf_converter') {
            pdfConverterTool = tool;
          } else if (tool.id == 'document_scanner') {
            documentScannerTool = tool;
          }

          if (pdfMergerTool != null && pdfConverterTool != null && documentScannerTool != null) {
            break;
          }
        }
      }
      if (pdfMergerTool != null && pdfConverterTool != null && documentScannerTool != null) break;
    }

    // Add PDF tools and document scanner to quick tools if found
    if (pdfMergerTool != null) {
      quickTools.add(pdfMergerTool);
    }
    if (pdfConverterTool != null) {
      quickTools.add(pdfConverterTool);
    }
    if (documentScannerTool != null) {
      quickTools.add(documentScannerTool);
    }

    // Add tools from different categories
    for (final category in toolsProvider.categories) {
      if (category.id == 'text_tools' && category.tools.isNotEmpty) {
        quickTools.add(category.tools.first); // Word Counter
      } else if (category.id == 'image_tools' && category.tools.length > 2) {
        quickTools.add(category.tools[2]); // QR Generator
      }

      if (quickTools.length >= 4) break; // Limit to 4 quick access tools
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickTools.map((tool) => _QuickAccessItem(tool: tool)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final Tool tool;

  const _QuickAccessItem({required this.tool});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return InkWell(
      onTap: () {
        toolsProvider.addToRecent(tool);
        context.go(tool.routePath);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tool.color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                tool.icon,
                color: tool.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tool.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
