import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart'; // Pastikan path ini sesuai dengan file config Anda

class Layanan extends StatefulWidget {
  const Layanan({super.key});

  @override
  State<Layanan> createState() => _LayananState();
}

class _LayananState extends State<Layanan> {
  List layananList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLayanan();
  }

  // --- 1. READ (AMBIL DATA) ---
  Future<void> fetchLayanan() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/layanan'));
      if (response.statusCode == 200) {
        setState(() {
          layananList = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching layanan: $e");
      setState(() => isLoading = false);
    }
  }

  // --- 2. CREATE & UPDATE (SIMPAN DATA) ---
  Future<void> saveLayanan({
    String? id, // Jika ID null berarti CREATE, jika ada berarti UPDATE
    required String nama,
    required String hargaReg,
    required String hargaExp,
    required String jamReguler,
    required String jamExpress,
  }) async {
    setState(() => isLoading = true);

    try {
      final url = id == null 
          ? Uri.parse('${Config.baseUrl}/layanan') 
          : Uri.parse('${Config.baseUrl}/layanan/$id');
      
      final method = id == null ? 'POST' : 'PUT';

      // Persiapkan request
      final request = http.Request(method, url);
      request.headers.addAll({"Content-Type": "application/json"});
      request.body = jsonEncode({
        "nama_layanan": nama,
        "harga_reguler": int.parse(hargaReg),
        "harga_express": int.parse(hargaExp),
        "jam_reguler": int.parse(jamReguler),
        "jam_express": int.parse(jamExpress),
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(id == null ? "Layanan Ditambahkan" : "Layanan Diperbarui"), backgroundColor: Colors.green),
          );
        }
        fetchLayanan(); // Refresh list
      } else {
        throw Exception("Gagal menyimpan data");
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- 3. DELETE (HAPUS DATA) ---
  Future<void> deleteLayanan(String id) async {
    try {
      final response = await http.delete(Uri.parse('${Config.baseUrl}/layanan/$id'));
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Layanan berhasil dihapus"), backgroundColor: Colors.red),
        );
        fetchLayanan(); // Refresh list
      }
    } catch (e) {
      debugPrint("Error delete: $e");
    }
  }

  // --- UI DIALOG FORM (Tambah/Edit) ---
  void showFormDialog({Map? item}) {
    final isEdit = item != null;
    final conNama = TextEditingController(text: isEdit ? item['nama_layanan'] : '');
    final conReg = TextEditingController(text: isEdit ? item['harga_reguler'].toString() : '');
    final conExp = TextEditingController(text: isEdit ? item['harga_express'].toString() : '');
    final conJamReguler = TextEditingController(text: isEdit ? item['jam_reguler'].toString() : '');
    final conJamExpress = TextEditingController(text: isEdit ? item['jam_express'].toString() : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEdit ? Icons.edit : Icons.add,
                color: Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? "Edit Layanan" : "Tambah Layanan Baru",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Layanan
              TextField(
                controller: conNama,
                decoration: InputDecoration(
                  labelText: "Nama Layanan",
                  hintText: "Contoh: Cuci Karpet",
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              
              // Section Header - Reguler
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      "Layanan Reguler",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Harga Reguler
              TextField(
                controller: conReg,
                decoration: InputDecoration(
                  labelText: "Harga /kg",
                  hintText: "Contoh: 5000",
                  prefixIcon: const Icon(Icons.payments),
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              // Durasi Reguler
              TextField(
                controller: conJamReguler,
                decoration: InputDecoration(
                  labelText: "Durasi Pengerjaan",
                  hintText: "Contoh: 24",
                  prefixIcon: const Icon(Icons.access_time),
                  suffixText: "jam",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              
              // Section Header - Express
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      "Layanan Express",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Harga Express
              TextField(
                controller: conExp,
                decoration: InputDecoration(
                  labelText: "Harga /kg",
                  hintText: "Contoh: 8000",
                  prefixIcon: const Icon(Icons.payments),
                  prefixText: "Rp ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              // Durasi Express
              TextField(
                controller: conJamExpress,
                decoration: InputDecoration(
                  labelText: "Durasi Pengerjaan",
                  hintText: "Contoh: 12",
                  prefixIcon: const Icon(Icons.access_time),
                  suffixText: "jam",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (conNama.text.isEmpty || conReg.text.isEmpty || conExp.text.isEmpty || conJamReguler.text.isEmpty || conJamExpress.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Semua kolom harus diisi!"), backgroundColor: Colors.orange),
                 );
                 return;
              }
              
              Navigator.pop(context);
              saveLayanan(
                id: isEdit ? item['id'].toString() : null,
                nama: conNama.text,
                hargaReg: conReg.text,
                hargaExp: conExp.text,
                jamReguler: conJamReguler.text,
                jamExpress: conJamExpress.text,
              );
            },
            child: Text(isEdit ? "Update" : "Simpan"),
          ),
        ],
      ),
    );
  }

  // --- UI DIALOG KONFIRMASI HAPUS ---
  void showDeleteConfirm(String id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Layanan?"),
        content: Text("Anda yakin ingin menghapus layanan '$nama'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteLayanan(id);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchLayanan,
              child: layananList.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada layanan tersedia",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap tombol + untuk menambah layanan baru",
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: layananList.length,
                    itemBuilder: (context, index) {
                      var item = layananList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.deepPurple.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header dengan nama layanan dan action buttons
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_laundry_service,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['nama_layanan'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, color: Colors.deepPurple[700]),
                                    onPressed: () => showFormDialog(item: item),
                                    tooltip: "Edit",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => showDeleteConfirm(item['id'].toString(), item['nama_layanan']),
                                    tooltip: "Hapus",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Pricing info dengan cards
                              Row(
                                children: [
                                  // Regular Card
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.schedule, size: 16, color: Colors.blue[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Reguler",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.payments, size: 14, color: Colors.blue[600]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "Rp ${item['harga_reguler']}/kg",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 14, color: Colors.blue[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${item['jam_reguler']} jam",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Express Card
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.bolt, size: 16, color: Colors.orange[700]),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Express",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.payments, size: 14, color: Colors.orange[600]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "Rp ${item['harga_express']}/kg",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.orange[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 14, color: Colors.orange[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${item['jam_express']} jam",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFormDialog(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
}