import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.decimalPattern('id');

class MenuList extends StatefulWidget {
  const MenuList({super.key});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  List<Map<String, dynamic>> _menuItems = [];

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
        _menuItems = List<Map<String, dynamic>>.from(json.decode(menuData));
      });
    }
  }

  void _deleteMenuItem(String id) {
    setState(() {
      _menuItems.removeWhere((menu) => menu['id'] == id);
    });
    _saveMenuItems();
  }

  Future<void> _saveMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('menu_items', json.encode(_menuItems));
  }

  void _showDeleteConfirmationDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus menu "$name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _deleteMenuItem(id); // Hapus menu
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
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
        title: const Text('Menu List'),
      ),
      body: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final menuItem = _menuItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${menuItem['name']} - Rp ${currencyFormatter.format(menuItem['price'])}',
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text('Type: ${menuItem['type']}'),
                  if (menuItem['addOns'] != null && menuItem['addOns'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add-Ons:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...menuItem['addOns'].map<Widget>((addOn) {
                            return Text('- ${addOn['name']}: Rp ${currencyFormatter.format(addOn['price'])}');
                          }).toList(),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmationDialog(menuItem['id'], menuItem['name']),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}