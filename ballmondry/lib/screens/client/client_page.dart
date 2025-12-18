// lib/screens/client/client_page.dart
import 'package:flutter/material.dart';
import 'tabs/order.dart';
import 'tabs/profile.dart';
import '../../widgets/weather_widget.dart';

class ClientPage extends StatefulWidget {
  final int userId;
  const ClientPage({super.key, required this.userId});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  int _selectedIndex = 0; 

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // Tab 1: Order
      OrderTab(userId: widget.userId), 
      
      // Tab 2: Cuaca (Gunakan Widget Baru Disini)
      // Kita bungkus dengan SingleChildScrollView agar aman di HP kecil
      const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 10.0), // Beri jarak sedikit dari atas
          child: WeatherWidget(),
        ),
      ),            
      
      // Tab 3: Profile
      ProfileTab(userId: widget.userId),             
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ubah warna background sedikit abu-abu agar kartu cuaca terlihat menonjol
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("Area Pelanggan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Warna teks hitam agar elegan
        elevation: 0, // Hilangkan bayangan AppBar agar terlihat modern
        automaticallyImplyLeading: false, 
      ),
      body: _pages[_selectedIndex], 
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(Icons.local_laundry_service, color: Colors.blue),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud, color: Colors.blue),
            label: 'Cuaca',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}