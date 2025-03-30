import 'package:flutter/material.dart';
import 'package:kathiayavad/services/database.dart';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  /// **Add a new menu item (with validation & duplicate check)**
  void _addMenu() async {
    String name = _nameController.text.trim();
    String priceText = _priceController.text.trim();
    double? price = double.tryParse(priceText);

    // **Validation checks**
    if (name.isEmpty) {
      _showError("Item name cannot be empty!");
      return;
    }
    if (price == null || price <= 0) {
      _showError("Please enter a valid price!");
      return;
    }

    // **Check if item already exists**
    List<Map<String, dynamic>> menuItems = await _databaseService.getMenuItems().first;
    bool itemExists = menuItems.any((item) => item['name'].toLowerCase() == name.toLowerCase());

    if (itemExists) {
      _showError("Menu item '$name' already exists!");
      return;
    }

    // **If valid, add item to Firestore**
    await _databaseService.addMenuItem(name, price);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Menu item added successfully!")),
    );
    _nameController.clear();
    _priceController.clear();
  }

  /// **Show error message**
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Text Fields for Name & Price**
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 20),

            /// **Add Button**
            Center(
              child: ElevatedButton(
                onPressed: _addMenu,
                child: const Text("Add Menu Item"),
              ),
            ),
            const SizedBox(height: 20),

            /// **Title for Current Menu**
            const Text(
              "Current Menu:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// **Display Menu List**
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _databaseService.getMenuItems(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> menuItems = snapshot.data!;
                  if (menuItems.isEmpty) {
                    return const Center(child: Text("No menu items available."));
                  }

                  return ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      String name = menuItems[index]['name'];
                      double price = menuItems[index]['price'];

                      return Card(
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text("₹$price"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
