import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../config.dart'; 
import '../order_detail.dart'; 

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  List orders = [];
  List filteredOrders = [];
  bool isLoading = true;
  
  // Filter & Search State
  TextEditingController searchController = TextEditingController();
  String selectedStatus = 'semua';
  String selectedPeriod = 'semua';
  String selectedPaymentStatus = 'semua';

  @override
  void initState() {
    super.initState();
    fetchOrders();
    searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/orders'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            orders = jsonDecode(response.body);
            isLoading = false;
            _filterOrders();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = orders.where((order) {
        // Filter by search
        String username = (order['username'] ?? '').toString().toLowerCase();
        String searchQuery = searchController.text.toLowerCase();
        bool matchSearch = username.contains(searchQuery);

        // Filter by status
        bool matchStatus = selectedStatus == 'semua' || order['status'] == selectedStatus;

        // Filter by payment status
        bool matchPaymentStatus = selectedPaymentStatus == 'semua' || 
                                  order['status_pembayaran'] == selectedPaymentStatus;

        // Filter by period
        bool matchPeriod = true;
        if (selectedPeriod != 'semua' && order['tgl_order'] != null) {
          try {
            DateTime orderDate = DateTime.parse(order['tgl_order']);
            DateTime now = DateTime.now();
            
            switch (selectedPeriod) {
              case 'hari_ini':
                matchPeriod = orderDate.year == now.year &&
                             orderDate.month == now.month &&
                             orderDate.day == now.day;
                break;
              case 'minggu_ini':
                DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                matchPeriod = orderDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
                break;
              case 'bulan_ini':
                matchPeriod = orderDate.year == now.year && orderDate.month == now.month;
                break;
            }
          } catch (e) {
            matchPeriod = true;
          }
        }

        return matchSearch && matchStatus && matchPaymentStatus && matchPeriod;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama pelanggan...',
                    prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Filter Dropdowns - Scrollable
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Dropdown
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 'semua', child: Text('📋 Semua Status')),
                              DropdownMenuItem(value: 'menunggu konfirmasi', child: Text('⏳ Menunggu')),
                              DropdownMenuItem(value: 'konfirmasi', child: Text('✅ Dikonfirmasi')),
                              DropdownMenuItem(value: 'dijemput', child: Text('🚗 Dijemput')),
                              DropdownMenuItem(value: 'diproses', child: Text('⚙️ Diproses')),
                              DropdownMenuItem(value: 'selesai', child: Text('✔️ Selesai')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                                _filterOrders();
                              });
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Period Dropdown
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPeriod,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 'semua', child: Text('📅 Semua Waktu')),
                              DropdownMenuItem(value: 'hari_ini', child: Text('📍 Hari Ini')),
                              DropdownMenuItem(value: 'minggu_ini', child: Text('📆 Minggu Ini')),
                              DropdownMenuItem(value: 'bulan_ini', child: Text('📊 Bulan Ini')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedPeriod = value!;
                                _filterOrders();
                              });
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Payment Status Dropdown
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPaymentStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 'semua', child: Text('💳 Semua Pembayaran')),
                              DropdownMenuItem(value: 'Belum Bayar', child: Text('❌ Belum Bayar')),
                              DropdownMenuItem(value: 'Menunggu Verifikasi', child: Text('⏳ Menunggu Verifikasi')),
                              DropdownMenuItem(value: 'Lunas', child: Text('✅ Lunas')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentStatus = value!;
                                _filterOrders();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Menampilkan ${filteredOrders.length} dari ${orders.length} pesanan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Order List
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada pesanan ditemukan',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        var item = filteredOrders[index];

                        // Format tanggal
                        String tanggalFormatted = '-';
                        try {
                          if (item['tgl_order'] != null) {
                            DateTime tglOrder = DateTime.parse(item['tgl_order']);
                            tanggalFormatted = DateFormat('dd MMM yyyy HH:mm').format(tglOrder);
                          }
                        } catch (e) {
                          tanggalFormatted = item['tgl_order'] ?? '-';
                        }

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
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['username'] ?? 'User',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                // Badge Pembayaran
                                if (item['status_pembayaran'] != null && 
                                    item['total_harga'] != null && 
                                    item['total_harga'] > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item['status_pembayaran'] == 'Lunas'
                                          ? Colors.green
                                          : item['status_pembayaran'] == 'Menunggu Verifikasi'
                                              ? Colors.orange
                                              : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item['status_pembayaran'] == 'Lunas'
                                              ? Icons.check_circle
                                              : Icons.payment,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          item['status_pembayaran'] == 'Lunas'
                                              ? 'LUNAS'
                                              : item['status_pembayaran'] == 'Menunggu Verifikasi'
                                                  ? 'VERIF'
                                                  : 'BAYAR',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              "${item['nama_layanan']} - ${item['status']}\n$tanggalFormatted",
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
          ),
        ],
      ),
    );
  }
}