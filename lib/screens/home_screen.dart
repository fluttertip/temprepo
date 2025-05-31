import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final Color accentColor = Colors.brown.shade300;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with slight dark overlay
          Image.asset(
            'assets/images/openart-image_FtIYq2cR_1748273727660_raw.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.4)),

          // Top Banner Ad Placeholder
          // Align(
          //   alignment: Alignment.topCenter,
          //   child: Container(
          //     height: 50,
          //     width: double.infinity,
          //     color: Colors.brown.withOpacity(0.6),
          //     alignment: Alignment.center,
          //     child: const Text(
          //       'Top Banner Ad',
          //       style: TextStyle(color: Colors.white70, fontSize: 16),
          //     ),
          //   ),
          // ),

          // Move card lower using FractionalTranslation
          Align(
            alignment: Alignment.center,
            child: FractionalTranslation(
              translation: const Offset(0, 0.15), // Move down 15% of its height
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.symmetric(
                  vertical: 45,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.brown.shade900.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 6),
                      blurRadius: 12,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.brown.shade300.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // _OptionButton(
                    //   icon: Icons.play_arrow,
                    //   label: 'Play with bot',
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (_) => const GameScreen()),
                    //     );
                    //   },
                    // ),
                    const SizedBox(height: 30),

                    _OptionButton(
                      icon: Icons.play_arrow,
                      label: '2 Player Offfline',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    _OptionButton(
                      icon: Icons.group,
                      label: 'Multiplayer',
                      onPressed: () {},
                    ),

                    const SizedBox(height: 20),

                    _OptionButton(
                      icon: Icons.settings,
                      label: 'Settings',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = Colors.orange[300];
    final bgColor = Colors.brown.shade900.withOpacity(0.1);

    return SizedBox(
      width: 260, // 🔥 Force all buttons to same width
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: fgColor,
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 20, // 🔥 Same size for all
            fontWeight: FontWeight.bold,
          ),
          elevation: 6,
          shadowColor: Colors.black,
        ),
        icon: Icon(icon, size: 28),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
