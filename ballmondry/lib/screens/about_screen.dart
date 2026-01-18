import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text("Tentang Aplikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LOGO APLIKASI
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.local_laundry_service, size: 70, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "BallMonDry",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text("Versi 1.0.0", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 30),

            // 1. DESKRIPSI APLIKASI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 10),
                      Text("Deskripsi Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  Divider(height: 30, thickness: 1),
                  Text(
                    "BallMonDry adalah aplikasi manajemen laundry pintar yang memudahkan pelanggan dalam memesan layanan laundry (antar-jemput), memantau status cucian secara real-time, serta melihat riwayat transaksi. Aplikasi ini juga membantu pemilik laundry dalam mengelola pesanan dan laporan dengan lebih efisien.",
                    style: TextStyle(fontSize: 15, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. TIM PENGEMBANG
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.groups, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 10),
                      Text("Tim Pengembang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildDeveloperRow("Fadli Ahmad Fahrezi", "152023047"),
                  const SizedBox(height: 15),
                  _buildDeveloperRow("Iqbal Ramadhan", "152023177"),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // 3. API INFO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.api, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 10),
                      Text("Sumber Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  Divider(height: 30, thickness: 1),
                  Text(
                    "Fitur Cuaca dalam aplikasi ini menggunakan data publik dari BMKG.",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  SelectableText(
                    "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=32.73.14.1002",
                    style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. DEMO APLIKASI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.video_library, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 10),
                      Text("Demo Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  Divider(height: 30, thickness: 1),
                  Text(
                    "Tonton video demo penggunaan aplikasi BallMonDry di YouTube:",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  SelectableText(
                    "https://youtu.be/o2KAltdgH-g", // Ganti dengan link youtube asli
                    style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperRow(String name, String npm) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("NPM: $npm", style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}