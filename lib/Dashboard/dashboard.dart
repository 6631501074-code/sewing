import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'firebase_dashB.dart';
import 'package:sewing/session/user_session.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserSession.getUsername();
    if (!mounted) return;
    setState(() => _userId = user);
  }

  @override
  Widget build(BuildContext context) {
    final service = DashboardService(FirebaseFirestore.instance);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('รายการแดชบอร์ด'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _userId == null
          ? const Center(child: Text('ยังไม่ได้เข้าสู่ระบบ'))
          : StreamBuilder<DashboardStats>(
              stream: service.watchStats(userId: _userId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snap.data!;
                final maxY = _maxSeries(stats) + 1;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    _SummaryRow(
                      totalJobs: stats.totalJobs,
                      totalIncome: stats.totalIncome,
                    ),
                    const SizedBox(height: 12),
                    _StatusBarChart(totals: stats.totals),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'แนวโน้มงานตามสถานะ (7 วันล่าสุด)',
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: maxY.toDouble(),
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) =>
                                      Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= stats.days.length) return const SizedBox.shrink();
                                    final label = DateFormat('d/M').format(stats.days[i]);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(label, style: const TextStyle(fontSize: 10)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              _line(stats, DashStatus.urgent, const Color(0xFFB42318)),
                              _line(stats, DashStatus.doing, const Color(0xFF1D4ED8)),
                              _line(stats, DashStatus.overdue, const Color(0xFFB45309)),
                              _line(stats, DashStatus.done, const Color(0xFF047857)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'หมายเหตุ: รายได้รวมมัดจำและยอดชำระเพิ่ม (extraPaid) แล้ว',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
    );
  }

  LineChartBarData _line(DashboardStats stats, DashStatus status, Color color) {
    final points = stats.series[status] ?? const <int>[];
    return LineChartBarData(
      spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].toDouble())),
      isCurved: true,
      color: color,
      barWidth: 2.6,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  int _maxSeries(DashboardStats stats) {
    var max = 0;
    for (final series in stats.series.values) {
      for (final v in series) {
        if (v > max) max = v;
      }
    }
    return max;
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalJobs;
  final double totalIncome;

  const _SummaryRow({
    required this.totalJobs,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'งานทั้งหมด',
            value: totalJobs.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'รายได้รวม',
            value: _moneyInt(totalIncome),
          ),
        ),
      ],
    );
  }

  String _money(double v) => NumberFormat('#,##0.00').format(v);
  String _moneyInt(double v) => NumberFormat('#,##0').format(v.round());
}

class _StatusBarChart extends StatelessWidget {
  final Map<DashStatus, int> totals;
  const _StatusBarChart({required this.totals});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'กราฟสถานะงานรวม',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: _maxTotal(totals).toDouble() + 1,
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) =>
                      Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final label = switch (value.toInt()) {
                      0 => 'เร่งด่วน',
                      1 => 'กำลังทำ',
                      2 => 'เลยกำหนด',
                      3 => 'เสร็จแล้ว',
                      _ => '',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(label, style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              _bar(0, totals[DashStatus.urgent] ?? 0, const Color(0xFFB42318)),
              _bar(1, totals[DashStatus.doing] ?? 0, const Color(0xFF1D4ED8)),
              _bar(2, totals[DashStatus.overdue] ?? 0, const Color(0xFFB45309)),
              _bar(3, totals[DashStatus.done] ?? 0, const Color(0xFF047857)),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  int _maxTotal(Map<DashStatus, int> totals) {
    var max = 0;
    for (final v in totals.values) {
      if (v > max) max = v;
    }
    return max;
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0F111827)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0F111827)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
