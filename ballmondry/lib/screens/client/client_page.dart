// lib/screens/client/client_page.dart
import 'package:flutter/material.dart';
import '../../services/chat_service.dart'; // Import Chat Service
import '../chat/chat_page.dart'; // Import Chat Page
import 'tabs/order.dart';
import 'tabs/profile.dart';
import '../../widgets/weather_widget.dart';

class ClientPage extends StatefulWidget {
  final int userId;
  final String? username;
  const ClientPage({super.key, required this.userId, this.username});

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
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("BallMonDry", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatId: widget.userId.toString(),
                    isViewerAdmin: false,
                    chatTitle: "Chat Admin",
                    currenUserDisplayName: widget.username ?? "User",
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: "Chat Admin",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex], 
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.deepPurple.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(Icons.local_laundry_service, color: Colors.deepPurple),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud, color: Colors.deepPurple),
            label: 'Cuaca',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.deepPurple),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}