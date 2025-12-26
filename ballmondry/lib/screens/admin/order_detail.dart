import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
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

  // --- VERIFIKASI PEMBAYARAN ---
  Future<void> verifikasiPembayaran(String statusPembayaran, {double? jumlahDibayar}) async {
    try {
      Map<String, dynamic> body = {
        "order_id": order['id'],
        "status_pembayaran": statusPembayaran,
      };
      
      // Tambahkan jumlah_dibayar jika ada (untuk COD)
      if (jumlahDibayar != null) {
        body['jumlah_dibayar'] = jumlahDibayar;
      }
      
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/order/payment/verifikasi'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        
        setState(() {
          order['status_pembayaran'] = statusPembayaran;
          if (result['jumlah_dibayar'] != null) {
            order['jumlah_dibayar'] = result['jumlah_dibayar'];
          }
          if (result['kembalian'] != null) {
            order['kembalian'] = result['kembalian'];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Pembayaran ${statusPembayaran == 'Lunas' ? 'Disetujui' : 'Ditolak'}"),
              backgroundColor: statusPembayaran == 'Lunas' ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        var msg = jsonDecode(response.body)['message'] ?? 'Gagal verifikasi';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Error verifikasi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
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

  // Dialog Input Pembayaran COD
  void _showCODPaymentDialog() {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    TextEditingController jumlahBayarController = TextEditingController();
    double kembalian = 0;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text("Pembayaran COD")),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Total Harga
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Harga:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currency.format(order['total_harga']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input Jumlah Dibayar
                  TextField(
                    controller: jumlahBayarController,
                    decoration: InputDecoration(
                      labelText: "Jumlah Dibayar",
                      hintText: "Masukkan nominal yang dibayarkan",
                      prefixText: "Rp ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: "Pas",
                        onPressed: () {
                          jumlahBayarController.text = order['total_harga'].toString();
                          setStateDialog(() {
                            kembalian = 0;
                          });
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      double dibayar = double.tryParse(value) ?? 0;
                      double totalHarga = (order['total_harga'] ?? 0).toDouble();
                      setStateDialog(() {
                        kembalian = dibayar - totalHarga;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Kembalian
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kembalian < 0 
                          ? Colors.red.shade50 
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kembalian < 0 
                            ? Colors.red.shade200 
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              kembalian < 0 ? Icons.error_outline : Icons.change_circle,
                              color: kembalian < 0 ? Colors.red[700] : Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              kembalian < 0 ? "Kurang:" : "Kembalian:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kembalian < 0 ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currency.format(kembalian.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kembalian < 0 ? Colors.red[800] : Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (kembalian < 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Jumlah dibayar tidak boleh kurang dari total harga",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Quick Amount Buttons
                  const SizedBox(height: 16),
                  const Text(
                    "Nominal Cepat:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [50000, 100000, 150000, 200000, 500000].map((nominal) {
                      return InkWell(
                        onTap: () {
                          jumlahBayarController.text = nominal.toString();
                          double totalHarga = (order['total_harga'] ?? 0).toDouble();
                          setStateDialog(() {
                            kembalian = nominal.toDouble() - totalHarga;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Text(
                            currency.format(nominal),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: kembalian < 0 || jumlahBayarController.text.isEmpty
                    ? null
                    : () {
                        double jumlahDibayar = double.parse(jumlahBayarController.text);
                        Navigator.pop(ctx);
                        verifikasiPembayaran('Lunas', jumlahDibayar: jumlahDibayar);
                      },
                child: const Text("Konfirmasi Pembayaran"),
              ),
            ],
          );
        },
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
                    _buildRow(Icons.phone, "No HP", order['no_hp'] ?? '-'),
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
            const SizedBox(height: 20),

            // Section Pembayaran
            if (order['total_harga'] != null && order['total_harga'] > 0) ...[
              const Text("Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                color: order['status_pembayaran'] == 'Lunas' 
                    ? Colors.green.shade50 
                    : order['status_pembayaran'] == 'Menunggu Verifikasi'
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: order['status_pembayaran'] == 'Lunas'
                        ? Colors.green.shade200
                        : order['status_pembayaran'] == 'Menunggu Verifikasi'
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            order['status_pembayaran'] == 'Lunas'
                                ? Icons.check_circle
                                : order['status_pembayaran'] == 'Menunggu Verifikasi'
                                    ? Icons.hourglass_empty
                                    : Icons.error_outline,
                            color: order['status_pembayaran'] == 'Lunas'
                                ? Colors.green
                                : order['status_pembayaran'] == 'Menunggu Verifikasi'
                                    ? Colors.orange
                                    : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Status: ${order['status_pembayaran'] ?? 'Belum Bayar'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: order['status_pembayaran'] == 'Lunas'
                                        ? Colors.green.shade800
                                        : order['status_pembayaran'] == 'Menunggu Verifikasi'
                                            ? Colors.orange.shade800
                                            : Colors.red.shade800,
                                  ),
                                ),
                                if (order['metode_pembayaran'] != null)
                                  Text(
                                    "Metode: ${order['metode_pembayaran']}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                // Tampilkan detail pembayaran COD jika ada
                                if (order['jumlah_dibayar'] != null && 
                                    order['metode_pembayaran'] == 'COD') ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Dibayar: ${currency.format(order['jumlah_dibayar'])}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (order['kembalian'] != null && order['kembalian'] > 0)
                                    Text(
                                      "Kembalian: ${currency.format(order['kembalian'])}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Jika ada bukti transfer
                      if (order['bukti_transfer'] != null && 
                          order['status_pembayaran'] == 'Menunggu Verifikasi') ...[
                        const Divider(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Bukti Transfer:",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.zoom_in, size: 18),
                                    label: const Text('Perbesar'),
                                    onPressed: () {
                                      // Show full screen image
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => Dialog(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppBar(
                                                title: const Text('Bukti Transfer'),
                                                automaticallyImplyLeading: false,
                                                actions: [
                                                  IconButton(
                                                    icon: const Icon(Icons.close),
                                                    onPressed: () => Navigator.pop(ctx),
                                                  ),
                                                ],
                                              ),
                                              Expanded(
                                                child: InteractiveViewer(
                                                  child: _buildImageFromBase64(order['bukti_transfer']),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: _buildImageFromBase64(order['bukti_transfer']),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Tombol Verifikasi
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Tolak Pembayaran?"),
                                      content: const Text("Bukti transfer tidak valid?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Batal"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            verifikasiPembayaran('Belum Bayar');
                                          },
                                          child: const Text("Tolak"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.close),
                                label: const Text("Tolak"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Setujui Pembayaran?"),
                                      content: const Text("Konfirmasi pembayaran sudah diterima?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Batal"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            verifikasiPembayaran('Lunas');
                                          },
                                          child: const Text("Setujui"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text("Setujui"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Tombol Manual Ubah Status (untuk COD atau kasus lainnya)
                      if (order['status_pembayaran'] != 'Lunas') ...[
                        const Divider(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Cek apakah metode pembayaran COD
                              bool isCOD = order['metode_pembayaran'] == 'COD';
                              
                              if (isCOD) {
                                // Untuk COD, tampilkan dialog input jumlah dibayar
                                _showCODPaymentDialog();
                              } else {
                                // Untuk non-COD (Transfer yang belum upload bukti), langsung tandai lunas
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Ubah Status Pembayaran"),
                                    content: const Text(
                                      "Tandai pembayaran sebagai Lunas?\n\n"
                                      "Gunakan ini untuk:\n"
                                      "• Pembayaran langsung/tunai\n"
                                      "• Transfer manual tanpa bukti"
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          verifikasiPembayaran('Lunas');
                                        },
                                        child: const Text("Tandai Lunas"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              order['metode_pembayaran'] == 'COD' 
                                  ? "Input Pembayaran COD" 
                                  : "Tandai Sebagai Lunas"
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

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

  // Helper method untuk decode base64 image
  Widget _buildImageFromBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Gambar tidak tersedia', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    try {
      // Remove data URI prefix if exists
      String base64Image = base64String;
      if (base64String.contains(',')) {
        base64Image = base64String.split(',')[1];
      }

      Uint8List bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 8),
                Text('Gagal memuat gambar', style: TextStyle(color: Colors.red[600])),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange[300]),
            const SizedBox(height: 8),
            Text('Format gambar tidak valid', style: TextStyle(color: Colors.orange[600])),
          ],
        ),
      );
    }
  }
}