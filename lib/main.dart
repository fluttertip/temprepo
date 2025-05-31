import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BhagchalApp());
}

class BhagchalApp extends StatelessWidget {
  const BhagchalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if it's mobile width
        final isMobile = constraints.maxWidth < 600;

        return MaterialApp(
          title: 'Bhagchal',
          theme: ThemeData.dark(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (isMobile) {
              // ✅ Mobile: show app normally
              return child!;
            }

            // ✅ Desktop: Wrap everything in a mobile-sized container
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "This app is best viewed in mobile size. Please zoom out or resize your browser.",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 400,
                      height: 800,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: child!,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
