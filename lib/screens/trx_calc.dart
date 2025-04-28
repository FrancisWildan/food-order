// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'trx_list_screen.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,##0", "id_ID");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Hapus semua karakter non-digit
    final unformattedValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format ulang angka dengan pemisah ribuan
    final formattedValue = _formatter.format(int.tryParse(unformattedValue) ?? 0);

    // Kembalikan nilai yang diformat dengan posisi kursor di akhir
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

class TrxCalcScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTransaction;

  const TrxCalcScreen({super.key, this.initialTransaction});

  @override
  State<TrxCalcScreen> createState() => _TrxCalcScreenState();
}

class _TrxCalcScreenState extends State<TrxCalcScreen> {
  final List<Map<String, dynamic>> _items = [];
  // List<Map<String, dynamic>> _savedTransactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      _items.addAll(
          List<Map<String, dynamic>>.from(widget.initialTransaction!['items']));
    }
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs.getString('transactions');
    if (transactionsData != null) {
      // setState(() {
      //   _savedTransactions = List<Map<String, dynamic>>.from(json.decode(transactionsData));
      // });
    } else {
      // setState(() {
      //   _savedTransactions = []; // Kosongkan jika tidak ada data
      // });
    }
  }

  // Future<void> _saveTransactions() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('transactions', json.encode(_savedTransactions));
  // }

  void _addField() {
    setState(() {
      _items.add({'name': '', 'price': 0.0, 'quantity': 1});
    });
  }

  void _saveTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs.getString('transactions');
    final List<Map<String, dynamic>> transactions = transactionsData != null
        ? List<Map<String, dynamic>>.from(json.decode(transactionsData))
        : [];

    if (widget.initialTransaction != null) {
      transactions.removeWhere((transaction) =>
          transaction['id'] == widget.initialTransaction!['id']);
    }

    final newTransaction = {
      'id': widget.initialTransaction?['id'] ?? DateTime.now().toString(),
      'date': DateTime.now().toIso8601String(),
      'items': _items,
    };

    transactions.add(newTransaction);
    await prefs.setString('transactions', json.encode(transactions));
    print('Data setelah disimpan: ${json.encode(transactions)}'); // Debugging

    // Tampilkan Snackbar hijau
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi berhasil disimpan!'),
        backgroundColor: Colors.green,
      ),
    );

    // Kembali ke layar sebelumnya
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrxListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration:
                              const InputDecoration(labelText: 'Nama Barang'),
                          onChanged: (value) {
                            setState(() {
                              item['name'] = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Harga'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Hanya izinkan angka
                            ThousandsSeparatorInputFormatter(), // Formatter untuk pemisah ribuan
                          ],
                          onChanged: (value) {
                            setState(() {
                              // Hapus pemisah ribuan sebelum menyimpan ke item
                              final unformattedValue = value.replaceAll('.', '');
                              item['price'] = double.tryParse(unformattedValue) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration:
                              const InputDecoration(labelText: 'Jumlah'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              item['quantity'] = int.tryParse(value) ?? 1;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addField,
              child: const Text('Tambah Barang'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Simpan Transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}
