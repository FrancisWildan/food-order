// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'menu_list_screen.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

final NumberFormat currencyFormatter = NumberFormat.decimalPattern('id');

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersData = prefs.getString('orders');
    if (ordersData != null) {
      print('Orders Data: $ordersData'); // Debugging: Periksa data yang dimuat
      final List<dynamic> rawOrders =
          json.decode(ordersData); // Decode JSON sebagai List<dynamic>
      final List<Map<String, dynamic>> orders =
          rawOrders.map<Map<String, dynamic>>((order) {
        return {
          ...order as Map<String,
              dynamic>, // Pastikan tipe data adalah Map<String, dynamic>
          'items': (order['items'] as List<dynamic>)
              .map<Map<String, dynamic>>((item) {
            return {
              ...item as Map<String,
                  dynamic>, // Pastikan tipe data adalah Map<String, dynamic>
              'addOns': item['addOns'] != null
                  ? (item['addOns'] as List<dynamic>)
                      .map<Map<String, dynamic>>((addOn) {
                      if (addOn is String) {
                        // Jika addOn adalah String, konversi ke Map
                        return {'name': addOn, 'price': 0.0};
                      }
                      return addOn as Map<String, dynamic>;
                    }).toList()
                  : [],
              'selectedAddOns': item['selectedAddOns'] != null
                  ? (item['selectedAddOns'] as List<dynamic>)
                      .map<Map<String, dynamic>>((selectedAddOn) {
                      if (selectedAddOn is String) {
                        // Jika selectedAddOn adalah String, konversi ke Map
                        return {'name': selectedAddOn, 'price': 0.0};
                      }
                      return selectedAddOn as Map<String, dynamic>;
                    }).toList()
                  : [],
            };
          }).toList(),
        };
      }).toList();
      setState(() {
        _groupedOrders = _groupOrdersByDate(orders);
      });
    } else {
      print('No orders found'); // Debugging: Tidak ada data order
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupOrdersByDate(
      List<Map<String, dynamic>> orders) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final order in orders) {
      // Ambil tanggal dari id (bagian sebelum '_') dan ubah formatnya
      final rawDate = order['id'].split('_')[0];
      final formattedDate = DateFormat('dd-MM-yyyy')
          .format(DateTime.parse(rawDate)); // Format tanggal menjadi dd-MM-yyyy
      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(order);
    }
    return grouped;
  }

  Future<void> _deleteOrder(String date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersData = prefs.getString('orders');
    if (ordersData != null) {
      final orders = List<Map<String, dynamic>>.from(json.decode(ordersData));
      final orderToDelete = _groupedOrders[date]![index];
      orders.removeWhere((order) => order['id'] == orderToDelete['id']);
      await prefs.setString('orders', json.encode(orders));
      setState(() {
        _groupedOrders = _groupOrdersByDate(orders);
      });
    }
  }

  Future<void> _deleteAllOrdersForDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersData = prefs.getString('orders');
    if (ordersData != null) {
      final orders = List<Map<String, dynamic>>.from(json.decode(ordersData));
      // Hapus semua order yang memiliki tanggal sesuai dengan parameter `date`
      orders.removeWhere((order) =>
          order['id'].startsWith(date)); // Bandingkan tanggal di awal `id`
      await prefs.setString('orders', json.encode(orders));
      setState(() {
        _groupedOrders = _groupOrdersByDate(orders);
      });
    }
  }

  void _addAnotherMenu(String date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MenuListScreen(
          isEditMode: false, // Mode new order
        ),
      ),
    );

    // Reload orders after adding a new order
    _loadOrders();
  }

  void _editOrder(String date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersData = prefs.getString('orders');
    if (ordersData != null) {
      final orderToEdit = _groupedOrders[date]![index];

      // Konversi items ke List<Map<String, dynamic>>
      final List<Map<String, dynamic>> items =
          List<Map<String, dynamic>>.from(orderToEdit['items']);

      // Navigate to MenuListScreen in edit mode
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuListScreen(
            initialOrder: items,
            isEditMode: true, // Mode edit
            orderId: orderToEdit['id'], // Kirim ID order
          ),
        ),
      );

      // Reload orders from SharedPreferences after editing
      final updatedOrdersData = prefs.getString('orders');
      if (updatedOrdersData != null) {
        final updatedOrders =
            List<Map<String, dynamic>>.from(json.decode(updatedOrdersData));
        setState(() {
          _groupedOrders = _groupOrdersByDate(updatedOrders);
        });
      }
    }
  }

  Future<void> _toggleOrderStatus(String date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersData = prefs.getString('orders');
    if (ordersData != null) {
      final orders = List<Map<String, dynamic>>.from(json.decode(ordersData));
      final orderToUpdate = _groupedOrders[date]![index];

      // Toggle the status
      orderToUpdate['status'] =
          orderToUpdate['status'] == 'Pending' ? 'Completed' : 'Pending';

      // Update the order in the main list
      final orderIndex =
          orders.indexWhere((order) => order['id'] == orderToUpdate['id']);
      if (orderIndex != -1) {
        orders[orderIndex] = orderToUpdate;
      }

      // Save the updated orders back to SharedPreferences
      await prefs.setString('orders', json.encode(orders));

      // Update the grouped orders in the UI
      setState(() {
        _groupedOrders = _groupOrdersByDate(orders);
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      String title, VoidCallback onConfirm) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('Apakah Anda yakin ingin menghapus?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        double totalPrice = 0.0; // Total keseluruhan

        return AlertDialog(
          title: Text('Detail Order #${order['orderNumber']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order['items'].map<Widget>((item) {
                  // Hitung subtotal untuk setiap menu
                  double itemSubtotal = item['price'] *
                      (item['quantity'] ?? 1); // Harga menu x quantity

                  // Tambahkan harga add-ons ke subtotal
                  if (item['selectedAddOns'] != null) {
                    for (var addOn in item['selectedAddOns']) {
                      final addOnData = item['addOns'].firstWhere(
                        (addOnItem) =>
                            addOnItem['name'] == addOn['name'], // Cocokkan berdasarkan nama
                        orElse: () => {
                          'name': '',
                          'price': 0.0
                        }, // Kembalikan Map<String, dynamic> default
                      );
                      if (addOnData['name'] != '') {
                        itemSubtotal += addOnData['price'] *
                            (item['quantity'] ?? 1); // Harga add-ons x quantity
                      }
                    }
                  }

                  // Tambahkan subtotal item ke total keseluruhan
                  totalPrice += itemSubtotal;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['name']} - Rp ${currencyFormatter.format(item['price'])} x ${item['quantity']} = Rp ${currencyFormatter.format(item['price'] * (item['quantity'] ?? 1))}',
                      ),
                      if (item['selectedAddOns'] != null &&
                          item['selectedAddOns'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Add-Ons:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...item['selectedAddOns'].map<Widget>((addOn) {
                                final addOnData = item['addOns'].firstWhere(
                                  (addOnItem) =>
                                      addOnItem['name'] == addOn['name'],
                                  orElse: () => {'name': '', 'price': 0.0},
                                );
                                if (addOnData['name'] != '') {
                                  return Text(
                                    '- ${addOnData['name']}: Rp ${currencyFormatter.format(addOnData['price'])} x ${item['quantity']} = Rp ${currencyFormatter.format(addOnData['price'] * (item['quantity'] ?? 1))}',
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              }).toList(),
                            ],
                          ),
                        ),
                      Text(
                        'Subtotal: Rp ${currencyFormatter.format(itemSubtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
                Text(
                  'Total: Rp ${currencyFormatter.format(totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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

  Future<void> _generatePdfForDate(String date) async {
    if (!_groupedOrders.containsKey(date) || _groupedOrders[date]!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk tanggal ini.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final transactions = _groupedOrders[date]!;

    // Hitung Grand Total
    final grandTotal = transactions.fold<double>(
      0.0,
      (double sum, Map<String, dynamic> transaction) {
        final transactionTotal = transaction['items'].fold<double>(
          0.0,
          (double itemSum, Map<String, dynamic> item) =>
              itemSum + (item['price'] * item['quantity']),
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
              'Transaksi Tanggal: $date',
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
                        pw.Text(
                            'Rp ${currencyFormatter.format(item['price'])}'),
                        pw.Text('${item['quantity']}'),
                        pw.Text('Rp ${currencyFormatter.format(total)}'),
                      ],
                    );
                  });
                }),
                pw.TableRow(
                  children: [
                    pw.Text(''),
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
      final now = DateTime.now();
      final formattedDateTime = DateFormat('dd-MM-yyyy_HHmmss').format(now);

      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file =
          File('${directory.path}/orders_${date}_$formattedDateTime.pdf');
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
    if (_groupedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk dibuat PDF.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    double grandTotalAll = 0.0;

    _groupedOrders.forEach((date, transactions) {
      final grandTotal = transactions.fold<double>(
        0.0,
        (double sum, Map<String, dynamic> transaction) {
          final transactionTotal = transaction['items'].fold<double>(
            0.0,
            (double itemSum, Map<String, dynamic> item) =>
                itemSum + (item['price'] * item['quantity']),
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
                          pw.Text(
                              'Rp ${currencyFormatter.format(item['price'])}'),
                          pw.Text('${item['quantity']}'),
                          pw.Text('Rp ${currencyFormatter.format(total)}'),
                        ],
                      );
                    });
                  }),
                  pw.TableRow(
                    children: [
                      pw.Text(''),
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
      final now = DateTime.now();
      final formattedDateTime = DateFormat('dd-MM-yyyy_HHmmss').format(now);

      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File('${directory.path}/orders_all_$formattedDateTime.pdf');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: ListView(
        children: _groupedOrders.keys.map((date) {
          final isToday =
              date == DateFormat('yyyy-MM-dd').format(DateTime.now());
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
            subtitle: Text('Jumlah Order: ${_groupedOrders[date]!.length}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToday)
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => _addAnotherMenu(date),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(
                    'Hapus Semua Order untuk $date',
                    () => _deleteAllOrdersForDate(date),
                  ),
                ),
              ],
            ),
            children: _groupedOrders[date]!.asMap().entries.map((entry) {
              final index = entry.key;
              final order = entry.value;
              return ListTile(
                title: Text('Order #${order['orderNumber']}'),
                subtitle: Text('Status: ${order['status']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        order['status'] == 'Pending'
                            ? Icons.check_box_outline_blank
                            : Icons.check_box,
                        color: order['status'] == 'Pending'
                            ? Colors.red
                            : Colors.green,
                      ),
                      onPressed: () => _toggleOrderStatus(date, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editOrder(date, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(
                        'Hapus Order #${order['orderNumber']}',
                        () => _deleteOrder(date, index),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _showOrderDetails(order);
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
