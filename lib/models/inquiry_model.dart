class InquiryModel {
  final String customerName;
  final String roomTitle;
  final String roomLocation;
  final String type;
  final String message;
  final String time;
  final String status;
  final bool isVisibleToCustomer;
  final DateTime? scheduledVisit;

  InquiryModel({
    required this.customerName,
    required this.roomTitle,
    required this.roomLocation,
    required this.type,
    required this.message,
    required this.time,
    this.status = "Pending",
    this.isVisibleToCustomer = true,
    this.scheduledVisit,
  });

  InquiryModel copyWith({
    String? status,
    bool? isVisibleToCustomer,
    DateTime? scheduledVisit,
  }) {
    return InquiryModel(
      customerName: customerName,
      roomTitle: roomTitle,
      roomLocation: roomLocation,
      type: type,
      message: message,
      time: time,
      status: status ?? this.status,
      isVisibleToCustomer: isVisibleToCustomer ?? this.isVisibleToCustomer,
      scheduledVisit: scheduledVisit ?? this.scheduledVisit,
    );
  }
}
