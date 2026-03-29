class DashboardStats {
  final int pendingRentals;
  final int activeRentals;
  final int availableCars;
  final double revenue;

  DashboardStats({
    required this.pendingRentals,
    required this.activeRentals,
    required this.availableCars,
    required this.revenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      pendingRentals:
          int.tryParse(json['totalBookings']?.toString() ?? '0') ?? 0,
      activeRentals:
          int.tryParse(json['activeBookings']?.toString() ?? '0') ?? 0,
      availableCars: int.tryParse(json['totalCars']?.toString() ?? '0') ?? 0,
      revenue: 0.0,
    );
  }
}
