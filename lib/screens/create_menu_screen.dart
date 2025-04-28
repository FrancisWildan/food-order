// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'menu_list.dart';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.decimalPattern('id');

class CreateMenuScreen extends StatefulWidget {
  const CreateMenuScreen({super.key});

  @override
  State<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends State<CreateMenuScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); // Tambahkan controller untuk harga
  String? _selectedType;
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _addOns = []; // Tambahkan harga untuk setiap add-on

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? menuData = prefs.getString('menu_items');
    if (menuData != null) {
      setState(() {
        _menuItems = List<Map<String, dynamic>>.from(json.decode(menuData)).map((item) {
          return {
            ...item,
            'addOns': item['addOns'] != null
                ? List<Map<String, dynamic>>.from(item['addOns']) // Pastikan addOns dimuat sebagai List<Map<String, dynamic>>
                : [],
          };
        }).toList();
      });
    }
  }

  Future<void> _saveMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToSave = _menuItems.map((item) {
      return {
        ...item,
        'addOns': item['addOns'] != null
            ? List<Map<String, dynamic>>.from(item['addOns']) // Simpan addOns sebagai List<Map<String, dynamic>>
            : [],
      };
    }).toList();
    print('Menu Data Saved: ${json.encode(dataToSave)}'); // Debugging: Periksa data yang disimpan
    await prefs.setString('menu_items', json.encode(dataToSave));
  }

  void _addMenuItem() {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedType == null) {
      // Tampilkan Snackbar jika ada field yang kosong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu Name, Menu Price, dan Type tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final newMenu = {
        'id': DateTime.now().toString(),
        'name': _nameController.text,
        'type': _selectedType,
        'price': double.parse(_priceController.text), // Simpan harga menu
        'addOns': _addOns, // Simpan add-ons beserta harga
      };
      print('New Menu Item: $newMenu'); // Debugging: Periksa menu yang ditambahkan
      _menuItems.add(newMenu);
    });

    _saveMenuItems(); // Pastikan data disimpan ke SharedPreferences

    // Tampilkan Snackbar jika berhasil menyimpan menu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu berhasil disimpan!'),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form setelah menyimpan
    _nameController.clear();
    _priceController.clear();
    _selectedType = null;
    _addOns = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuList(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Menu Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Menu Name'),
              ),
              const SizedBox(height: 16),

              // Input Menu Price
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Menu Price'),
              ),
              const SizedBox(height: 16),

              // Dropdown for Menu Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
                  DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                  DropdownMenuItem(value: 'Penutup', child: Text('Penutup')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),

              // Tombol Add-On
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _addOns.add({'name': '', 'price': 0.0}); // Tambahkan add-on baru
                  });
                },
                child: const Text('Add Add-On'),
              ),
              const SizedBox(height: 16),

              // Jika tidak ada add-ons, tampilkan tombol Add Menu Item di bawah tombol Add Add-On
              if (_addOns.isEmpty)
                ElevatedButton(
                  onPressed: _addMenuItem,
                  child: const Text('Add Menu Item'),
                ),
              const SizedBox(height: 16),

              // Daftar Add-Ons
              if (_addOns.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true, // Agar ListView tidak mengambil seluruh ruang
                  physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll di dalam ListView
                  itemCount: _addOns.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Add-On Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _addOns[index]['name'] = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Add-On Price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _addOns[index]['price'] =
                                    double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _addOns.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),

              // Tombol Add Menu Item jika ada add-ons
              if (_addOns.isNotEmpty)
                ElevatedButton(
                  onPressed: _addMenuItem,
                  child: const Text('Add Menu Item'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}