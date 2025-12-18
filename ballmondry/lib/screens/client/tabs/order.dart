// lib/screens/client/tabs/order_tab.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class OrderTab extends StatefulWidget {
  final int userId;
  const OrderTab({super.key, required this.userId});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  List riwayat = [];
  List layananList = [];

  @override
  void initState() {
    super.initState();
    fetchLayanan();
    fetchRiwayat();
  }

  // --- 1. API CALLS (GET, POST, PUT, DELETE) ---

  Future<void> fetchLayanan() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/layanan'));
      if (response.statusCode == 200) {
        if (mounted) setState(() { layananList = jsonDecode(response.body); });
      }
    } catch (e) { print("Error fetch layanan: $e"); }
  }

  Future<void> fetchRiwayat() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/history/${widget.userId}'));
      if (response.statusCode == 200) {
        if (mounted) setState(() { riwayat = jsonDecode(response.body); });
      }
    } catch (e) { print("Error fetch riwayat: $e"); }
  }

  Future<void> createOrder(int idLayanan, String tipe, bool pickup) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/order'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId, "layanan_id": idLayanan, "tipe_layanan": tipe, "is_pickup": pickup}),
      );
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
           Navigator.pop(context); // Tutup Dialog
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Berhasil!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) { print(e); }
  }

  Future<void> updateOrder(int orderId, int idLayanan, String tipe, bool pickup) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/order/edit-client'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"order_id": orderId, "layanan_id": idLayanan, "tipe_layanan": tipe, "is_pickup": pickup}),
      );
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
           Navigator.pop(context); // Tutup Form Edit
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Berhasil Diupdate!"), backgroundColor: Colors.blue));
        }
      } else {
         var msg = jsonDecode(response.body)['message'];
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) { print(e); }
  }

  Future<void> deleteOrder(int id) async {
    try {
      final response = await http.delete(Uri.parse('${Config.baseUrl}/order/$id'));
      if (response.statusCode == 200) {
        fetchRiwayat();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan dibatalkan"), backgroundColor: Colors.orange));
      } else {
        var msg = jsonDecode(response.body)['message'];
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) { print(e); }
  }

  // --- 2. LOGIKA PILIHAN AKSI (POPUP SAAT KLIK KARTU) ---
  
  void showActionOptions(Map order) {
    // Cek apakah status masih bisa diedit?
    bool isEditable = order['status'] == 'menunggu konfirmasi';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(
                isEditable ? "Kelola Pesanan" : "Detail Pesanan", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 10),
              
              if (!isEditable)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pesanan sedang ${order['status']}, sudah tidak bisa diedit atau dibatalkan.",
                          style: TextStyle(color: Colors.orange[800], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),

              if (isEditable) ...[
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.edit, color: Colors.white, size: 20)),
                  title: const Text("Edit Pesanan"),
                  subtitle: const Text("Ubah layanan atau metode antar"),
                  onTap: () {
                    Navigator.pop(context); // Tutup BottomSheet
                    showOrderDialog(orderToEdit: order); // Buka Form Edit
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete, color: Colors.white, size: 20)),
                  title: const Text("Batalkan Pesanan"),
                  subtitle: const Text("Hapus pesanan ini secara permanen"),
                  onTap: () {
                    Navigator.pop(context); // Tutup BottomSheet
                    // Konfirmasi Hapus
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Batalkan Order?"),
                      content: const Text("Apakah Anda yakin ingin menghapus pesanan ini?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TIDAK")),
                        TextButton(onPressed: () { Navigator.pop(ctx); deleteOrder(order['id']); }, child: const Text("YA, HAPUS", style: TextStyle(color: Colors.red))),
                      ],
                    ));
                  },
                ),
              ] else ...[
                 ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.close, color: Colors.white, size: 20)),
                  title: const Text("Tutup"),
                  onTap: () => Navigator.pop(context),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  // --- 3. FORM ORDER (BISA UNTUK BARU / EDIT) ---

  void showOrderDialog({Map? orderToEdit}) {
    // Mode Edit jika orderToEdit tidak null
    bool isEditMode = orderToEdit != null;
    
    // Setup Data Awal
    int? selectedLayananId = isEditMode ? orderToEdit['layanan_id'] : null;
    String tipe = isEditMode ? orderToEdit['tipe_layanan'] : 'reguler';
    
    // Parsing Pickup (Database kadang 1/0, kadang true/false)
    bool isPickup = false;
    if (isEditMode) {
      var p = orderToEdit['is_pickup'];
      isPickup = (p == 1 || p == true);
    }

    // Cari Data Layanan Awal (Untuk hitung harga saat pertama buka edit)
    Map? selectedLayananData;
    if (isEditMode && layananList.isNotEmpty) {
      try {
        selectedLayananData = layananList.firstWhere((e) => e['id'] == selectedLayananId);
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // LOGIKA HITUNG HARGA
            int hargaPerKg = 0;
            if (selectedLayananData != null) {
              hargaPerKg = (tipe == 'reguler') 
                  ? selectedLayananData!['harga_reguler'] 
                  : selectedLayananData!['harga_express'];
            }
            int biayaJemput = isPickup ? 7000 : 0;

            return AlertDialog(
              title: Text(isEditMode ? "Edit Pesanan" : "Buat Pesanan Baru"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pilih Paket Laundry:", style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text("- Pilih Layanan -"),
                      value: selectedLayananId,
                      items: layananList.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(item['nama_layanan']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedLayananId = val;
                          selectedLayananData = layananList.firstWhere((element) => element['id'] == val);
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    const Text("Tipe Layanan:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: RadioListTile(title: const Text("Reguler", style: TextStyle(fontSize: 14)), value: "reguler", groupValue: tipe, contentPadding: EdgeInsets.zero, onChanged: (val) => setStateDialog(() => tipe = val.toString()))),
                        Expanded(child: RadioListTile(title: const Text("Express", style: TextStyle(fontSize: 14)), value: "express", groupValue: tipe, contentPadding: EdgeInsets.zero, onChanged: (val) => setStateDialog(() => tipe = val.toString()))),
                      ],
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Harga Paket:"), Text("Rp $hargaPerKg /kg", style: const TextStyle(fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 5),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Biaya Jemput:"), Text(isPickup ? "+ Rp 7.000" : "Rp 0", style: TextStyle(fontWeight: FontWeight.bold, color: isPickup ? Colors.red : Colors.green))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text("Jemput Pakaian?"),
                      subtitle: Text(isPickup ? "Kurir akan datang" : "Antar sendiri ke outlet"),
                      value: isPickup,
                      activeThumbColor: Colors.deepPurple,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateDialog(() => isPickup = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: selectedLayananId == null ? null : () {
                    // Panggil fungsi Update atau Create
                    if (isEditMode) {
                      updateOrder(orderToEdit['id'], selectedLayananId!, tipe, isPickup);
                    } else {
                      createOrder(selectedLayananId!, tipe, isPickup);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: Text(isEditMode ? "SIMPAN PERUBAHAN" : "ORDER SEKARANG"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 4. TAMPILAN UTAMA (BUILD) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: const Text("Riwayat Pesanan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: riwayat.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Belum ada pesanan", style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      var r = riwayat[index];
                      bool isPickup = (r['is_pickup'] == 1 || r['is_pickup'] == true);

                      // LOGIKA WARNA STATUS
                      Color statusColor;
                      String statusText = r['status'].toString();
                      switch (statusText) {
                        case 'menunggu konfirmasi': statusColor = Colors.grey; break;
                        case 'dikonfirmasi': statusColor = Colors.blue; break;
                        case 'dijemput': statusColor = Colors.orange; break;
                        case 'diproses': statusColor = Colors.purple; break;
                        case 'selesai': statusColor = Colors.green; break;
                        default: statusColor = Colors.black;
                      }

                      // DISINI PERUBAHANNYA: CARD DIBUNGKUS INKWELL AGAR BISA DIKLIK
                      return Card(
                        clipBehavior: Clip.hardEdge, // Agar efek klik tidak keluar sudut tumpul
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: InkWell(
                          // SAAT DIKLIK -> MUNCUL POPUP OPSI
                          onTap: () => showActionOptions(r),
                          splashColor: Colors.deepPurple.withAlpha(30),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['nama_layanan'] ?? 'Paket', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                                      child: Text(statusText.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 5),
                                    Text("Tipe: ${r['tipe_layanan']?.toUpperCase() ?? '-'}", style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                                    const SizedBox(width: 15),
                                    Icon(isPickup ? Icons.delivery_dining : Icons.store, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 5),
                                    Text(isPickup ? "Dijemput" : "Antar Sendiri", style: TextStyle(color: isPickup ? Colors.deepPurple : Colors.grey[800], fontSize: 13, fontWeight: isPickup ? FontWeight.bold : FontWeight.normal)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['berat'] == 0 ? "Menunggu ditimbang..." : "Berat: ${r['berat']} Kg", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 12)),
                                    Text("Total: Rp ${r['total_harga']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showOrderDialog(), // Mode Create
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ORDER BARU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}