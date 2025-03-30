import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kathiayavad/pages/AdminPage.dart';
import 'package:kathiayavad/pages/homepage.dart';
import 'package:kathiayavad/pages/add_menu.dart';
import 'package:kathiayavad/pages/BillsPage.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const AddMenuPage(),
    const BillsPage(),
    const AdminPage(),
  ];

  final List<String> _titles = [
    "Home",
    "Add Menu",
    "Bills",
    "Admin",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Closes the drawer after selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Dynamic title based on selected page
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/food_plate.png', // Path to your image
                      width: double.infinity, // Make it as wide as possible
                      height: double.infinity, // Use full available height
                      fit: BoxFit.cover, // Cover the area nicely
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Add Menu'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Bills'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Admin'),
              onTap: () => _onItemTapped(3),
            ),
          ],
        ),
      ),

      body: _pages[_selectedIndex], // Displays the selected page
    );
  }
}
