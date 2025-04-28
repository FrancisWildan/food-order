// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.decimalPattern('id');

class MenuListScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialOrder;
  final bool isEditMode; // Tambahkan parameter untuk menentukan mode
  final String? orderId; // Tambahkan parameter untuk ID order yang diedit

  const MenuListScreen({
    super.key,
    this.initialOrder,
    this.isEditMode = false, // Default adalah mode "new order"
    this.orderId,
  });

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _currentOrder = [];
  double _currentOrderHeight = 200.0; // Default height for Current Order

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    if (widget.initialOrder != null) {
      _currentOrder = List<Map<String, dynamic>>.from(widget.initialOrder!);
      print('Initial Order Loaded: ${widget.initialOrder}'); // Debugging: Periksa initial order
    }
  }

  Future<void> _loadMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? menuData = prefs.getString('menu_items');
    if (menuData != null) {
      print('Menu Data Loaded: $menuData'); // Debugging: Periksa data yang dimuat
      setState(() {
        _menuItems = List<Map<String, dynamic>>.from(json.decode(menuData)).map((item) {
          final addOns = item['addOns'] != null
              ? List<Map<String, dynamic>>.from(item['addOns'])
              : [];
          print('Add-Ons for ${item['name']}: $addOns'); // Debugging: Periksa struktur add-ons
          return {
            ...item,
            'addOns': addOns,
            'quantity': 1,
          };
        }).toList();
      });
    } else {
      print('No menu data found'); // Debugging: Tidak ada data menu
    }
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersData = prefs.getString('orders');
    List<Map<String, dynamic>> orders = [];
    if (ordersData != null) {
      orders = List<Map<String, dynamic>>.from(json.decode(ordersData));
    }

    // Tentukan waktu saat ini
    final now = DateTime.now();
    final today = DateFormat('yyyyMMdd').format(now); // Format tanggal sebagai yyyyMMdd

    // Hitung nomor urut order untuk hari ini
    final todayOrders = orders.where((order) {
      final orderDate = order['id'].split('_')[0]; // Ambil tanggal dari id
      return orderDate == today; // Cocokkan dengan format yyyyMMdd
    }).toList();
    final orderNumber = todayOrders.length + 1; // Nomor urut berdasarkan jumlah order hari ini

    // Buat ID order dengan format tanggal_bulan_tahun_jam_menit_detik
    final orderId =
        '${today}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // Tambahkan current order ke daftar orders
    final newOrder = {
      'id': orderId, // Simpan id sebagai string
      'orderNumber': orderNumber, // Nomor urut untuk tampilan
      'items': _currentOrder, // Termasuk note di setiap item
      'status': 'Pending',
    };

    // Debug: Print detail order
    print('Order Details: $newOrder');

    orders.add(newOrder);

    // Simpan orders ke SharedPreferences
    await prefs.setString('orders', json.encode(orders));

    // Tampilkan notifikasi bahwa order berhasil disimpan
    showCustomSnackbar('Order berhasil disimpan!', Colors.green);

    // Kosongkan current order setelah disimpan
    setState(() {
      _currentOrder.clear();
    });
  }

  Future<void> _saveEditOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersData = prefs.getString('orders');
    List<Map<String, dynamic>> orders = [];
    if (ordersData != null) {
      orders = List<Map<String, dynamic>>.from(json.decode(ordersData));
    }

    // Cari order berdasarkan ID dan perbarui
    final orderIndex = orders.indexWhere((order) => order['id'] == orderId);
    if (orderIndex != -1) {
      final updatedOrder = {
        ...orders[orderIndex], // Pertahankan properti lain
        'items': _currentOrder, // Perbarui items termasuk note
      };

      // Debug: Print detail order yang diperbarui
      print('Updated Order Details: $updatedOrder');

      orders[orderIndex] = updatedOrder;

      // Simpan perubahan ke SharedPreferences
      await prefs.setString('orders', json.encode(orders));

      // Tampilkan notifikasi bahwa order berhasil diperbarui
      showCustomSnackbar('Order berhasil diperbarui!',Colors.green);
      setState(() {
        _currentOrder.clear();
      });
    }
  }

  void _addToOrder(Map<String, dynamic> item) {
    setState(() {
      final existingItemIndex = _currentOrder
          .indexWhere((orderItem) => orderItem['id'] == item['id']);
      if (existingItemIndex != -1) {
        _currentOrder[existingItemIndex]['quantity'] += 1; // Default increment by 1
      } else {
        final newItem = {
          ...item,
          'addOns': List<Map<String, dynamic>>.from(item['addOns'] ?? []), // Pastikan addOns adalah List<Map<String, dynamic>>
          'selectedAddOns': [],
          'quantity': 1,
        };
        print('Adding to Order: $newItem'); // Debugging: Periksa item yang ditambahkan
        _currentOrder.add(newItem);
      }
    });
  }

  void _removeFromOrder(int index) {
    setState(() {
      _currentOrder.removeAt(index);
    });
  }

  void _updateOrderQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _currentOrder[index]['quantity'] + delta;
      if (newQuantity > 0) {
        _currentOrder[index]['quantity'] = newQuantity;
      } else {
        _currentOrder.removeAt(index); // Remove item if quantity becomes 0
      }
    });
  }

  void showCustomSnackbar(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: bg,

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Order' : 'New Order'),
      ),
      body: Column(
        children: [
          // Daftar Menu
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_menuItems[index]['name']),
                  subtitle: Text('Type: ${_menuItems[index]['type']}'),
                  trailing: Text('Rp ${currencyFormatter.format(_menuItems[index]['price'])}'), // Format harga menu
                  onTap: () {
                    _addToOrder(_menuItems[index]);
                  },
                );
              },
            ),
          ),

          // Tampilan Current Order dengan Slider di sebelah kanan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Order
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Current Order', // Label untuk Current Order
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      height:
                          _currentOrderHeight, // Gunakan _currentOrderHeight untuk tinggi
                      color: Colors.grey[200],
                      child: ListView.builder(
                        itemCount: _currentOrder.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey), // Tambahkan border
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama Menu dan Jumlah
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _currentOrder[index]['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                        'Jumlah: ${_currentOrder[index]['quantity']}'),
                                  ],
                                ),
                                const SizedBox(height: 8.0),

                                // // Notes
                                // TextField(
                                //   decoration: const InputDecoration(
                                //     labelText: 'Note (optional)',
                                //     border: OutlineInputBorder(),
                                //   ),
                                //   onChanged: (value) {
                                //     setState(() {
                                //       _currentOrder[index]['note'] = value;
                                //     });
                                //   },
                                //   controller: TextEditingController(
                                //     text: _currentOrder[index]['note'],
                                //   ),
                                // ),
                                const SizedBox(height: 8.0),

                                // Add-Ons
                                if (_currentOrder[index]['addOns'] != null)
                                  Wrap(
                                    spacing: 8.0,
                                    children: _currentOrder[index]['addOns']
                                        .map<Widget>((addOn) {
                                      return FilterChip(
                                        label: Text('${addOn['name']} - Rp ${currencyFormatter.format(addOn['price'])}'), // Format harga add-on
                                        selected: _currentOrder[index]['selectedAddOns']
                                                ?.any((selectedAddOn) => selectedAddOn['name'] == addOn['name']) ??
                                            false,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _currentOrder[index]['selectedAddOns'] ??= [];
                                              _currentOrder[index]['selectedAddOns'].add(addOn); // Tambahkan nama dan harga add-on
                                            } else {
                                              _currentOrder[index]['selectedAddOns']
                                                  ?.removeWhere((selectedAddOn) => selectedAddOn['name'] == addOn['name']);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 8.0),

                                // Tombol Aksi
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _updateOrderQuantity(index, -1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _updateOrderQuantity(index, 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _removeFromOrder(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Slider di sebelah kanan
              RotatedBox(
                quarterTurns: 3, // Putar slider secara vertikal
                child: Slider(
                  value: _currentOrderHeight,
                  min: 100.0,
                  max: 500.0,
                  divisions: 5,
                  label: '${_currentOrderHeight.round()} px',
                  onChanged: (value) {
                    setState(() {
                      _currentOrderHeight =
                          value; // Perbarui tinggi berdasarkan slider
                    });
                  },
                ),
              ),
            ],
          ),

          // Tombol Finish
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (widget.isEditMode) {
                  // Jalankan saveEditOrder jika dalam mode edit
                  await _saveEditOrder(widget.orderId!);
                } else {
                  // Jalankan saveOrder jika dalam mode new order
                  await _saveOrder();
                }
                Navigator.pop(context); // Kembali ke OrdersScreen
              },
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }
}
