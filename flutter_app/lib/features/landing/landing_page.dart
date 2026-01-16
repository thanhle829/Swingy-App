import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/Untitled design.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.55))),

          // Main content stacked vertically for mobile-like landing
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),

                // Top title area (keeps some breathing room)
                const SizedBox(height: 30),

                Expanded(
                  child: Row(
                    children: [
                      // Vertical stacked letters on the left to mimic design
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: 'SWINGY'.split('').map((c) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),
                      ),

                      // Spacer for big visual area
                      Expanded(child: Container()),
                    ],
                  ),
                ),

                // Short copy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                  child: Column(children: const [
                    Text('Track Progress,', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 6),
                    Text('Refine Your Swing &', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 6),
                    Text('Master Every Round!', style: TextStyle(color: Colors.white70)),
                  ]),
                ),

                // CTA button at bottom
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/camera'),
                      icon: Image.asset('assets/images/icons8-verify-64.png', width: 28, height: 28, color: Colors.white),
                      label: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Start Detecting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
                          Image.asset('assets/images/icons8-double-right-50.png', width: 28, height: 28, color: Colors.white),
                        ],
                      ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
