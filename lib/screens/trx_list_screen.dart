// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TrxListScreen extends StatefulWidget {
  const TrxListScreen({super.key});

  @override
  State<TrxListScreen> createState() => _TrxListScreenState();
}

class _TrxListScreenState extends State<TrxListScreen> {
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "id_ID");
  final DateFormat _dateFormat = DateFormat("dd MMMM yyyy", "id_ID");
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs.getString('transactions');
    if (transactionsData != null) {
      final List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(json.decode(transactionsData));
      setState(() {
        _groupedTransactions = _groupTransactionsByDate(transactions);
      });
    } else {
      setState(() {
        _groupedTransactions = {};
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final transaction in transactions) {
      final date =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date']));
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    return grouped;
  }

  Future<void> _deleteTransactionsForDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs.getString('transactions');
    if (transactionsData != null) {
      final List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(json.decode(transactionsData));
      transactions.removeWhere((transaction) =>
          DateFormat('yyyy-MM-dd')
              .format(DateTime.parse(transaction['date'])) ==
          date);
      await prefs.setString('transactions', json.encode(transactions));
      setState(() {
        _groupedTransactions = _groupTransactionsByDate(transactions);
      });
    }
  }

  Future<void> _generatePdf(String date) async {
    final pdf = pw.Document();
    final transactions = _groupedTransactions[date]!;

    // Hitung Grand Total
    final grandTotal = transactions.fold<double>(
      0.0,
      (double sum, transaction) {
        final transactionTotal = transaction['items'].fold<double>(
          0.0,
          (double itemSum, item) => itemSum + (item['price'] * item['quantity']),
        );
        return sum + transactionTotal;
      },
    );

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Transaksi ${_dateFormat.format(DateTime.parse(date))}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Nama Barang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Harga',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Jumlah',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                ...transactions.expand((transaction) {
                  return transaction['items'].map<pw.TableRow>((item) {
                    final total = item['price'] * item['quantity'];
                    return pw.TableRow(
                      children: [
                        pw.Text(item['name']),
                        pw.Text('Rp ${_currencyFormat.format(item['price'])}'),
                        pw.Text('${item['quantity']}'),
                        pw.Text('Rp ${_currencyFormat.format(total)}'),
                      ],
                    );
                  });
                }).toList(),
                // Tambahkan baris untuk Grand Total
                pw.TableRow(
                  children: [
                    pw.Text(''),
                    pw.Text(''),
                    pw.Text('Grand Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rp ${_currencyFormat.format(grandTotal)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    try {
      // Format nama file dengan tanggal dan waktu
      final now = DateTime.now();
      final formattedDateTime = DateFormat('dd-MM-yyyy_HHmmss').format(now);

      // Dapatkan direktori Download
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // Simpan file dengan nama yang diformat
      final file = File('${directory.path}/shopping_transaksi_$formattedDateTime.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF berhasil disimpan di ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePdfForAll() async {
    final pdf = pw.Document();

    double grandTotalAll = 0.0;

    _groupedTransactions.forEach((date, transactions) {
      final grandTotal = transactions.fold<double>(
        0.0,
        (double sum, transaction) {
          final transactionTotal = transaction['items'].fold<double>(
            0.0,
            (double itemSum, item) => itemSum + (item['price'] * item['quantity']),
          );
          return sum + transactionTotal;
        },
      );

      grandTotalAll += grandTotal;

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Transaksi Tanggal: ${_dateFormat.format(DateTime.parse(date))}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Nama Barang',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Harga',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Jumlah',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...transactions.expand((transaction) {
                    return transaction['items'].map<pw.TableRow>((item) {
                      final total = item['price'] * item['quantity'];
                      return pw.TableRow(
                        children: [
                          pw.Text(item['name']),
                          pw.Text('Rp ${_currencyFormat.format(item['price'])}'),
                          pw.Text('${item['quantity']}'),
                          pw.Text('Rp ${_currencyFormat.format(total)}'),
                        ],
                      );
                    });
                  }).toList(),
                  pw.TableRow(
                    children: [
                      pw.Text(''),
                      pw.Text(''),
                      pw.Text('Grand Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rp ${_currencyFormat.format(grandTotal)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
      );
    });

    // Tambahkan Grand Total Semua Transaksi di halaman terakhir
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 16),
            pw.Text(
              'Grand Total Semua Transaksi: Rp ${_currencyFormat.format(grandTotalAll)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    try {
      // Dapatkan tanggal dan waktu saat ini
      final now = DateTime.now();
      final formattedDateTime = DateFormat('dd-MM-yyyy_HHmmss').format(now);

      // Simpan file dengan nama yang menyertakan tanggal dan waktu
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File('${directory.path}/shopping_transaksi_all_$formattedDateTime.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF berhasil disimpan di ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editTransaction(Map<String, dynamic> transaction) {
    // Tambahkan logika untuk mengedit transaksi
  }

  void _deleteTransaction(Map<String, dynamic> transactionToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs.getString('transactions');
    if (transactionsData != null) {
      final List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(json.decode(transactionsData));
      transactions.removeWhere(
          (transaction) => transaction['id'] == transactionToDelete['id']);
      await prefs.setString('transactions', json.encode(transactions));
      setState(() {
        _groupedTransactions = _groupTransactionsByDate(transactions);
      });
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: transaction['items'].map<Widget>((item) {
                final total = item['price'] * item['quantity'];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(
                      'Harga: Rp ${_currencyFormat.format(item['price'])} x ${item['quantity']} = Rp ${_currencyFormat.format(total)}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
      ),
      body: ListView(
        children: _groupedTransactions.keys.map((date) {
          final transactions = _groupedTransactions[date]!;
          final totalAmount = transactions.fold<double>(
            0.0,
            (double sum, transaction) {
              final items =
                  List<Map<String, dynamic>>.from(transaction['items']);
              final transactionTotal = items.fold<double>(
                0.0,
                (double itemSum, item) =>
                    itemSum + (item['price'] * item['quantity']),
              );
              return sum + transactionTotal;
            },
          );

          return ExpansionTile(
            title: Text('Tanggal: ${_dateFormat.format(DateTime.parse(date))}'),
            subtitle: Text('Total: Rp ${_currencyFormat.format(totalAmount)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                  onPressed: () => _generatePdf(date),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTransactionsForDate(date),
                ),
              ],
            ),
            children: transactions.map((transaction) {
              final transactionTotal = transaction['items'].fold<double>(
                0.0,
                (double sum, item) => sum + (item['price'] * item['quantity']),
              );

              return ListTile(
                title: Text('Total Barang: ${transaction['items'].length}'),
                subtitle: Text(
                    'Total Transaksi: Rp ${_currencyFormat.format(transactionTotal)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        _editTransaction(transaction);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteTransaction(transaction);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  _showTransactionDetails(transaction);
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePdfForAll,
        backgroundColor: Colors.blue,
        tooltip: 'Convert Semua Transaksi ke PDF',
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }
}
