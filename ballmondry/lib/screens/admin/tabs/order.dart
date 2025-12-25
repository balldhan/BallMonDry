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
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
          var item = orders[index]; 

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(Icons.receipt_long, color: Colors.deepPurple, size: 24),
              ),
              title: Text(
                item['username'] ?? 'User', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              subtitle: Text(
                "${item['nama_layanan']} - ${item['status']}\n${item['tgl_order'] ?? ''}",
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepPurple),
              
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetail(orderData: item),
                  ),
                );
                fetchOrders();
              },
            ),
          );
        },
        ),
      ),
    );
  }
}