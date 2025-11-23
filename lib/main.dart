import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitnessOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFFBBF24),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Color(0xFF0F172A), Color(0xFF292524)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            ['Home', 'Train', 'Fuel', 'You'][_currentIndex],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                  ),
                ),
                child: const Icon(Icons.fitness_center, size: 50, color: Colors.black),
              ),
              const SizedBox(height: 32),
              const Text(
                'FitnessOS',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ['Your mission today', 'Train hard', 'Fuel your body', 'Track progress'][_currentIndex],
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'BEGIN SESSION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xE6000000),
            border: Border(
              top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabButton(0, Icons.home, 'Home'),
                  _buildTabButton(1, Icons.fitness_center, 'Train'),
                  _buildTabButton(2, Icons.apple, 'Fuel'),
                  _buildTabButton(3, Icons.person, 'You'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive ? const Color(0xFFFBBF24) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : const Color(0x80FFFFFF),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : const Color(0x80FFFFFF),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
