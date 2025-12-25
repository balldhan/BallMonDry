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
    required String hargaExp
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Layanan" : "Tambah Layanan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: conNama,
              decoration: const InputDecoration(labelText: "Nama Layanan (Cth: Cuci Karpet)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: conReg,
              decoration: const InputDecoration(labelText: "Harga Reguler /kg (Rp)", prefixText: "Rp "),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: conExp,
              decoration: const InputDecoration(labelText: "Harga Express /kg (Rp)", prefixText: "Rp "),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (conNama.text.isEmpty || conReg.text.isEmpty || conExp.text.isEmpty) {
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
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchLayanan,
              child: layananList.isEmpty 
                ? const Center(child: Text("Belum ada layanan tersedia."))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Biar gak ketutup FAB
                    itemCount: layananList.length,
                    itemBuilder: (context, index) {
                      var item = layananList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.local_laundry_service, color: Colors.deepPurple.shade800),
                          ),
                          title: Text(
                            item['nama_layanan'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Reguler: Rp ${item['harga_reguler']}/kg"),
                              Text("Express: Rp ${item['harga_express']}/kg", style: const TextStyle(color: Colors.orange)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                onPressed: () => showFormDialog(item: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => showDeleteConfirm(item['id'].toString(), item['nama_layanan']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFormDialog(),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah Layanan"),
      ),
    );
  }
}