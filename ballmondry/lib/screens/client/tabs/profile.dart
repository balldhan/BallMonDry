import 'package:ballmondry/screens/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class ProfileTab extends StatefulWidget {
  final int userId;
  const ProfileTab({super.key, required this.userId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isObscure = true;

  // Controller untuk input
  TextEditingController conUser = TextEditingController();
  TextEditingController conPass = TextEditingController();
  TextEditingController conAlamat = TextEditingController();
  TextEditingController conPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/user/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          conUser.text = data['username'] ?? '';
          conPass.text = data['password'] ?? '';
          conAlamat.text = data['alamat'] ?? '';
          conPhone.text = data['no_hp'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetch profile: $e");
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('${Config.baseUrl}/user/update'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": widget.userId,
          "username": conUser.text,
          "password": conPass.text,
          "alamat": conAlamat.text,
          "no_hp": conPhone.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil Berhasil Diperbarui!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // HEADER PROFILE
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                conUser.text,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 40),

              // INPUT USERNAME
              _buildTextField(
                controller: conUser,
                label: "Username",
                icon: Icons.account_circle,
                validator: (v) =>
                    v!.isEmpty ? "Username tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              // INPUT PASSWORD
              _buildTextField(
                controller: conPass,
                label: "Password",
                icon: Icons.lock,
                isPassword: true,
                validator: (v) =>
                    v!.length < 4 ? "Password minimal 4 karakter" : null,
              ),
              const SizedBox(height: 15),

              // INPUT NO HP
              _buildTextField(
                controller: conPhone,
                label: "No. Handphone",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              // INPUT ALAMAT
              _buildTextField(
                controller: conAlamat,
                label: "Alamat Lengkap",
                icon: Icons.location_on,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "SIMPAN PERUBAHAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // TOMBOL LOGOUT (Opsional)
              TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ), // Panggil langsung class-nya
                    (route) =>
                        false, // Menghapus semua riwayat halaman sebelumnya agar tidak bisa "back"
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Keluar Akun",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER UNTUK TEXTFIELD AGAR TIDAK REPETITIF
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => isObscure = !isObscure),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
