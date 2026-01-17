// lib/screens/auth/register_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../client/osm_picker_page.dart'; // Import halaman peta

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController userCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();
  TextEditingController confirmPassCtrl = TextEditingController(); 
  TextEditingController alamatCtrl = TextEditingController();
  TextEditingController telpCtrl = TextEditingController();

  // State untuk Koordinat
  double? lat;
  double? lng;

  // State untuk Show/Hide Password
  bool _isPassObscure = true;
  bool _isConfirmObscure = true;

  // Fungsi untuk Membuka Peta OSM
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OSMPickerPage()),
    );

    if (result != null) {
      setState(() {
        alamatCtrl.text = result['address'];
        lat = result['lat'];
        lng = result['lng'];
      });
    }
  }

  Future<void> daftar() async {
    // VALIDASI: Cek Password
    if (passCtrl.text != confirmPassCtrl.text) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password dan Konfirmasi tidak sama!"), backgroundColor: Colors.red)
       );
       return;
    }

    // VALIDASI: Cek Lokasi Peta (Opsional tapi disarankan)
    if (lat == null || lng == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan tandai lokasi alamat pada peta!"), backgroundColor: Colors.orange)
       );
       return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": userCtrl.text,
          "password": passCtrl.text,
          "alamat": alamatCtrl.text,
          "no_telepon": telpCtrl.text,
          "latitude": lat,  // Kirim Latitude ke Backend
          "longitude": lng, // Kirim Longitude ke Backend
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sukses Daftar! Silakan Login."), backgroundColor: Colors.green)
          );
        }
      } else {
        if (mounted) {
          var msg = "Gagal Daftar";
          try { msg = jsonDecode(response.body)['message']; } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.person_add, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const Text("DAFTAR AKUN BARU", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 15),
              
                    TextField(
                      controller: passCtrl, 
                      obscureText: _isPassObscure,
                      decoration: InputDecoration(
                        labelText: "Password", 
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isPassObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isPassObscure = !_isPassObscure),
                        )
                      ), 
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: confirmPassCtrl, 
                      obscureText: _isConfirmObscure,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password", 
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                        )
                      ), 
                    ),
                    const SizedBox(height: 15),

                    TextField(controller: telpCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "No Telepon / WA", prefixIcon: Icon(Icons.phone_android))),
                    const SizedBox(height: 15),
                    
                    // Alamat Lengkap dengan Tombol Peta
                    TextField(
                      controller: alamatCtrl, 
                      maxLines: 2, 
                      decoration: InputDecoration(
                        labelText: "Alamat Lengkap", 
                        prefixIcon: const Icon(Icons.home_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map_outlined, color: Colors.deepPurple),
                          onPressed: _pickLocation, // Fungsi Buka Peta
                          tooltip: "Pilih dari Peta",
                        )
                      )
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: daftar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("DAFTAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Sudah punya akun? Login disini", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}