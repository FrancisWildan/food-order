import 'package:flutter/material.dart';
import 'all_you_can_eat_screen.dart';
import 'create_menu_screen.dart';
import 'menu_list_screen.dart';
import 'orders_screen.dart';
import 'trx_calc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All You Can Eat'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Flutter
              // Center(
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/flutter_logo.png', // Pastikan file logo ada di folder assets
              //         height: 100,
              //         width: 100,
              //       ),
              //       const SizedBox(height: 16),
              //     ],
              //   ),
              // ),

              // Kelompok 1: Menu dan Pesanan
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateMenuScreen(),
                            ),
                          );
                        },
                        child: const Text('Buat Menu Baru'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MenuListScreen(),
                            ),
                          );
                        },
                        child: const Text('Pesan Makanan'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrdersScreen(),
                            ),
                          );
                        },
                        child: const Text('Daftar Pesanan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kelompok 2: 
               Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllYouCanEatScreen(),
                        ),
                      );
                    },
                    child: const Text('Pesanan All You Can Eat'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kelompok 3: 
             
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrxCalcScreen(),
                        ),
                      );
                    },
                    child: const Text('Laporan Belanja'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}