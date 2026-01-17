import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 
import '../../../config.dart'; 

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  
  // State untuk Filter
  String selectedPeriod = 'Hari'; 
  DateTime selectedDate = DateTime.now(); 

  // State untuk Pie Chart Interactivity
  int selectedPieIndex = -1;
  int selectedDonutIndex = -1;
  int selectedDeliveryIndex = -1; // State untuk grafik baru
  
  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initData(); 
  }

  Future<void> _initData() async {
    await initializeDateFormatting('id_ID', null); 
    await fetchStats();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/admin/stats'));
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            stats = jsonDecode(response.body);
            isLoading = false; 
          });
          _animationController?.forward();
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) { 
      print("❌ Exception: $e"); 
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _fadeAnimation == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.white, Colors.purple.shade50],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.white, Colors.purple.shade50],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => isLoading = true);
          _animationController?.reset();
          await fetchStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 25),
                _buildQuickStats(),
                const SizedBox(height: 30),
                _buildRevenueSection(),
                const SizedBox(height: 30),
                _buildOrderChartsSection(), // Bagian Grafik Order & Metode
                const SizedBox(height: 30),
                _buildServiceChartsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purple.shade300]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.dashboard, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard Analytics", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              Text("Pantau performa laundry Anda", style: TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Quick Stats ---
  Widget _buildQuickStats() {
    return Column(
      children: [
        _buildStatCard("Total Pendapatan", "Rp ${_formatCurrency(stats['total_pendapatan'] ?? 0)}", Colors.green, Icons.account_balance_wallet, isLarge: true),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildStatCard("Total Order", "${stats['total_order'] ?? 0}", Colors.deepPurple, Icons.shopping_bag)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard("Order Proses", "${stats['order_proses'] ?? 0}", Colors.orange, Icons.hourglass_empty)),
          ],
        ),
      ],
    );
  }

  // --- Revenue Chart ---
  Widget _buildRevenueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 10.0,
          spacing: 10.0,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text("Pendapatan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ],
            ),
            _buildPeriodFilter(),
          ],
        ),
        const SizedBox(height: 15),

        if (selectedPeriod != 'Bulan')
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.deepPurple),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

        _buildChartCard(
          selectedPeriod == 'Bulan' 
            ? "Tren Tahunan" 
            : "Statistik Bulan ${DateFormat('MMMM', 'id_ID').format(selectedDate)}",
          _buildRevenueLineChart(),
          height: 300,
        ),
      ],
    );
  }

  Widget _buildRevenueLineChart() {
    List<FlSpot> spots = [];
    double maxY = 0;

    if (selectedPeriod == 'Hari') {
      List<dynamic> dailyData = stats['revenue_chart']?['daily'] ?? [];
      var filtered = dailyData.where((item) {
        DateTime date = DateTime.parse(item['date'].toString());
        return date.month == selectedDate.month && date.year == selectedDate.year;
      }).toList();

      spots = filtered.map((item) {
        DateTime date = DateTime.parse(item['date'].toString());
        double total = double.tryParse(item['total'].toString()) ?? 0;
        return FlSpot(date.day.toDouble(), total);
      }).toList();

    } else if (selectedPeriod == 'Minggu') {
      List<dynamic> dailyData = stats['revenue_chart']?['daily'] ?? [];
      Map<int, double> weeklySums = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var item in dailyData) {
        DateTime date = DateTime.parse(item['date'].toString());
        if (date.month == selectedDate.month && date.year == selectedDate.year) {
          double total = double.tryParse(item['total'].toString()) ?? 0;
          int weekNumber = ((date.day - 1) / 7).floor() + 1;
          if (weekNumber > 5) weekNumber = 5;
          weeklySums[weekNumber] = (weeklySums[weekNumber] ?? 0) + total;
        }
      }
      weeklySums.forEach((week, total) {
        spots.add(FlSpot(week.toDouble(), total));
      });

    } else {
      List<dynamic> monthlyData = stats['revenue_chart']?['monthly'] ?? [];
      spots = monthlyData.asMap().entries.map((e) {
        double total = double.tryParse(e.value['total'].toString()) ?? 0;
        return FlSpot(e.key.toDouble(), total);
      }).toList();
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    if (spots.isEmpty) spots = [const FlSpot(0, 0)];
    maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.15), dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, 
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (selectedPeriod == 'Hari') {
                   if (index < 1 || index > 31) return const SizedBox.shrink();
                   if (index == 1 || index % 5 == 0) {
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(index.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                     );
                   }
                   return const SizedBox.shrink();

                } else if (selectedPeriod == 'Minggu') {
                  if (index >= 1 && index <= 5) {
                    return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text("M$index", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                     );
                  }
                  return const SizedBox.shrink();

                } else {
                  List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                  if (index >= 0 && index < months.length) {
                    return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(months[index], style: const TextStyle(fontSize: 10)),
                     );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => Text(
                _formatShortCurrency(value),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: selectedPeriod == 'Hari' ? 1 : (selectedPeriod == 'Minggu' ? 1 : 0),
        maxX: selectedPeriod == 'Hari' ? 31 : (selectedPeriod == 'Minggu' ? 5 : 11),
        minY: 0,
        maxY: maxY * 1.2, 
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String label = "";
                if (selectedPeriod == 'Hari') label = "Tgl ${spot.x.toInt()}";
                else if (selectedPeriod == 'Minggu') label = "Minggu ${spot.x.toInt()}";
                else {
                   List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                   if(spot.x.toInt() < months.length) label = months[spot.x.toInt()];
                }
                return LineTooltipItem(
                  '$label\nRp ${_formatCurrency(spot.y.toInt())}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: selectedPeriod == 'Minggu'), 
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent].map((color) => color.withOpacity(0.2)).toList(),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Analisis Pesanan (Status, Tipe, & Metode) ---
  Widget _buildOrderChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Analisis Pesanan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 10),
        
        // Baris 1: Status & Tipe (Diperkecil agar tidak tumpang tindih)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildChartCard("Status Order", _buildOrderStatusPieChart(), height: 200)), // Tinggi dikurangi sedikit
            const SizedBox(width: 12),
            Expanded(child: _buildChartCard("Tipe Layanan", _buildRegularExpressDonutChart(), height: 200)),
          ],
        ),
        
        const SizedBox(height: 12),

        // Baris 2: Metode Antar / Jemput (Full Width agar jelas)
        _buildChartCard("Metode Antar / Jemput", _buildDeliveryMethodChart(), height: 250),
      ],
    );
  }

  // Grafik 1: Status Order (Diperkecil Radiusnya)
  Widget _buildOrderStatusPieChart() {
    final orderSelesai = (stats['order_selesai'] ?? 0).toDouble();
    final orderProses = (stats['order_proses'] ?? 0).toDouble();
    final totalOrder = orderSelesai + orderProses;
    
    if (totalOrder == 0) return const Center(child: Text("Tidak ada data", style: TextStyle(color: Colors.grey)));

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      selectedPieIndex = -1;
                      return;
                    }
                    selectedPieIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2, 
              centerSpaceRadius: 30, // DIPERKECIL (sebelumnya 40)
              sections: [
                PieChartSectionData(
                  value: orderSelesai, 
                  title: '${((orderSelesai/totalOrder)*100).toInt()}%', 
                  color: Colors.green, 
                  radius: selectedPieIndex == 0 ? 50 : 40, // DIPERKECIL (sebelumnya 60/50)
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                PieChartSectionData(
                  value: orderProses, 
                  title: '${((orderProses/totalOrder)*100).toInt()}%', 
                  color: Colors.orange, 
                  radius: selectedPieIndex == 1 ? 50 : 40, // DIPERKECIL
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Indicator(color: Colors.green, text: "Selesai"),
            Indicator(color: Colors.orange, text: "Proses")
          ],
        ),
      ],
    );
  }

  // Grafik 2: Tipe Layanan (Reguler/Express) - Diperkecil Radiusnya
  Widget _buildRegularExpressDonutChart() {
    final types = (stats['type_breakdown'] as List?) ?? [];
    double regular = 0, express = 0;

    for (var item in types) {
      if (item['tipe_layanan'].toString().toLowerCase() == 'reguler') regular = double.tryParse(item['count'].toString()) ?? 0;
      else if (item['tipe_layanan'].toString().toLowerCase() == 'express') express = double.tryParse(item['count'].toString()) ?? 0;
    }
    final total = regular + express;
    if (total == 0) return const Center(child: Text("Tidak ada data", style: TextStyle(color: Colors.grey)));

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      selectedDonutIndex = -1;
                      return;
                    }
                    selectedDonutIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2, 
              centerSpaceRadius: 30, // DIPERKECIL
              sections: [
                PieChartSectionData(
                  value: regular, 
                  title: '${((regular/total)*100).toInt()}%', 
                  color: Colors.blue, 
                  radius: selectedDonutIndex == 0 ? 50 : 40, // DIPERKECIL
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                PieChartSectionData(
                  value: express, 
                  title: '${((express/total)*100).toInt()}%', 
                  color: Colors.redAccent, 
                  radius: selectedDonutIndex == 1 ? 50 : 40, // DIPERKECIL
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Indicator(color: Colors.blue, text: "Reguler"),
            Indicator(color: Colors.redAccent, text: "Express")
          ],
        ),
      ],
    );
  }

  // Grafik 3: Metode Antar / Jemput (BARU)
  Widget _buildDeliveryMethodChart() {
    // Menggunakan data 'pickup_breakdown' dari API yang sudah tersedia
    final pickupData = (stats['pickup_breakdown'] as List?) ?? [];
    
    // Variabel untuk menampung data
    double antarJemput = 0; // is_pickup = 1 (Layanan Jemput)
    double dropOff = 0;     // is_pickup = 0 (Antar Sendiri ke Toko)

    if (pickupData.isNotEmpty) {
      for (var item in pickupData) {
        int isPickup = int.tryParse(item['is_pickup'].toString()) ?? 0;
        double count = double.tryParse(item['count'].toString()) ?? 0;
        
        if (isPickup == 1) {
          antarJemput += count;
        } else {
          dropOff += count;
        }
      }
    }

    final total = antarJemput + dropOff;
    
    if (total == 0) {
      return const Center(child: Text("Belum ada data metode", style: TextStyle(color: Colors.grey)));
    }

    return Row(
      children: [
        // Bagian Grafik Pie
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1.2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                        selectedDeliveryIndex = -1;
                        return;
                      }
                      selectedDeliveryIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 45, // Diperbesar dari 40 agar lebih lega
                sections: [
                  PieChartSectionData(
                    value: antarJemput,
                    title: '${((antarJemput/total)*100).toInt()}%',
                    titlePositionPercentageOffset: 0.25, // Move text closer to inner center
                    color: Colors.purpleAccent,
                    radius: selectedDeliveryIndex == 0 ? 55 : 45,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    badgeWidget: _Badge(Icons.delivery_dining, size: selectedDeliveryIndex == 0 ? 25 : 22, color: Colors.purple.shade900),
                    badgePositionPercentageOffset: 0.7, // pull deeper to prevent overflow
                  ),
                  PieChartSectionData(
                    value: dropOff,
                    title: '${((dropOff/total)*100).toInt()}%',
                    titlePositionPercentageOffset: 0.25,
                    color: Colors.teal,
                    radius: selectedDeliveryIndex == 1 ? 55 : 45,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    badgeWidget: _Badge(Icons.storefront, size: selectedDeliveryIndex == 1 ? 25 : 22, color: Colors.teal.shade900),
                    badgePositionPercentageOffset: 0.7, // pull deeper to prevent overflow
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tambahkan jarak di sini
        const SizedBox(width: 20),
        // Bagian Keterangan (Legend) di sebelah kanan agar layout beda
        const Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Indicator(color: Colors.purpleAccent, text: "Antar Jemput", isSquare: true),
              SizedBox(height: 10),
              Indicator(color: Colors.teal, text: "Drop Off", isSquare: true),
            ],
          ),
        ),
      ],
    );
  }

  // --- Popular Services ---
  Widget _buildServiceChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Layanan Terpopuler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 20),
        _buildChartCard("Layanan Terlaris", _buildPopularServicesBarChart(), height: 300),
      ],
    );
  }

  Widget _buildPopularServicesBarChart() {
    final servicesData = (stats['service_breakdown'] as List?) ?? [];
    if (servicesData.isEmpty) return const Center(child: Text("Tidak ada data", style: TextStyle(color: Colors.grey)));
    
    final displayData = servicesData.length > 5 ? servicesData.sublist(0, 5) : servicesData;
    double maxVal = 0;
    for(var item in displayData) {
       double c = double.tryParse(item['count'].toString()) ?? 0;
       if(c > maxVal) maxVal = c;
    }
    double maxY = maxVal < 5 ? 5 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.deepPurple.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle( color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < displayData.length) {
                  String name = displayData[value.toInt()]['nama_layanan'] ?? '-';
                  if (name.length > 8) name = "${name.substring(0, 6)}..";
                  return Padding(
                    padding: const EdgeInsets.only(top: 8), 
                    child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple))
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 30, 
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(), 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple)
              )
            )
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY/5),
        borderData: FlBorderData(show: false),
        barGroups: displayData.asMap().entries.map((entry) {
          double count = double.tryParse(entry.value['count'].toString()) ?? 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [BarChartRodData(toY: count, color: Colors.indigo, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))],
          );
        }).toList(),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildPeriodFilter() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Hari', 'Minggu', 'Bulan'].map((period) {
          final isSelected = selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? Colors.deepPurple : Colors.transparent, borderRadius: BorderRadius.circular(20)),
              child: Text(period, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool isLarge = false}) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: isLarge ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                if (isLarge) Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: isLarge ? 30 : 24),
              ],
            ),
            if(!isLarge) ...[const SizedBox(height: 8), Text(title, style: TextStyle(fontSize: 12))],
            SizedBox(height: isLarge ? 10 : 5),
            Text(value, style: TextStyle(fontSize: isLarge ? 24 : 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart, {double height = 250}) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)), 
            const SizedBox(height: 15), 
            SizedBox(height: height, child: chart)
          ]
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "0";
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toInt().toString();
  }
}

// Widget tambahan untuk icon di dalam pie chart
class _Badge extends StatelessWidget {
  const _Badge(this.icon, {required this.size, required this.color});
  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 3)],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(child: Icon(icon, color: color, size: size * 0.6)),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  const Indicator({super.key, required this.color, required this.text, this.isSquare = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Agar wrap berfungsi baik
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: isSquare ? BoxShape.rectangle : BoxShape.circle)), 
        const SizedBox(width: 6), 
        Flexible(
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        )
      ]
    );
  }
}