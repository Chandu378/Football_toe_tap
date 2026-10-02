import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/tap_counter_controller.dart';
import 'screens/tap_counter_screen.dart';

/// Flickit application root widget.
class FlickitApp extends StatelessWidget {
  const FlickitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TapCounterController(),
      child: MaterialApp(
        title: 'Flickit Toe Tap Counter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF090D16),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF22C55E),
            secondary: Color(0xFF38BDF8),
            surface: Color(0xFF0F172A),
          ),
          useMaterial3: true,
        ),
        home: const TapCounterScreen(),
      ),
    );
  }
}
