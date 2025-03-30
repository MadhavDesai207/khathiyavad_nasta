import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kathiayavad/services/database.dart';
import 'package:intl/intl.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final DatabaseService dbService = DatabaseService();

  /// Fetch all bills for a specific table
  Future<List<DocumentSnapshot>> _fetchBillsForTable(int tableNumber) async {
    return await dbService.getBillsForTable(tableNumber);
  }

  /// Fetch the total count of all bills across tables
  Future<int> _fetchTotalBillCount() async {
    int totalCount = 0;
    for (int i = 1; i <= 8; i++) {
      List<DocumentSnapshot> bills = await dbService.getBillsForTable(i);
      totalCount += bills.length;
    }
    return totalCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// **Total Bill Count at the Top**
          FutureBuilder<int>(
            future: _fetchTotalBillCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "Total Bills: ${snapshot.data}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          /// **List of Tables with Bills**
          Expanded(
            child: ListView.builder(
              itemCount: 8, // Fixed 8 tables
              itemBuilder: (context, index) {
                int tableNumber = index + 1;

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _fetchBillsForTable(tableNumber),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<DocumentSnapshot> bills = snapshot.data!;
                    if (bills.isEmpty) {
                      return const SizedBox.shrink(); // Hide if no bills for this table
                    }

                    /// **Grouping Bills by Date**
                    Map<String, List<DocumentSnapshot>> groupedBills = {};
                    for (var bill in bills) {
                      var billData = bill.data() as Map<String, dynamic>;
                      DateTime dateTime = (billData['timestamp'] as Timestamp).toDate();
                      String formattedDate = DateFormat('dd-MM-yy').format(dateTime);

                      if (!groupedBills.containsKey(formattedDate)) {
                        groupedBills[formattedDate] = [];
                      }
                      groupedBills[formattedDate]!.add(bill);
                    }

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 3,
                      child: ExpansionTile(
                        title: Text(
                          'Table $tableNumber  (Total Bills: ${bills.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        children: groupedBills.entries.map((entry) {
                          String date = entry.key;
                          List<DocumentSnapshot> billsForDate = entry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// **Date Header with Bill Count**
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "📅  $date",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    Text(
                                      "Bills: ${billsForDate.length}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),

                                /// **Bills for the Date**
                                ...billsForDate.map((bill) {
                                  var billData = bill.data() as Map<String, dynamic>;
                                  double totalAmount = billData['totalAmount'] ?? 0.0;
                                  bool isComplete = billData['complete'] ?? false;

                                  return ListTile(
                                    title: Text("Bill No: ${bill.id}",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Amount: ₹$totalAmount"),
                                    trailing: Text(
                                      isComplete ? "Completed" : "Pending",
                                      style: TextStyle(
                                        color: isComplete ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
