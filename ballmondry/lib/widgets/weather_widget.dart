import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  // GANTI KODE WILAYAH INI JIKA PERLU
  final String apiUrl = "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=32.73.14.1002";
  
  Map<String, dynamic>? currentWeather;
  List<dynamic> forecastList = [];
  String locationName = "Memuat...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        String desa = json['lokasi']['desa'];
        String kota = json['lokasi']['kotkab'];

        // 1. Ambil & Ratakan Data
        List rawData = json['data'][0]['cuaca'];
        List flattened = [];
        for (var list in rawData) {
          for (var item in list) {
            flattened.add(item);
          }
        }

        // 2. Urutkan Waktu
        flattened.sort((a, b) => DateTime.parse(a['local_datetime']).compareTo(DateTime.parse(b['local_datetime'])));

        DateTime now = DateTime.now();
        Map<String, dynamic>? current;
        List<dynamic> futureForecasts = [];

        // 3. Filter Data
        for (var item in flattened) {
          DateTime itemTime = DateTime.parse(item['local_datetime']);
          
          // Data valid jika belum lewat dari 3 jam yang lalu
          if (itemTime.isAfter(now.subtract(const Duration(hours: 3)))) {
            if (current == null) {
              current = item; 
            } else {
              futureForecasts.add(item);
            }
          }
        }

        if (mounted) {
          setState(() {
            locationName = "$desa, $kota";
            currentWeather = current;
            forecastList = futureForecasts.take(15).toList(); 
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  IconData getWeatherIcon(String desc) {
    desc = desc.toLowerCase();
    if (desc.contains("cerah")) return Icons.wb_sunny_rounded;
    if (desc.contains("hujan")) return Icons.thunderstorm;
    if (desc.contains("petir")) return Icons.flash_on;
    return Icons.cloud; 
  }

  // Helper untuk nama hari Indonesia
  String getDayName(DateTime date) {
    List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[date.weekday - 1];
  }

  Widget _buildDetailInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (currentWeather == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], 
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // --- BAGIAN ATAS: CUACA SEKARANG ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 5),
                    Expanded( 
                      child: Text(locationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${currentWeather!['t']}°C", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        Text(currentWeather!['weather_desc'], style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                    Icon(getWeatherIcon(currentWeather!['weather_desc']), color: Colors.white, size: 60),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailInfo(Icons.water_drop, "${currentWeather!['hu']}%", "Lembap"),
                    _buildDetailInfo(Icons.air, "${currentWeather!['ws']} km/h", "Angin"),
                    _buildDetailInfo(Icons.visibility, "${currentWeather!['vs_text']}", "Visibilitas"),
                  ],
                ),
              ],
            ),
          ),

          // --- BAGIAN BAWAH: LIST PREDIKSI (DENGAN HEADER HARI) ---
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Prediksi Kedepan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                
                // Gunakan ListView.builder agar bisa custom logic header
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: forecastList.length,
                  itemBuilder: (context, index) {
                    var item = forecastList[index];
                    DateTime time = DateTime.parse(item['local_datetime']);
                    
                    // --- LOGIC HEADER HARI ---
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true; // Item pertama pasti butuh header (Hari ini)
                    } else {
                      // Cek apakah tanggal item ini BEDA dengan tanggal item sebelumnya
                      DateTime prevTime = DateTime.parse(forecastList[index - 1]['local_datetime']);
                      if (time.day != prevTime.day) {
                        showHeader = true;
                      }
                    }
                    // -------------------------

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAMPILKAN HEADER JIKA HARI BERUBAH
                        if (showHeader) 
                          Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 8),
                            child: Text(
                              "${getDayName(time)}, ${DateFormat('d MMM').format(time)}", // Cth: Senin, 21 Okt
                              style: TextStyle(color: Colors.orangeAccent.shade100, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),

                        // ITEM CUACA (PER 3 JAM)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(width: 50, child: Text(DateFormat('HH:mm').format(time), style: const TextStyle(color: Colors.white, fontSize: 13))),
                              Icon(getWeatherIcon(item['weather_desc']), color: Colors.white70, size: 20),
                              const SizedBox(width: 10),
                              Expanded( 
                                child: Text(item['weather_desc'], style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                              ),
                              Text("${item['t']}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),
                              Text("${item['hu']}%", style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11)),
                            ],
                          ),
                        ),
                        // Garis pemisah tipis antar jam (tapi jangan di item terakhir)
                        if (index != forecastList.length - 1) 
                          const Divider(color: Colors.white12, height: 1),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}