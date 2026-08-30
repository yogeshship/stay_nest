import 'inquiry_model.dart';
import 'review_model.dart';
import 'room_model.dart';

class OwnerReviewSnapshot {
  const OwnerReviewSnapshot({required this.reviews, required this.loadedAt});

  final List<ReviewModel> reviews;
  final DateTime loadedAt;
}

class RoomPerformance {
  const RoomPerformance({
    required this.room,
    required this.totalRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.completedRequests,
    required this.completedVisitCount,
    required this.declinedRequests,
    required this.unreadRequestCount,
    required this.reviewCount,
    required this.averageRating,
    this.latestRequestAt,
  });

  final RoomModel room;
  final int totalRequests;
  final int pendingRequests;
  final int acceptedRequests;
  final int completedRequests;
  final int completedVisitCount;
  final int declinedRequests;
  final int unreadRequestCount;
  final int reviewCount;
  final double averageRating;
  final DateTime? latestRequestAt;
}

class OwnerAnalytics {
  const OwnerAnalytics({
    required this.totalListings,
    required this.availableListings,
    required this.unavailableListings,
    required this.totalRequests,
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.completedRequests,
    required this.completedVisits,
    required this.declinedRequests,
    required this.unreadRequests,
    required this.cancelledOrOtherRequests,
    required this.totalReviews,
    required this.averageRating,
    required this.ratedRoomCount,
    required this.orphanedInquiryCount,
    required this.roomPerformance,
    required this.recentInquiries,
  });

  final int totalListings;
  final int availableListings;
  final int unavailableListings;
  final int totalRequests;
  final int pendingRequests;
  final int acceptedRequests;
  final int completedRequests;
  final int completedVisits;
  final int declinedRequests;
  final int unreadRequests;
  final int cancelledOrOtherRequests;
  final int totalReviews;
  final double averageRating;
  final int ratedRoomCount;
  final int orphanedInquiryCount;
  final List<RoomPerformance> roomPerformance;
  final List<InquiryModel> recentInquiries;
}

Map<String, List<InquiryModel>> groupInquiriesByRoomId(
  Iterable<InquiryModel> inquiries,
) {
  final grouped = <String, List<InquiryModel>>{};
  for (final inquiry in inquiries) {
    grouped.putIfAbsent(inquiry.roomId, () => []).add(inquiry);
  }
  return grouped;
}

Map<String, List<ReviewModel>> groupReviewsByRoomId(
  Iterable<ReviewModel> reviews,
) {
  final grouped = <String, List<ReviewModel>>{};
  final seen = <String>{};
  for (final review in reviews) {
    if (!seen.add(review.id)) continue;
    grouped.putIfAbsent(review.roomId, () => []).add(review);
  }
  return grouped;
}

double weightedAverageRating(Iterable<ReviewModel> reviews) {
  final unique = <String, ReviewModel>{};
  for (final review in reviews) {
    if (review.rating >= 1 && review.rating <= 5) {
      unique.putIfAbsent(review.id, () => review);
    }
  }
  if (unique.isEmpty) return 0;
  final total = unique.values.fold<int>(0, (sum, item) => sum + item.rating);
  return total / unique.length;
}

List<InquiryModel> recentOwnerInquiries(
  Iterable<InquiryModel> inquiries, {
  int limit = 10,
}) {
  final result = inquiries.toList();
  result.sort((a, b) {
    if (a.createdAt == null && b.createdAt != null) return 1;
    if (a.createdAt != null && b.createdAt == null) return -1;
    final byDate = b.createdAt?.compareTo(a.createdAt!) ?? 0;
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return result.take(limit).toList(growable: false);
}

void sortRoomPerformance(List<RoomPerformance> performance) {
  performance.sort((a, b) {
    var comparison = b.unreadRequestCount.compareTo(a.unreadRequestCount);
    if (comparison != 0) return comparison;
    comparison = b.pendingRequests.compareTo(a.pendingRequests);
    if (comparison != 0) return comparison;
    comparison = b.totalRequests.compareTo(a.totalRequests);
    if (comparison != 0) return comparison;
    return a.room.title.toLowerCase().compareTo(b.room.title.toLowerCase());
  });
}

OwnerAnalytics calculateOwnerAnalytics({
  required Iterable<RoomModel> rooms,
  required Iterable<InquiryModel> inquiries,
  required Iterable<ReviewModel> reviews,
}) {
  final roomList = rooms.toList(growable: false);
  final inquiryList = inquiries.toList(growable: false);
  final validReviews = <String, ReviewModel>{};
  final roomIds = roomList.map((room) => room.id).toSet();
  for (final review in reviews) {
    if (roomIds.contains(review.roomId) &&
        review.rating >= 1 &&
        review.rating <= 5) {
      validReviews.putIfAbsent(review.id, () => review);
    }
  }
  final groupedInquiries = groupInquiriesByRoomId(inquiryList);
  final groupedReviews = groupReviewsByRoomId(validReviews.values);
  final performance = <RoomPerformance>[];

  for (final room in roomList) {
    final roomInquiries = groupedInquiries[room.id] ?? const <InquiryModel>[];
    final roomReviews = groupedReviews[room.id] ?? const <ReviewModel>[];
    DateTime? latest;
    for (final inquiry in roomInquiries) {
      if (inquiry.createdAt != null &&
          (latest == null || inquiry.createdAt!.isAfter(latest))) {
        latest = inquiry.createdAt;
      }
    }
    performance.add(RoomPerformance(
      room: room,
      totalRequests: roomInquiries.length,
      pendingRequests: _statusCount(roomInquiries, InquiryModel.pendingStatus),
      acceptedRequests:
          _statusCount(roomInquiries, InquiryModel.acceptedStatus),
      completedRequests:
          _statusCount(roomInquiries, InquiryModel.completedStatus),
      completedVisitCount: roomInquiries
          .where((item) =>
              item.type == InquiryModel.visitRequestType &&
              item.status == InquiryModel.completedStatus)
          .length,
      declinedRequests:
          _statusCount(roomInquiries, InquiryModel.declinedStatus),
      unreadRequestCount:
          roomInquiries.where((item) => item.isUnreadForOwner).length,
      reviewCount: roomReviews.length,
      averageRating: weightedAverageRating(roomReviews),
      latestRequestAt: latest,
    ));
  }
  sortRoomPerformance(performance);

  final knownWorkflow = inquiryList
      .where((item) => const {
            InquiryModel.pendingStatus,
            InquiryModel.acceptedStatus,
            InquiryModel.completedStatus,
            InquiryModel.declinedStatus,
          }.contains(item.status))
      .length;
  final reviewedRoomIds =
      validReviews.values.map((item) => item.roomId).toSet();

  return OwnerAnalytics(
    totalListings: roomList.length,
    availableListings: roomList.where((room) => room.isAvailable).length,
    unavailableListings: roomList.where((room) => !room.isAvailable).length,
    totalRequests: inquiryList.length,
    pendingRequests: _statusCount(inquiryList, InquiryModel.pendingStatus),
    acceptedRequests: _statusCount(inquiryList, InquiryModel.acceptedStatus),
    completedRequests: _statusCount(inquiryList, InquiryModel.completedStatus),
    completedVisits: inquiryList
        .where((item) =>
            item.type == InquiryModel.visitRequestType &&
            item.status == InquiryModel.completedStatus)
        .length,
    declinedRequests: _statusCount(inquiryList, InquiryModel.declinedStatus),
    unreadRequests: inquiryList.where((item) => item.isUnreadForOwner).length,
    cancelledOrOtherRequests: inquiryList.length - knownWorkflow,
    totalReviews: validReviews.length,
    averageRating: weightedAverageRating(validReviews.values),
    ratedRoomCount: reviewedRoomIds.length,
    orphanedInquiryCount:
        inquiryList.where((item) => !roomIds.contains(item.roomId)).length,
    roomPerformance: List.unmodifiable(performance),
    recentInquiries: List.unmodifiable(recentOwnerInquiries(inquiryList)),
  );
}

int _statusCount(Iterable<InquiryModel> inquiries, String status) =>
    inquiries.where((item) => item.status == status).length;
