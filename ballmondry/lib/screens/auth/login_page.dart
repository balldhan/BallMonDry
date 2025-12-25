// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../admin/admin_page.dart';
import '../client/client_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userController = TextEditingController();
  TextEditingController passController = TextEditingController();
  
  // 1. Variabel untuk status sembunyi/lihat password
  bool _isObscure = true; 

  Future<void> login() async {
    // ... (Kode logika login TETAP SAMA, tidak ada yang berubah disini) ...
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({ "username": userController.text, "password": passController.text }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['data']['role'] == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ClientPage(userId: data['data']['id'])));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Gagal!"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.local_laundry_service, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const Text("BallMonDry", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    TextField(controller: userController, decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 15),
                    
                    // 2. Update TextField Password dengan Logic Show/Hide
                    TextField(
                      controller: passController, 
                      obscureText: _isObscure, // Menggunakan variabel state
                      decoration: InputDecoration(
                        labelText: "Password", 
                        prefixIcon: const Icon(Icons.lock),
                        // Tombol Mata (Suffix Icon)
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure; // Balikkan status (True jadi False, dst)
                            });
                          },
                        )
                      ), 
                    ),

                    const SizedBox(height: 25),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: login, child: const Text("MASUK"))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterPage())), child: const Text("Belum punya akun? Daftar disini", style: TextStyle(color: Colors.white)))
            ],
          ),
        ),
      ),
    );
  }
}