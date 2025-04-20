import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:multi_utility_tools/core/providers/theme_provider.dart';
import 'package:multi_utility_tools/core/providers/tools_provider.dart';
import 'package:multi_utility_tools/core/router/app_router.dart';
import 'package:multi_utility_tools/core/theme/app_theme.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log error to console or analytics service
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Handle uncaught async errors
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error');
    return true;
  };

  // Run the app inside a zone that catches errors
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stackTrace) {
      debugPrint('Caught error in runZonedGuarded: $error');
      debugPrint(stackTrace.toString());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ToolsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Multi-Utility Tools',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            // Add error handling for the router
            builder: (context, widget) {
              // Add error handling for the framework
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: Text(
                    'An error occurred: ${details.exception}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              };

              // Check for errors in the widget tree
              if (widget == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('App failed to initialize'),
                  ),
                );
              }

              return widget;
            },
          );
        },
      ),
    );
  }
}
