// lib/screens/client/tabs/order_tab.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config.dart';

class OrderTab extends StatefulWidget {
  final int userId;
  const OrderTab({super.key, required this.userId});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  // Variabel Data
  List riwayat = [];
  List layananList = [];

  @override
  void initState() {
    super.initState();
    fetchLayanan();
    fetchRiwayat();
  }

  // Ambil Daftar Layanan (Reguler/Express/Satuan)
  Future<void> fetchLayanan() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/layanan'));
      if (response.statusCode == 200) {
        if (mounted)
          setState(() {
            layananList = jsonDecode(response.body);
          });
      }
    } catch (e) {
      print("Error fetch layanan: $e");
    }
  }

  // Ambil Riwayat Pesanan User Ini
  Future<void> fetchRiwayat() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/history/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          List newRiwayat = jsonDecode(response.body);
          
          // Cek jika ada order baru yang dikonfirmasi dan belum pilih metode pembayaran
          for (var order in newRiwayat) {
            if ((order['status'] == 'dikonfirmasi' || 
                 order['status'] == 'konfirmasi' ||
                 order['status'] == 'dijemput' ||
                 order['status'] == 'proses' || 
                 order['status'] == 'selesai') &&
                order['metode_pembayaran'] == null &&
                order['total_harga'] != null &&
                order['total_harga'] > 0) {
              // Tampilkan notifikasi untuk pilih metode pembayaran
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showPaymentReminderDialog(order);
                }
              });
              break; // Hanya tampilkan untuk satu order
            }
          }
          
          setState(() {
            riwayat = newRiwayat;
          });
        }
      }
    } catch (e) {
      print("Error fetch riwayat: $e");
    }
  }

  // Dialog pengingat pilih metode pembayaran
  void _showPaymentReminderDialog(Map order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order #${order['id']} Dikonfirmasi!",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Layanan: ${order['nama_layanan']}"),
                  Text("Berat: ${order['berat']} Kg"),
                  Text(
                    "Total: Rp ${order['total_harga']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Silakan pilih metode pembayaran untuk melanjutkan:",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nanti Saja"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              showPilihMetodePembayaran(order['id']);
            },
            child: const Text("Pilih Sekarang"),
          ),
        ],
      ),
    );
  }

  // Buat Order Baru
  // UPDATE: Menambahkan parameter 'estimasiStr' untuk dikirim ke DB
  Future<void> createOrder(
    int idLayanan,
    String tipe,
    bool pickup,
    String estimasiStr,
  ) async {
    try {
      // 1. Print Log untuk cek data terkirim
      print("SENDING ORDER -> Layanan: $idLayanan, Estimasi: $estimasiStr");

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/order'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "layanan_id": idLayanan,
          "tipe_layanan": tipe,
          "is_pickup": pickup,
          "estimasi": estimasiStr,
        }),
      );

      print("RESPONSE SERVER: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Order Berhasil!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // TAMPILKAN ERROR DARI SERVER DI LAYAR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal: ${response.body}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // TAMPILKAN ERROR KONEKSI DI LAYAR
      print("ERROR KONEKSI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Aplikasi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update Order (Hanya bisa jika status masih 'menunggu konfirmasi')
  Future<void> updateOrder(
    int orderId,
    int idLayanan,
    String tipe,
    bool pickup,
    String estimasiStr,
  ) async {
    try {
      // Logic update estimasi di skip dulu agar simpel, atau bisa ditambahkan jika perlu
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/order/edit-client'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": orderId,
          "layanan_id": idLayanan,
          "tipe_layanan": tipe,
          "is_pickup": pickup,
          "estimasi": estimasiStr
        }),
      );
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Order Berhasil Diupdate!"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        var msg = jsonDecode(response.body)['message'];
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
      }
    } catch (e) {
      print(e);
    }
  }

  // Hapus Order
  Future<void> deleteOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/order/$id'),
      );
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pesanan dibatalkan"),
              backgroundColor: Colors.orange,
            ),
          );
      } else {
        var msg = jsonDecode(response.body)['message'];
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
      }
    } catch (e) {
      print(e);
    }
  }

  // Pilih Metode Pembayaran
  Future<void> pilihMetodePembayaran(int orderId, String metode) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/order/payment/metode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'metode_pembayaran': metode,
        }),
      );
      
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Metode pembayaran: $metode"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Error pilih metode: $e");
    }
  }

  // Upload Bukti Transfer dengan base64 image
  Future<void> uploadBuktiTransfer(int orderId, String base64Image, String fileName) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/order/payment/upload-bukti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'bukti_transfer': base64Image, // Simpan base64 image lengkap
        }),
      );
      
      if (response.statusCode == 200) {
        fetchRiwayat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bukti transfer berhasil diupload"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Error upload bukti: $e");
    }
  }

  void showActionOptions(Map order) {
    bool isEditable = order['status'] == 'menunggu konfirmasi';
    bool isConfirmed = order['status'] == 'konfirmasi' ||
                      order['status'] == 'dijemput' ||
                      order['status'] == 'proses' || 
                      order['status'] == 'selesai';
    bool hasPrice = order['total_harga'] != null && order['total_harga'] > 0;
    String? metodePembayaran = order['metode_pembayaran'];
    String? statusPembayaran = order['status_pembayaran'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditable ? "Kelola Pesanan" : "Detail Pesanan",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),

              // Info Status Pembayaran
              if (hasPrice && statusPembayaran != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusPembayaran == 'Lunas' 
                        ? Colors.green[50] 
                        : statusPembayaran == 'Menunggu Verifikasi'
                            ? Colors.orange[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusPembayaran == 'Lunas'
                          ? Colors.green
                          : statusPembayaran == 'Menunggu Verifikasi'
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusPembayaran == 'Lunas' 
                            ? Icons.check_circle 
                            : Icons.info_outline,
                        color: statusPembayaran == 'Lunas'
                            ? Colors.green
                            : statusPembayaran == 'Menunggu Verifikasi'
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status Pembayaran: $statusPembayaran",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusPembayaran == 'Lunas'
                                    ? Colors.green[800]
                                    : statusPembayaran == 'Menunggu Verifikasi'
                                        ? Colors.orange[800]
                                        : Colors.red[800],
                              ),
                            ),
                            if (metodePembayaran != null)
                              Text(
                                "Metode: $metodePembayaran",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            // Tampilkan info kembalian untuk COD
                            if (order['kembalian'] != null && 
                                order['kembalian'] > 0 &&
                                metodePembayaran == 'COD')
                              Text(
                                "Kembalian: Rp ${order['kembalian']}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isEditable && !hasPrice)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pesanan sedang ${order['status']}, sudah tidak bisa diedit atau dibatalkan.",
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (isEditable) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  title: const Text("Edit Pesanan"),
                  onTap: () {
                    Navigator.pop(context);
                    showOrderDialog(orderToEdit: order);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white, size: 20),
                  ),
                  title: const Text("Batalkan Pesanan"),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Batalkan Order?"),
                        content: const Text(
                          "Apakah Anda yakin ingin menghapus pesanan ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("TIDAK"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              deleteOrder(order['id']);
                            },
                            child: const Text(
                              "YA, HAPUS",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else if (hasPrice && isConfirmed) ...[
                // Opsi Pilih Metode Pembayaran (jika belum pilih)
                if (metodePembayaran == null)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.payment, color: Colors.white, size: 20),
                    ),
                    title: const Text("Pilih Metode Pembayaran"),
                    onTap: () {
                      Navigator.pop(context);
                      showPilihMetodePembayaran(order['id']);
                    },
                  ),
                // Opsi Upload Bukti Transfer (jika pilih transfer & belum upload)
                if (metodePembayaran == 'Transfer Bank' && 
                    statusPembayaran == 'Belum Bayar')
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.upload_file, color: Colors.white, size: 20),
                    ),
                    title: const Text("Upload Bukti Transfer"),
                    onTap: () {
                      Navigator.pop(context);
                      showUploadBuktiDialog(order['id']);
                    },
                  ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  title: const Text("Tutup"),
                  onTap: () => Navigator.pop(context),
                ),
              ] else ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  title: const Text("Tutup"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Dialog Pilih Metode Pembayaran
  void showPilihMetodePembayaran(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opsi COD
            InkWell(
              onTap: () {
                Navigator.pop(context);
                pilihMetodePembayaran(orderId, 'COD');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.money, color: Colors.blue[700], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "COD (Cash on Delivery)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Bayar tunai saat mengambil cucian",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.blue[700], size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Opsi Transfer Bank
            InkWell(
              onTap: () {
                Navigator.pop(context);
                pilihMetodePembayaran(orderId, 'Transfer Bank');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.orange[700], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Transfer Bank",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Transfer ke rekening & upload bukti",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.orange[700], size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
        ],
      ),
    );
  }

  // Dialog Upload Bukti Transfer
  void showUploadBuktiDialog(int orderId) {
    File? selectedImage;
    final ImagePicker picker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.upload_file, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("Upload Bukti Transfer")),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transfer ke:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Bank BCA"),
                      const Text("1234567890"),
                      const Text("a.n. BallMonDry Laundry"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Preview Image
                if (selectedImage != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada foto dipilih",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Tombol Pilih Foto
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            PermissionStatus? photoStatus;
                            
                            if (await Permission.photos.isPermanentlyDenied) {
                              if (context.mounted) {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Izin Diperlukan'),
                                    content: const Text(
                                      'Aplikasi memerlukan izin akses foto. Silakan aktifkan di pengaturan.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Buka Pengaturan'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result == true) {
                                  await openAppSettings();
                                }
                              }
                              return;
                            }
                              
                            photoStatus = await Permission.photos.request();
                            
                            if (photoStatus.isGranted || photoStatus.isLimited) {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            } else if (photoStatus.isDenied) {
                              // Coba langsung buka picker (mungkin tidak perlu permission)
                              try {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1024,
                                  maxHeight: 1024,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setState(() {
                                    selectedImage = File(image.path);
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Izin akses galeri diperlukan. Silakan aktifkan di pengaturan.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galeri"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // Cek jika permission permanently denied
                            if (await Permission.camera.isPermanentlyDenied) {
                              if (context.mounted) {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Izin Diperlukan'),
                                    content: const Text(
                                      'Aplikasi memerlukan izin akses kamera. Silakan aktifkan di pengaturan.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Buka Pengaturan'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result == true) {
                                  await openAppSettings();
                                }
                              }
                              return;
                            }
                            
                            // Request camera permission
                            var status = await Permission.camera.request();
                            
                            if (status.isGranted) {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            } else if (status.isDenied) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Izin akses kamera diperlukan untuk mengambil foto.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Kamera"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedImage == null
                  ? null
                  : () async {
                      // Convert image to base64 dengan format data URI
                      final bytes = await selectedImage!.readAsBytes();
                      final base64Image = base64Encode(bytes);
                      // Format: data:image/jpeg;base64,<base64string>
                      final imageDataUri = 'data:image/jpeg;base64,$base64Image';
                      
                      Navigator.pop(context);
                      uploadBuktiTransfer(orderId, imageDataUri, '');
                    },
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Form Order (Create / Edit)
  void showOrderDialog({Map? orderToEdit}) {
    bool isEditMode = orderToEdit != null;

    // Setup Data Awal
    int? selectedLayananId = isEditMode ? orderToEdit['layanan_id'] : null;
    String tipe = isEditMode ? orderToEdit['tipe_layanan'] : 'reguler';

    // Parsing Pickup
    bool isPickup = false;
    if (isEditMode) {
      var p = orderToEdit['is_pickup'];
      isPickup = (p == 1 || p == true);
    }

    // Cari Data Layanan Awal (untuk edit)
    Map? selectedLayananData;
    if (isEditMode && layananList.isNotEmpty) {
      try {
        selectedLayananData = layananList.firstWhere(
          (e) => e['id'] == selectedLayananId,
        );
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // --- LOGIKA HITUNG HARGA & ESTIMASI DURASI ---
            int hargaPerKg = 0;
            String estimasiText = "-";

            if (selectedLayananData != null) {
              // 1. Hitung Harga Per Kg
              hargaPerKg = (tipe == 'reguler')
                  ? selectedLayananData!['harga_reguler']
                  : selectedLayananData!['harga_express'];

              // 2. Ambil Durasi Jam (TIDAK PAKAI TANGGAL LAGI)
              int durasiJam = (tipe == 'reguler')
                  ? (selectedLayananData!['jam_reguler'] ??
                        48) // Default 48 jika null
                  : (selectedLayananData!['jam_express'] ??
                        6); // Default 6 jika null

              estimasiText = "$durasiJam Jam";
            }
            int biayaJemput = isPickup ? 7000 : 0;
            // ---------------------------------------------

            return AlertDialog(
              title: Text(isEditMode ? "Edit Pesanan" : "Buat Pesanan Baru"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pilih Paket Laundry:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                          selectedLayananData = layananList.firstWhere(
                            (element) => element['id'] == val,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      "Tipe Layanan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text(
                              "Reguler",
                              style: TextStyle(fontSize: 14),
                            ),
                            value: "reguler",
                            groupValue: tipe,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setStateDialog(() => tipe = val.toString()),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text(
                              "Express",
                              style: TextStyle(fontSize: 14),
                            ),
                            value: "express",
                            groupValue: tipe,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setStateDialog(() => tipe = val.toString()),
                          ),
                        ),
                      ],
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Harga Paket:"),
                              Text(
                                "Rp $hargaPerKg /kg",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Biaya Jemput:"),
                              Text(
                                isPickup ? "+ Rp 7.000" : "Rp 0",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPickup ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 5),
                          // Tampilkan Estimasi Text (ex: "48 Jam")
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Estimasi Pengerjaan:"),
                              Text(
                                estimasiText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text("Jemput Pakaian?"),
                      subtitle: Text(
                        isPickup
                            ? "Kurir akan datang"
                            : "Antar sendiri ke outlet",
                      ),
                      value: isPickup,
                      activeColor: Colors.deepPurple,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateDialog(() => isPickup = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "BATAL",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedLayananId == null
                      ? null
                      : () {
                          if (isEditMode) {
                            updateOrder(
                              orderToEdit['id'],
                              selectedLayananId!,
                              tipe,
                              isPickup,
                              estimasiText
                            );
                          } else {
                            // Kirim estimasiText ("48 Jam") ke database
                            createOrder(
                              selectedLayananId!,
                              tipe,
                              isPickup,
                              estimasiText,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isEditMode ? "SIMPAN PERUBAHAN" : "ORDER SEKARANG",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: const Text(
              "Riwayat Pesanan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchRiwayat,
              child: riwayat.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Belum ada pesanan",
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      var r = riwayat[index];
                      bool isPickup =
                          (r['is_pickup'] == 1 || r['is_pickup'] == true);

                      // Warna Status
                      Color statusColor;
                      String statusText = r['status'].toString();
                      switch (statusText) {
                        case 'menunggu konfirmasi':
                          statusColor = Colors.grey;
                          break;
                        case 'dikonfirmasi':
                          statusColor = Colors.blue;
                          break;
                        case 'dijemput':
                          statusColor = Colors.orange;
                          break;
                        case 'diproses':
                          statusColor = Colors.purple;
                          break;
                        case 'selesai':
                          statusColor = Colors.green;
                          break;
                        default:
                          statusColor = Colors.black;
                      }

                      return Card(
                        clipBehavior: Clip.hardEdge,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () => showActionOptions(r),
                          splashColor: Colors.deepPurple.withAlpha(30),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['nama_layanan'] ?? 'Paket',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Badge Status Pembayaran
                                        if (r['status_pembayaran'] != null && 
                                            r['total_harga'] != null && 
                                            r['total_harga'] > 0)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: r['status_pembayaran'] == 'Lunas'
                                                  ? Colors.green
                                                  : r['status_pembayaran'] == 'Menunggu Verifikasi'
                                                      ? Colors.orange
                                                      : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  r['status_pembayaran'] == 'Lunas'
                                                      ? Icons.check_circle
                                                      : Icons.payment,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  r['status_pembayaran'] == 'Lunas'
                                                      ? 'LUNAS'
                                                      : r['status_pembayaran'] == 'Menunggu Verifikasi'
                                                          ? 'VERIF'
                                                          : 'BAYAR',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Badge Status Order
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            statusText.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // Baris Estimasi (Ditampilkan di Kartu)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Estimasi: ${r['estimasi'] ?? '-'}",
                                      style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Tipe: ${r['tipe_layanan']?.toUpperCase() ?? '-'}",
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Icon(
                                      isPickup
                                          ? Icons.delivery_dining
                                          : Icons.store,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isPickup ? "Dijemput" : "Antar Sendiri",
                                      style: TextStyle(
                                        color: isPickup
                                            ? Colors.deepPurple
                                            : Colors.grey[800],
                                        fontSize: 13,
                                        fontWeight: isPickup
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['berat'] == 0
                                          ? "Menunggu ditimbang..."
                                          : "Berat: ${r['berat']} Kg",
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "Total: Rp ${r['total_harga']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showOrderDialog(),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "ORDER BARU",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  
}