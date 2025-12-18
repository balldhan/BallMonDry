// lib/screens/about_page.dart
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aplikasi")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text("Smart Laundry v1.0", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Aplikasi Tugas Besar Mobile Programming\nCreated with Flutter", textAlign: TextAlign.center),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: const [
                      Text("Credits & Data Source:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Divider(),
                      SizedBox(height: 10),
                      Text("🌍 Data Cuaca: BMKG Indonesia"),
                      SizedBox(height: 5),
                      Text("📡 API: api.bmkg.go.id"),
                      SizedBox(height: 5),
                      Text("📍 Wilayah: Kota Bandung"),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}