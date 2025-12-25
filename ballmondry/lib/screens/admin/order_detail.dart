import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class OrderDetail extends StatefulWidget {
  final Map orderData;
  const OrderDetail({super.key, required this.orderData});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  late Map order; 

  @override
  void initState() {
    super.initState();
    order = widget.orderData;
  }

  // --- LOGIC UPDATE ORDER ---
  Future<void> updateOrder(String status, String beratStr, String estimasi) async {
    // Validasi input berat (ubah koma jadi titik jika ada, lalu parse)
    double berat = double.tryParse(beratStr.replaceAll(',', '.')) ?? 0.0;

    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/order/update'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": order['id'], // Pastikan key ini 'order_id' sesuai backend
          "status": status, 
          "berat": berat, 
          "estimasi": estimasi
        }),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        
        setState(() {
          order['status'] = status;
          order['berat'] = berat;
          order['estimasi'] = estimasi;
          // Update total harga yang dikirim balik oleh backend
          if (result['detail'] != null) {
            order['total_harga'] = result['detail']['total_final'];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Tersimpan!"), backgroundColor: Colors.green));
        }
      } else {
         var msg = jsonDecode(response.body)['message'] ?? "Gagal Update";
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $msg"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error koneksi: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- DIALOG UPDATE (DIPERBAIKI OVERFLOW-NYA) ---
  void showUpdateDialog() {
    TextEditingController beratController = TextEditingController(text: order['berat'].toString());
    TextEditingController estimasiController = TextEditingController(text: order['estimasi'] == "-" ? "" : order['estimasi']);
    String selectedStatus = order['status'];
    
    // List status yang valid
    List<String> statuses = ['menunggu konfirmasi', 'dijemput', 'proses', 'selesai', 'konfirmasi'];
    if (!statuses.contains(selectedStatus)) selectedStatus = statuses[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Proses Order"),
        content: SingleChildScrollView( // Tambah ini agar tidak error saat keyboard muncul
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PERBAIKAN OVERFLOW: isExpanded: true
              DropdownButtonFormField<String>(
                value: selectedStatus,
                isExpanded: true, // AGAR TIDAK OVERFLOW KE SAMPING
                items: statuses.map((s) => DropdownMenuItem(
                  value: s, 
                  child: Text(
                    s.toUpperCase(), 
                    overflow: TextOverflow.ellipsis, // POTONG TEKS JIKA KEPANJANGAN
                    style: const TextStyle(fontSize: 14)
                  )
                )).toList(),
                onChanged: (v) => selectedStatus = v.toString(),
                decoration: const InputDecoration(labelText: "Status Cucian", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: beratController, 
                decoration: const InputDecoration(labelText: "Berat (Kg)", suffixText: "Kg", border: OutlineInputBorder()), 
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: estimasiController, 
                decoration: const InputDecoration(labelText: "Estimasi Selesai", hintText: "Cth: Besok Sore / 20 Okt", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog dulu
              // Kirim data ke fungsi update
              updateOrder(selectedStatus, beratController.text, estimasiController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text("SIMPAN"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format mata uang agar rapi (Rp 10.000)
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    // Parsing tanggal aman
    DateTime tglOrder;
    try {
      tglOrder = DateTime.parse(order['tgl_order']);
    } catch (e) {
      tglOrder = DateTime.now();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Chip(
                label: Text(order['status'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: _getStatusColor(order['status']),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Informasi Pelanggan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow(Icons.person, "Nama", order['username'] ?? '-'),
                    const Divider(),
                    _buildRow(Icons.phone, "No HP", order['no_telepon'] ?? '-'),
                    const Divider(),
                    _buildRow(Icons.location_on, "Alamat", order['alamat'] ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Detail Layanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow(Icons.local_laundry_service, "Layanan", order['nama_layanan'] ?? '-'),
                    const Divider(),
                    _buildRow(Icons.settings, "Tipe", order['tipe_layanan'].toString().toUpperCase()),
                    const Divider(),
                    _buildRow(Icons.directions_car, "Antar-Jemput", (order['is_pickup'] == 1 || order['is_pickup'] == true) ? "YA (+Rp 7rb)" : "TIDAK"),
                    const Divider(),
                    _buildRow(Icons.calendar_today, "Tanggal Masuk", DateFormat('dd MMM yyyy HH:mm').format(tglOrder)),
                    const Divider(),
                    _buildRow(Icons.timer, "Estimasi Selesai", order['estimasi'] ?? "-"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Tagihan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              color: Colors.deepPurple.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.deepPurple.shade100)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow(Icons.scale, "Berat Cucian", "${order['berat']} Kg"),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL HARGA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                        Text(currency.format(order['total_harga']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showUpdateDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text("Update Status / Berat", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 15),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'selesai') return Colors.green;
    if (status == 'diproses') return Colors.orange;
    if (status == 'menunggu konfirmasi') return Colors.red;
    return Colors.blue;
  }
}