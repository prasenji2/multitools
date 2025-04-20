import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/models/tool_model.dart';
import 'package:multi_utility_tools/shared/widgets/tool_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CategoryToolsScreen extends StatelessWidget {
  final ToolCategory category;

  const CategoryToolsScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: category.tools.length,
          itemBuilder: (context, index) {
            return ToolCard(tool: category.tools[index]);
          },
        ),
      ),
    );
  }
}
