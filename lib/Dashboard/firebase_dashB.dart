import 'package:cloud_firestore/cloud_firestore.dart';

enum DashStatus { urgent, doing, overdue, done }

class DashboardStats {
  final List<DateTime> days;
  final Map<DashStatus, List<int>> series;
  final Map<DashStatus, int> totals;
  final int totalJobs;
  final double totalIncome;

  DashboardStats({
    required this.days,
    required this.series,
    required this.totals,
    required this.totalJobs,
    required this.totalIncome,
  });
}

class DashboardService {
  final FirebaseFirestore _db;
  DashboardService(this._db);

  Stream<DashboardStats> watchStats({String? userId}) {
    if (userId == null || userId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('jobs')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map(_fromSnap);
  }

  DashboardStats _fromSnap(QuerySnapshot snap) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final series = {
      DashStatus.urgent: List<int>.filled(7, 0),
      DashStatus.doing: List<int>.filled(7, 0),
      DashStatus.overdue: List<int>.filled(7, 0),
      DashStatus.done: List<int>.filled(7, 0),
    };
    final totals = {
      DashStatus.urgent: 0,
      DashStatus.doing: 0,
      DashStatus.overdue: 0,
      DashStatus.done: 0,
    };

    double incomeSum = 0;

    for (final doc in snap.docs) {
      final data = (doc.data() as Map<String, dynamic>? ?? {});
      final statusRaw = (data['status'] ?? 'doing').toString();
      final pickupDate = _dateFrom(data['pickupDate']) ?? today;

      final isOverdue = pickupDate.isBefore(today) && statusRaw != 'done';
      final status = _mapStatus(statusRaw, isOverdue);

      totals[status] = (totals[status] ?? 0) + 1;

      final index = days.indexWhere((d) => _isSameDay(d, pickupDate));
      if (index >= 0) {
        series[status]![index] = series[status]![index] + 1;
      }

      final deposit = _toDouble(data['deposit']);
      final extraPaid = _toDouble(data['extraPaid']);
      final baseIncome = _toDouble(
        data['total'] ?? data['price'] ?? data['amount'] ?? data['income'],
      );
      incomeSum += deposit + extraPaid + baseIncome;
    }

    return DashboardStats(
      days: days,
      series: series,
      totals: totals,
      totalJobs: snap.docs.length,
      totalIncome: incomeSum,
    );
  }

  DashStatus _mapStatus(String s, bool overdue) {
    if (overdue) return DashStatus.overdue;
    switch (s) {
      case 'urgent':
        return DashStatus.urgent;
      case 'done':
        return DashStatus.done;
      case 'doing':
      default:
        return DashStatus.doing;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _dateFrom(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
