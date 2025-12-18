// lib/screens/auth/register_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController userCtrl = TextEditingController();
  TextEditingController passCtrl = TextEditingController();
  // 1. Tambah Controller untuk Konfirmasi
  TextEditingController confirmPassCtrl = TextEditingController(); 
  TextEditingController alamatCtrl = TextEditingController();
  TextEditingController telpCtrl = TextEditingController();

  // 2. State untuk Show/Hide Password
  bool _isPassObscure = true;
  bool _isConfirmObscure = true;

  Future<void> daftar() async {
    // 3. VALIDASI: Cek apakah Password dan Konfirmasi sama?
    if (passCtrl.text != confirmPassCtrl.text) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password dan Konfirmasi tidak sama!"), backgroundColor: Colors.red)
       );
       return; // Berhenti disini, jangan kirim ke server
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": userCtrl.text,
          "password": passCtrl.text, // Tetap kirim password asli
          "alamat": alamatCtrl.text,
          "no_telepon": telpCtrl.text,
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
      appBar: AppBar(title: const Text("Daftar Akun")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 15),
              
              // 4. Input Password Utama
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

              // 5. Input Konfirmasi Password
              TextField(
                controller: confirmPassCtrl, 
                obscureText: _isConfirmObscure,
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password", 
                  prefixIcon: const Icon(Icons.lock_reset), // Ikon beda dikit biar variatif
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmObscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                  )
                ), 
              ),
              const SizedBox(height: 15),

              TextField(controller: telpCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "No Telepon / WA", prefixIcon: Icon(Icons.phone_android))),
              const SizedBox(height: 15),
              TextField(controller: alamatCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Alamat Lengkap", prefixIcon: Icon(Icons.home_outlined))),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: daftar, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("DAFTAR SEKARANG")))
            ],
          ),
        ),
      ),
    );
  }
}