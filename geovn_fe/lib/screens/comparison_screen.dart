import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/province_model.dart';

class ComparisonScreen extends StatelessWidget {
  final Province provinceA;
  final Province provinceB;

  const ComparisonScreen({super.key, required this.provinceA, required this.provinceB});


  String _formatNumber(double value) {
    return NumberFormat('#,###', 'vi_VN').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color colorPop = Colors.blueAccent;
    final Color colorArea = Colors.orangeAccent;


    double maxPop = (provinceA.population > provinceB.population) ? provinceA.population : provinceB.population;
    double maxArea = (provinceA.area > provinceB.area) ? provinceA.area : provinceB.area;


    double areaScaleFactor = maxPop / (maxArea == 0 ? 1 : maxArea);
    double chartMaxY = maxPop * 1.25;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text('So sánh chi tiết',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildHorizontalStatRow('Dân số', provinceA.name, provinceB.name,
                  provinceA.population, provinceB.population, isDark, colorPop,
                  unit: 'người', isInteger: true),

              const SizedBox(height: 16),


              _buildHorizontalStatRow('Diện tích', provinceA.name, provinceB.name,
                  provinceA.area, provinceB.area, isDark, colorArea,
                  unit: 'km²', isInteger: false),

              const SizedBox(height: 32),


              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(colorPop, 'Dân số', isDark),
                  const SizedBox(width: 24),
                  _buildLegendItem(colorArea, 'Diện tích', isDark),
                ],
              ),

              const SizedBox(height: 24),


              Container(
                height: 350,
                padding: const EdgeInsets.only(top: 10),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            String name = value.toInt() == 0 ? provinceA.name : provinceB.name;
                            String formattedName = name.replaceAll(' ', '\n');

                            return SideTitleWidget(
                              meta: meta,
                              space: 10,
                              child: Text(
                                formattedName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [

                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(toY: provinceA.population, color: colorPop, width: 20, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: provinceA.area * areaScaleFactor, color: colorArea, width: 20, borderRadius: BorderRadius.circular(4)),
                      ]),

                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(toY: provinceB.population, color: colorPop, width: 20, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: provinceB.area * areaScaleFactor, color: colorArea, width: 20, borderRadius: BorderRadius.circular(4)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHorizontalStatRow(String label, String nameA, String nameB,
      double valA, double valB, bool isDark, Color activeColor,
      {required String unit, required bool isInteger}) {
    bool aHigher = valA > valB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Expanded(child: _buildStatColumn(nameA, valA, aHigher, activeColor, isInteger, unit)),
              Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.1)),
              Expanded(child: _buildStatColumn(nameB, valB, !aHigher, activeColor, isInteger, unit)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String name, double val, bool isWinner, Color color, bool isInteger, String unit) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          isInteger ? _formatNumber(val) : val.toStringAsFixed(1),
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isWinner ? color : null
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}