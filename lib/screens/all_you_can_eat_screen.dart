// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'a_y_c_e_trx_screen.dart';

class AllYouCanEatScreen extends StatefulWidget {
  const AllYouCanEatScreen({super.key});

  @override
  State<AllYouCanEatScreen> createState() => _AllYouCanEatScreenState();
}

class _AllYouCanEatScreenState extends State<AllYouCanEatScreen> {
  int _numberOfPeople = 1; // Default 1 orang
  static const int pricePerPerson = 30000; // Harga tetap per orang

  int _calculateTotal() {
    return _numberOfPeople * pricePerPerson;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All You Can Eat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllYouCanEatTransactionsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'All You Can Eat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Harga per orang: Rp 30.000',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  if (_numberOfPeople > 1) {
                    setState(() {
                      _numberOfPeople--;
                    });
                  }
                },
              ),
              Text(
                '$_numberOfPeople Orang',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  setState(() {
                    _numberOfPeople++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total Harga: Rp $totalPrice',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Tambahkan logika untuk konfirmasi pesanan
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Pesanan'),
                  content: Text('Total yang harus dibayar: Rp $totalPrice'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Simpan pesanan ke SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        final String? ayceData = prefs.getString('ayce_transactions');
                        final List<Map<String, dynamic>> ayceTransactions = ayceData != null
                            ? List<Map<String, dynamic>>.from(json.decode(ayceData))
                            : [];

                        // Filter transaksi berdasarkan tanggal hari ini
                        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final todayOrders = ayceTransactions.where((order) {
                          final orderDate = order['id'].split('_')[0];
                          return orderDate == today;
                        }).toList();

                        // Hitung nomor urut pesanan berdasarkan transaksi hari ini
                        final int nextOrderNumber = todayOrders.isNotEmpty
                            ? todayOrders.map((order) => order['orderNumber'] as int).reduce((a, b) => a > b ? a : b) + 1
                            : 1;

                        // Buat data pesanan baru
                        final newOrder = {
                          'id': '${today}_${nextOrderNumber}_all_you_can_eat',
                          'orderNumber': nextOrderNumber,
                          'status': 'Pending',
                          'items': [
                            {
                              'name': 'All You Can Eat',
                              'price': pricePerPerson,
                              'quantity': _numberOfPeople,
                            },
                          ],
                        };

                        // Tambahkan pesanan baru ke daftar transaksi All You Can Eat
                        ayceTransactions.add(newOrder);

                        // Simpan kembali ke SharedPreferences
                        await prefs.setString('ayce_transactions', json.encode(ayceTransactions));

                        // Tampilkan pesan sukses
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pesanan berhasil dibuat!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Konfirmasi'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Konfirmasi Pesanan'),
          ),
        ],
      ),
    );
  }
}