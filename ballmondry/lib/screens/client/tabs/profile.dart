import 'package:ballmondry/screens/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import '../../about_screen.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade50],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: fetchUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            children: [
              const SizedBox(height: 30),
              // HEADER PROFILE dengan design modern
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      conUser.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Pelanggan",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // FORM SECTION dengan container putih
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informasi Profil",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Divider(height: 30),

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
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "SIMPAN PERUBAHAN",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // MENU ITEMS
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                      title: const Text("Tentang Aplikasi"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Keluar Akun", style: TextStyle(color: Colors.red)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            ),
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
