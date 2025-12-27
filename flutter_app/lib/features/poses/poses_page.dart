import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PosesPage extends StatelessWidget {
  const PosesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final golfers = [
      {
        'name': 'Tiger Woods',
        'stance': 'Balanced stance with feet shoulder-width apart',
      },
      {
        'name': 'Jack Nicklaus',
        'stance': 'Closed stance with controlled positioning',
      },
      {
        'name': 'Rory McIlroy',
        'stance': 'Athletic stance with dynamic balance',
      },
      {'name': 'Dustin Johnson', 'stance': 'Wide stance for stability'},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1720), Color(0xFF0B1220)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/feedback'),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Back to Analysis', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF334155)), backgroundColor: Colors.transparent),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Famous Golfer Poses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Learn and compare your posture with professional golfers', style: TextStyle(color: Color(0xFF94A3B8))),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: golfers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final g = golfers[idx];
                    return Card(
                      color: const Color(0xFF0B1220),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF334155))),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g['name']!, style: const TextStyle(color: Color(0xFFFFC107), fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black), child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white30, size: 48))),
                          const SizedBox(height: 8),
                          Text('Stance: ${g['stance']}', style: const TextStyle(color: Colors.white70)),
                        ]),
                      ),
                    );
                  },
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
