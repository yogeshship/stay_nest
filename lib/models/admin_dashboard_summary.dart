class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.pendingVerifications,
    required this.availableRooms,
    required this.unavailableRooms,
    required this.recentActions,
  });

  final int pendingVerifications;
  final int availableRooms;
  final int unavailableRooms;
  final int recentActions;
}
