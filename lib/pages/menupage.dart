import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kathiayavad/services/database.dart';

class MenuPage extends StatefulWidget {
  final int tableNumber;
  const MenuPage({super.key, required this.tableNumber});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Map<String, int> orderQuantities = {};
  final DatabaseService _databaseService = DatabaseService();
  String? activeBillId;
  bool isLoading = true;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingBill();
  }

  Future<void> _loadExistingBill() async {
    DocumentSnapshot? billSnapshot = await _databaseService.getLatestBill(widget.tableNumber);
    if (billSnapshot != null && !(billSnapshot['complete'] ?? false)) {
      setState(() {
        activeBillId = billSnapshot.id;
        orderQuantities = Map<String, int>.from(
            (billSnapshot['items'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value['quantity'])));
        totalAmount = billSnapshot['totalAmount'] ?? 0.0;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void _incrementQuantity(String itemId) {
    setState(() {
      orderQuantities[itemId] = (orderQuantities[itemId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String itemId) {
    setState(() {
      if (orderQuantities[itemId] != null && orderQuantities[itemId]! > 0) {
        orderQuantities[itemId] = orderQuantities[itemId]! - 1;
        if (orderQuantities[itemId] == 0) {
          orderQuantities.remove(itemId);
        }
      }
    });
  }

  double _calculateTotal(List<Map<String, dynamic>> menuItems) {
    double total = 0.0;
    orderQuantities.forEach((itemId, quantity) {
      var item = menuItems.firstWhere((item) => item['id'] == itemId, orElse: () => {});
      if (item.isNotEmpty) {
        total += quantity * (item['price'] ?? 0);
      }
    });
    return total;
  }

  Future<void> _saveBillToFirestore(List<Map<String, dynamic>> menuItems) async {
    if (orderQuantities.isNotEmpty) {
      Map<String, dynamic> billItems = {};
      orderQuantities.forEach((itemId, quantity) {
        var item = menuItems.firstWhere((item) => item['id'] == itemId, orElse: () => {});
        if (item.isNotEmpty) {
          billItems[itemId] = {
            'name': item['name'],
            'quantity': quantity,
            'price': item['price'],
          };
        }
      });

      double totalAmount = _calculateTotal(menuItems);
      await _databaseService.saveBill(widget.tableNumber, billItems, totalAmount);
      setState(() {
        this.totalAmount = totalAmount;
      });
    }
  }

  Future<void> _completeBill() async {
    if (activeBillId != null) {
      await _databaseService.completeBill(widget.tableNumber, activeBillId!);
      setState(() {
        orderQuantities.clear();
        totalAmount = 0.0;
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu - Table ${widget.tableNumber}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No menu items available."));
          }

          List<Map<String, dynamic>> menuItems = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    var item = menuItems[index];
                    String itemId = item['id'];
                    String itemName = item['name'];
                    double price = item['price'];
                    int quantity = orderQuantities[itemId] ?? 0;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text("Price: ₹$price"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _decrementQuantity(itemId),
                              icon: const Icon(Icons.remove, color: Colors.red),
                            ),
                            Text('$quantity', style: const TextStyle(fontSize: 18)),
                            IconButton(
                              onPressed: () => _incrementQuantity(itemId),
                              icon: const Icon(Icons.add, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// **🔹 Order Summary Card**
              if (orderQuantities.isNotEmpty)
                Card(
                  elevation: 5,
                  margin: const EdgeInsets.all(10),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Summary",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        Column(
                          children: orderQuantities.entries.map((entry) {
                            String itemId = entry.key;
                            int quantity = entry.value;
                            var item = menuItems.firstWhere((item) => item['id'] == itemId, orElse: () => {});
                            double price = item['price'] ?? 0;
                            double totalItemPrice = price * quantity;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  /// **Item Name (Left)**
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      item['name'],
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  /// **Price × Quantity (Center)**
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${price.toInt()} × $quantity",
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  /// **Total Price (Right)**
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "= ₹${totalItemPrice.toInt()}",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              /// **🔹 Total & Buttons**
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      "Total: ₹${_calculateTotal(menuItems).toInt()}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _saveBillToFirestore(menuItems),
                          child: const Text("Save Bill"),
                        ),
                        ElevatedButton(
                          onPressed: _completeBill,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Complete Bill", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
