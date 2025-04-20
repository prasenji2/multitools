import 'package:flutter/material.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:multi_utility_tools/shared/widgets/tool_card.dart';
import 'package:provider/provider.dart';

class FavoritesSection extends StatelessWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final toolsProvider = Provider.of<ToolsProvider>(context);
    final favoriteTools = toolsProvider.favoriteTools;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorites',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteTools.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < favoriteTools.length - 1 ? 16.0 : 0,
                  ),
                  child: ToolCard(
                    tool: favoriteTools[index],
                    showFavoriteButton: true,
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
