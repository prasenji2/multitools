import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multi_utility_tools/core/models/tool_model.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:multi_utility_tools/features/dashboard/dashboard_screen.dart';
import 'package:provider/provider.dart';

class FeaturedTools extends StatelessWidget {
  const FeaturedTools({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    // Get tools for featured section
    final featuredTools = <Tool>[];

    // Add specific tools we want to feature
    Tool? pdfMergerTool;
    Tool? pdfConverterTool;
    Tool? imageCropperTool;
    Tool? imageResizerTool;
    Tool? fileCompressorTool;
    Tool? documentScannerTool;

    // First, find the specific tools we want to feature
    for (final category in toolsProvider.categories) {
      if (category.id == 'file_tools') {
        for (final tool in category.tools) {
          if (tool.id == 'pdf_merger') {
            pdfMergerTool = tool;
          } else if (tool.id == 'pdf_converter') {
            pdfConverterTool = tool;
          } else if (tool.id == 'file_compressor') {
            fileCompressorTool = tool;
          } else if (tool.id == 'document_scanner') {
            documentScannerTool = tool;
          }
        }
      } else if (category.id == 'image_tools') {
        for (final tool in category.tools) {
          if (tool.id == 'image_cropper') {
            imageCropperTool = tool;
          } else if (tool.id == 'image_resizer') {
            imageResizerTool = tool;
          }
        }
      }
    }

    // Then get one tool from each category
    for (final category in toolsProvider.categories) {
      if (category.id != 'file_tools' && category.id != 'image_tools' && category.tools.isNotEmpty) {
        // Add the first tool from each category (except file_tools and image_tools)
        featuredTools.add(category.tools.first);
      }
      if (featuredTools.length >= 3) break; // Limit to 3 tools from other categories
    }

    // Add specific tools to the featured tools if found
    if (pdfMergerTool != null) {
      featuredTools.add(pdfMergerTool);
    }
    if (pdfConverterTool != null) {
      featuredTools.add(pdfConverterTool);
    }
    if (imageCropperTool != null) {
      featuredTools.add(imageCropperTool);
    }
    if (imageResizerTool != null) {
      featuredTools.add(imageResizerTool);
    }
    if (fileCompressorTool != null) {
      featuredTools.add(fileCompressorTool);
    }
    if (documentScannerTool != null) {
      featuredTools.add(documentScannerTool);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Switch to Categories tab
                (context as Element).markNeedsBuild();
                (context.findAncestorStateOfType<DashboardScreenState>())
                    ?.currentIndex = 2;
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: featuredTools.length,
          itemBuilder: (context, index) {
            final tool = featuredTools[index];
            return _FeaturedToolCard(tool: tool);
          },
        ),
      ],
    );
  }
}

class _FeaturedToolCard extends StatelessWidget {
  final Tool tool;

  const _FeaturedToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: tool.color.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          toolsProvider.addToRecent(tool);
          context.go(tool.routePath);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tool.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tool.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                tool.description,
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
  }
}

// This is needed for the context reference in the FeaturedTools class
class _DashboardScreenState extends State<StatefulWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
