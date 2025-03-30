import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final CollectionReference billCollection =
      FirebaseFirestore.instance.collection('bills');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference menuCollection =
      FirebaseFirestore.instance.collection('menu_items');

  // Function to add a menu item to Firestore
  Future<void> addMenuItem(String name, double price) async {
    try {
      await menuCollection.add({
        'name': name,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Menu item added successfully!");
    } catch (e) {
      print("Error adding menu item: $e");
    }
  }

  // Function to fetch menu items from Firestore
  Stream<List<Map<String, dynamic>>> getMenuItems() {
    return menuCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'],
              'price': doc['price'],
            };
          }).toList(),
        );
  }

  // Function to save bill in Firestore
  Future<void> saveBill(
      int tableNumber, Map<String, dynamic> items, double totalAmount) async {
    String tableId = 'table_$tableNumber';
    CollectionReference tableCollection =
        _firestore.collection('bills').doc(tableId).collection('orders');

    // Fetch last bill number and auto-increment
    QuerySnapshot querySnapshot = await tableCollection.get();
    int billNumber = querySnapshot.docs.length + 1;

    await tableCollection.doc(billNumber.toString()).set({
      'items': items,
      'totalAmount': totalAmount,
      'complete': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Function to fetch the latest incomplete bill for a table
  Future<DocumentSnapshot?> getLatestBill(int tableNumber) async {
    String tableId = 'table_$tableNumber';
    CollectionReference tableCollection =
        _firestore.collection('bills').doc(tableId).collection('orders');

    QuerySnapshot querySnapshot = await tableCollection
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  Future<List<DocumentSnapshot>> getBillsForTable(int tableNumber) async {
    List<DocumentSnapshot> tableBills = [];
    String tableId = 'table_$tableNumber';

    // Reference to the 'orders' subcollection for the specified table
    CollectionReference tableCollection =
        _firestore.collection('bills').doc(tableId).collection('orders');

    QuerySnapshot orderSnapshot = await tableCollection.get();
    print("Table $tableId has ${orderSnapshot.docs.length} bills");

    // Add all fetched bills to the list
    tableBills.addAll(orderSnapshot.docs);

    for (var billDoc in orderSnapshot.docs) {
      print("Bill ID: ${billDoc.id}, Data: ${billDoc.data()}");
    }

    return tableBills;
  }

  // Function to complete a bill
  Future<void> completeBill(int tableNumber, String billId) async {
    String tableId = 'table_$tableNumber';
    DocumentReference billRef = _firestore
        .collection('bills')
        .doc(tableId)
        .collection('orders')
        .doc(billId);

    DocumentSnapshot billSnapshot = await billRef.get();

    if (billSnapshot.exists) {
      double totalAmount = billSnapshot['totalAmount'] ?? 0.0;

      await billRef.update({'complete': true});

      await _updateRevenue(totalAmount);
    }
  }

  /// **Update daily, weekly, and monthly revenue in admin/revenue**
  Future<void> _updateRevenue(double amount) async {
    DocumentReference revenueRef = _firestore.collection('admin').doc('revenue');

    DateTime now = DateTime.now();
    String year = DateFormat('yyyy').format(now);
    String month = DateFormat('MM').format(now);
    String day = DateFormat('dd').format(now);

    DocumentReference yearRef = _firestore.collection('admin').doc(year);
    DocumentReference monthRef = yearRef.collection('month').doc(month);
    DocumentReference dayRef = monthRef.collection('day').doc(day);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot revenueSnapshot = await transaction.get(revenueRef);
      DocumentSnapshot yearSnapshot = await transaction.get(yearRef);
      DocumentSnapshot monthSnapshot = await transaction.get(monthRef);
      DocumentSnapshot daySnapshot = await transaction.get(dayRef);

      double totalRevenue = revenueSnapshot.exists ? (revenueSnapshot['total'] ?? 0) : 0;
      double yearlyRevenue = yearSnapshot.exists ? (yearSnapshot['total'] ?? 0) : 0;
      double monthlyRevenue = monthSnapshot.exists ? (monthSnapshot['total'] ?? 0) : 0;
      double dailyRevenue = daySnapshot.exists ? (daySnapshot['total'] ?? 0) : 0;

      transaction.set(revenueRef, {"total": totalRevenue + amount}, SetOptions(merge: true));
      transaction.set(yearRef, {"total": yearlyRevenue + amount}, SetOptions(merge: true));
      transaction.set(monthRef, {"total": monthlyRevenue + amount}, SetOptions(merge: true));
      transaction.set(dayRef, {"total": dailyRevenue + amount}, SetOptions(merge: true));
    });
  }

  // fetch daily, weekly, and monthly revenue from admin/revenue**
  Future<Map<String, double>> fetchRevenue() async {
    DateTime now = DateTime.now();
    String year = DateFormat('yyyy').format(now);
    String month = DateFormat('MM').format(now);
    String day = DateFormat('dd').format(now);

    // Define Firestore references
    DocumentReference revenueRef = _firestore.collection('admin').doc('revenue');
    DocumentReference yearRef = _firestore.collection('admin').doc(year);
    DocumentReference monthRef = yearRef.collection('month').doc(month);
    DocumentReference dayRef = monthRef.collection('day').doc(day);

    try {
      // Fetch all revenue documents in parallel
      List<DocumentSnapshot> snapshots = await Future.wait([
        revenueRef.get(),
        yearRef.get(),
        monthRef.get(),
        dayRef.get(),
      ]);

      // Extract revenue data safely
      double totalRevenue = snapshots[0].exists ? (snapshots[0]['total'] ?? 0) : 0;
      double yearlyRevenue = snapshots[1].exists ? (snapshots[1]['total'] ?? 0) : 0;
      double monthlyRevenue = snapshots[2].exists ? (snapshots[2]['total'] ?? 0) : 0;
      double dailyRevenue = snapshots[3].exists ? (snapshots[3]['total'] ?? 0) : 0;

      return {
        "totalRevenue": totalRevenue,
        "yearlyRevenue": yearlyRevenue,
        "monthlyRevenue": monthlyRevenue,
        "dailyRevenue": dailyRevenue,
      };
    } catch (e) {
      print("Error fetching revenue: $e");
      return {
        "totalRevenue": 0,
        "yearlyRevenue": 0,
        "monthlyRevenue": 0,
        "dailyRevenue": 0,
      };
    }
  }
}
