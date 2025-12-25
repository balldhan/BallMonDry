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
      print("🔍 Fetching stats from: ${Config.baseUrl}/admin/stats");
      final response = await http.get(Uri.parse('${Config.baseUrl}/admin/stats'));
      print("📊 Response status: ${response.statusCode}");
      print("📊 Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        setState(() {
          stats = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Error: Status ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) { 
      print("❌ Exception: $e"); 
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() { super.initState(); fetchStats(); }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.white, Colors.purple.shade50],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Dashboard Statistik",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Ringkasan data laundry Anda",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),
              _buildStatCard(
                "Total Pendapatan", 
                "Rp ${stats['total_pendapatan'] ?? 0}", 
                Colors.green, 
                Icons.account_balance_wallet,
                isLarge: true,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total Order", 
                      "${stats['total_order'] ?? 0}", 
                      Colors.deepPurple, 
                      Icons.shopping_bag,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      "Proses", 
                      "${stats['order_proses'] ?? 0}", 
                      Colors.orange, 
                      Icons.hourglass_empty,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildStatCard(
                "Order Selesai", 
                "${stats['order_selesai'] ?? 0}", 
                Colors.blue, 
                Icons.check_circle,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool isLarge = false}) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isLarge ? 25 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15), 
              color.withOpacity(0.05),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: isLarge ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: isLarge ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (isLarge)
                  Text(
                    title, 
                    style: TextStyle(
                      color: Colors.grey[700], 
                      fontWeight: FontWeight.w600, 
                      fontSize: 16,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: isLarge ? 32 : 28),
                ),
              ],
            ),
            SizedBox(height: isLarge ? 15 : 12),
            if (!isLarge)
              Text(
                title, 
                style: TextStyle(
                  color: Colors.grey[700], 
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: isLarge ? 8 : 5),
            Text(
              value, 
              style: TextStyle(
                fontSize: isLarge ? 28 : 24, 
                fontWeight: FontWeight.bold, 
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}