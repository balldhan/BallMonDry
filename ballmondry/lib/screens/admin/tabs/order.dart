import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart'; // Pastikan path config benar
import '../order_detail.dart'; // Pastikan path ke halaman detail benar

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/orders'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            orders = jsonDecode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orders.isEmpty) {
      return const Center(child: Text("Belum ada pesanan masuk"));
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          // --- BAGIAN INI YANG SEBELUMNYA HILANG/ERROR ---
          var item = orders[index]; 
          // -----------------------------------------------

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: const Icon(Icons.receipt_long, color: Colors.indigo),
              ),
              // Mengambil data dari variabel 'item'
              title: Text(
                item['username'] ?? 'User', 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: Text(
                "${item['nama_layanan']} - ${item['status']}\n${item['tgl_order'] ?? ''}",
                style: const TextStyle(height: 1.5),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              
              // Navigasi ke Detail
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Pastikan nama class ini sama dengan file order_detail_screen.dart
                    builder: (context) => OrderDetail(orderData: item),
                  ),
                );
                // Refresh data setelah kembali dari halaman detail
                fetchOrders();
              },
            ),
          );
        },
      ),
    );
  }
}