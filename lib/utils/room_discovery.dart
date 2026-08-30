import '../models/room_model.dart';

enum RoomSortOption {
  newest,
  rentLowToHigh,
  rentHighToLow,
}

class RoomDiscoveryCriteria {
  const RoomDiscoveryCriteria({
    this.query = '',
    this.minRent,
    this.maxRent,
    this.genderPreference,
    this.sortOption = RoomSortOption.newest,
  });

  final String query;
  final num? minRent;
  final num? maxRent;
  final String? genderPreference;
  final RoomSortOption sortOption;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasActiveFilters =>
      minRent != null || maxRent != null || genderPreference != null;

  int get activeFilterCount =>
      (minRent == null ? 0 : 1) +
      (maxRent == null ? 0 : 1) +
      (genderPreference == null ? 0 : 1);
}

num? parseOptionalRent(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final rent = num.tryParse(trimmed);
  if (rent == null || !rent.isFinite || rent < 0) {
    throw const FormatException('Enter a valid non-negative rent amount.');
  }
  return rent;
}

String? validateRentRange(num? minRent, num? maxRent) {
  if (minRent != null && maxRent != null && minRent > maxRent) {
    return 'Minimum rent cannot be greater than maximum rent.';
  }
  return null;
}

List<RoomModel> filterAndSortRooms(
  Iterable<RoomModel> rooms,
  RoomDiscoveryCriteria criteria,
) {
  final normalizedQuery = criteria.query.trim().toLowerCase();
  final normalizedGender = criteria.genderPreference?.trim().toLowerCase();

  final results = rooms.where((room) {
    if (!room.isAvailable) return false;

    final matchesQuery = normalizedQuery.isEmpty ||
        room.title.toLowerCase().contains(normalizedQuery) ||
        room.location.toLowerCase().contains(normalizedQuery);
    if (!matchesQuery) return false;

    if (criteria.minRent != null && room.monthlyRent < criteria.minRent!) {
      return false;
    }
    if (criteria.maxRent != null && room.monthlyRent > criteria.maxRent!) {
      return false;
    }

    if (normalizedGender != null && normalizedGender.isNotEmpty) {
      final roomGender = room.genderPreference.trim().toLowerCase();
      if (roomGender != normalizedGender && roomGender != 'any') return false;
    }

    return true;
  }).toList(growable: false);

  final sorted = List<RoomModel>.of(results);
  sorted.sort((a, b) => switch (criteria.sortOption) {
        RoomSortOption.newest => _compareNewest(a, b),
        RoomSortOption.rentLowToHigh => _compareRent(a, b, ascending: true),
        RoomSortOption.rentHighToLow => _compareRent(a, b, ascending: false),
      });
  return sorted;
}

int _compareRent(RoomModel a, RoomModel b, {required bool ascending}) {
  final aHasValidRent = a.monthlyRent > 0;
  final bHasValidRent = b.monthlyRent > 0;
  if (aHasValidRent != bHasValidRent) return aHasValidRent ? -1 : 1;

  if (aHasValidRent) {
    final rentComparison = ascending
        ? a.monthlyRent.compareTo(b.monthlyRent)
        : b.monthlyRent.compareTo(a.monthlyRent);
    if (rentComparison != 0) return rentComparison;
  }

  return _compareNewest(a, b);
}

int _compareNewest(RoomModel a, RoomModel b) {
  if (a.createdAt == null && b.createdAt != null) return 1;
  if (a.createdAt != null && b.createdAt == null) return -1;
  if (a.createdAt != null && b.createdAt != null) {
    final dateComparison = b.createdAt!.compareTo(a.createdAt!);
    if (dateComparison != 0) return dateComparison;
  }
  return a.id.compareTo(b.id);
}
