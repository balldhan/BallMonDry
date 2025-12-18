import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/admin/stats'));
      if (response.statusCode == 200) {
        setState(() {
          stats = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) { print(e); }
  }

  @override
  void initState() { super.initState(); fetchStats(); }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatCard("Total Pendapatan", "Rp ${stats['total_pendapatan'] ?? 0}", Colors.green, Icons.monetization_on),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard("Total Order", "${stats['total_order'] ?? 0}", Colors.blue, Icons.shopping_bag)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard("Proses", "${stats['order_proses'] ?? 0}", Colors.orange, Icons.loop)),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatCard("Order Selesai", "${stats['order_selesai'] ?? 0}", Colors.purple, Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: color.withOpacity(0.1)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}