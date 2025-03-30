import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database.dart'; // Import DatabaseService

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseService _databaseService = DatabaseService();
  Future<Map<String, double>>? _revenueFuture; // Make it nullable

  @override
  void initState() {
    super.initState();
    _fetchRevenue(); // Initialize the future
  }

  void _fetchRevenue() {
    setState(() {
      _revenueFuture = _databaseService.fetchRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Scaffold(
      body: _revenueFuture == null
          ? const Center(child: CircularProgressIndicator()) // Show loader until initialized
          : FutureBuilder<Map<String, double>>(
        future: _revenueFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var revenue = snapshot.data!;
          double totalRevenue = revenue["totalRevenue"] ?? 0;
          double yearlyRevenue = revenue["yearlyRevenue"] ?? 0;
          double monthlyRevenue = revenue["monthlyRevenue"] ?? 0;
          double dailyRevenue = revenue["dailyRevenue"] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("💰 Total Revenue: ₹$totalRevenue",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                Text("📆 Yearly Revenue (${DateFormat('yyyy').format(now)}): ₹$yearlyRevenue",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("📅 Monthly Revenue (${DateFormat('MMMM yyyy').format(now)}): ₹$monthlyRevenue",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("📅 Today's Revenue: ₹$dailyRevenue",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
