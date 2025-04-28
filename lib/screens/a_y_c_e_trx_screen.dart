// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

final NumberFormat currencyFormatter = NumberFormat.decimalPattern('id');

class AllYouCanEatTransactionsScreen extends StatefulWidget {
  const AllYouCanEatTransactionsScreen({super.key});

  @override
  State<AllYouCanEatTransactionsScreen> createState() =>
      _AllYouCanEatTransactionsScreenState();
}

class _AllYouCanEatTransactionsScreenState
    extends State<AllYouCanEatTransactionsScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsData = prefs
        .getString('ayce_transactions'); // Ambil data dari ayce_transactions
    if (transactionsData != null) {
      final List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(json.decode(transactionsData));

      setState(() {
        _groupedTransactions = _groupTransactionsByDate(transactions);
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
      List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final transaction in transactions) {
      final rawDate = transaction['id'].split('_')[0];
      final formattedDate =
          DateFormat('dd-MM-yyyy_HHmmss').format(DateTime.parse(rawDate));
      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(transaction);
    }
    return grouped;
  }

  Future<void> _generatePdfForDate(String date) async {
    final pdf = pw.Document();
    final transactions = _groupedTransactions[date]!;

    // Hitung Grand Total
    final grandTotal = transactions.fold<double>(
      0.0,
      (sum, transaction) {
        final transactionTotal = transaction['items'][0]['price'] *
            transaction['items'][0]['quantity'];
        return sum + transactionTotal;
      },
    );

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Transaksi Tanggal: $date',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Order Number',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Jumlah Orang',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                ...transactions.map((transaction) {
                  final total = transaction['items'][0]['price'] *
                      transaction['items'][0]['quantity'];
                  return pw.TableRow(
                    children: [
                      pw.Text('Order #${transaction['orderNumber']}'),
                      pw.Text('${transaction['items'][0]['quantity']}'),
                      pw.Text('Rp ${currencyFormatter.format(total)}'),
                    ],
                  );
                }),
                pw.TableRow(
                  children: [
                    pw.Text(''),
                    pw.Text('Grand Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rp ${currencyFormatter.format(grandTotal)}',
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
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File('${directory.path}/transaksi_AYCE_$date.pdf');
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
        (sum, transaction) {
          final transactionTotal = transaction['items'][0]['price'] *
              transaction['items'][0]['quantity'];
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
                'Transaksi Tanggal: $date',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Order Number',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Jumlah Orang',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...transactions.map((transaction) {
                    final total = transaction['items'][0]['price'] *
                        transaction['items'][0]['quantity'];
                    return pw.TableRow(
                      children: [
                        pw.Text('Order #${transaction['orderNumber']}'),
                        pw.Text('${transaction['items'][0]['quantity']}'),
                        pw.Text('Rp ${currencyFormatter.format(total)}'),
                      ],
                    );
                  }),
                  pw.TableRow(
                    children: [
                      pw.Text(''),
                      pw.Text('Grand Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rp ${currencyFormatter.format(grandTotal)}',
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

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(
            'Grand Total Semua Transaksi: Rp ${currencyFormatter.format(grandTotalAll)}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );

    try {
      // Dapatkan tanggal saat ini
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd_HHmmss').format(now);

      // Simpan file dengan nama yang menyertakan tanggal
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file =
          File('${directory.path}/transaksi_AYCE_all_$formattedDate.pdf');
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

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final String? ayceData = prefs.getString('ayce_transactions');
    if (ayceData != null) {
      final List<Map<String, dynamic>> ayceTransactions =
          List<Map<String, dynamic>>.from(json.decode(ayceData));

      // Hapus transaksi dari daftar
      ayceTransactions.removeWhere((order) => order['id'] == transaction['id']);

      // Simpan kembali ke SharedPreferences
      await prefs.setString('ayce_transactions', json.encode(ayceTransactions));

      // Perbarui tampilan
      setState(() {
        _groupedTransactions = _groupTransactionsByDate(ayceTransactions);
      });

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi All You Can Eat'),
      ),
      body: ListView(
        children: _groupedTransactions.keys.map((date) {
          return ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tanggal: $date'),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                  onPressed: () => _generatePdfForDate(date),
                ),
              ],
            ),
            subtitle:
                Text('Jumlah Transaksi: ${_groupedTransactions[date]!.length}'),
            children: _groupedTransactions[date]!.map((transaction) {
              final totalPrice = transaction['items'][0]['price'] *
                  transaction['items'][0]['quantity'];
              return ListTile(
                title: Text('Order #${transaction['orderNumber']}'),
                subtitle: Text(
                  'Total: Rp ${currencyFormatter.format(totalPrice)}',
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTransaction(transaction),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            'Detail Transaksi #${transaction['orderNumber']}'),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Jumlah Orang: ${transaction['items'][0]['quantity']}'),
                            Text(
                                'Total Harga: Rp ${currencyFormatter.format(totalPrice)}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePdfForAll,
        // child: const Icon(Icons.picture_as_pdf),
        backgroundColor: Colors.blue,
        tooltip: 'Convert Semua Transaksi ke PDF',
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }
}
