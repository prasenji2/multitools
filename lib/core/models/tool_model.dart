import 'package:flutter/material.dart';

class ToolCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<Tool> tools;

  ToolCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.tools,
  });
}

class Tool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPremium;
  final bool worksOffline;
  final String routePath;

  Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isPremium = false,
    this.worksOffline = true,
    required this.routePath,
  });
}
