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
              "Smart Laundry App",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text("Versi 1.0.0", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),

            // BAGIAN INFO API - Dengan design modern
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
                      Text("Sumber Data Publik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  Divider(height: 30, thickness: 1),
                  Text(
                    "Fitur Cuaca dalam aplikasi ini menggunakan data publik dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika).",
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Endpoint API yang digunakan:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  SelectableText(
                    "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=32.73.14.1002",
                    style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // BAGIAN DEVELOPER
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
                      Icon(Icons.people, color: Colors.deepPurple, size: 28),
                      SizedBox(width: 10),
                      Text("Dikembangkan oleh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildDeveloperRow("Fadli Ahmad Fahrezi"),
                  const SizedBox(height: 10),
                  _buildDeveloperRow("Iqbal Ramadhan"),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperRow(String name) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 15),
        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}