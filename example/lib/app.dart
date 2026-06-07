import 'package:flutter/material.dart';
import 'package:snap_floater/snap_floater.dart';

import 'home_screen.dart';
import 'logger_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
        builder: (context, child) => NewWidget(child: child),
      );
}

class NewWidget extends StatelessWidget {
  const NewWidget({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => SnapFloaterScope(
        settings: const SnapFloaterSettings(
          dragMode: FloaterDragMode.pan,
          snapAlignments: [
            Alignment.bottomCenter,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ],
        ),
        onPressed: () async {
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const LoggerScreen(),
            ),
          );
        },
        child: child ?? const HomeScreen(),
      );
}
