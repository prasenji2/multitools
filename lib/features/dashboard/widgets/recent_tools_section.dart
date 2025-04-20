import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:multi_utility_tools/shared/widgets/tool_card.dart';
import 'package:provider/provider.dart';

class RecentToolsSection extends StatelessWidget {
  const RecentToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final recentTools = toolsProvider.recentTools;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentTools.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < recentTools.length - 1 ? 16.0 : 0,
                  ),
                  child: ToolCard(
                    tool: recentTools[index],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
