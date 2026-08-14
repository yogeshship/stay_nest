import '../models/inquiry_model.dart';

class InquiryService {
  static final List<InquiryModel> inquiries = [];

  static void addInquiry(InquiryModel inquiry) {
    inquiries.add(inquiry);
  }

  static void updateStatus(int index, String status) {
    inquiries[index] = inquiries[index].copyWith(status: status);
  }

  static void scheduleVisit(int index, DateTime scheduledVisit) {
    inquiries[index] = inquiries[index].copyWith(
      status: "Visit Scheduled",
      scheduledVisit: scheduledVisit,
    );
  }

  static void hideFromCustomer(int index) {
    inquiries[index] = inquiries[index].copyWith(isVisibleToCustomer: false);
  }
}
