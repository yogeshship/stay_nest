import 'package:flutter_test/flutter_test.dart';
import 'package:stay_nest/models/room_model.dart';
import 'package:stay_nest/utils/room_discovery.dart';

void main() {
  final newest = DateTime.utc(2026, 8, 3);
  final older = DateTime.utc(2026, 8, 1);

  RoomModel room({
    required String id,
    String title = 'Sunny Room',
    String location = 'Baneshwor',
    num rent = 8000,
    String gender = 'Any',
    bool available = true,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id,
      ownerId: 'owner-$id',
      title: title,
      location: location,
      monthlyRent: rent,
      genderPreference: gender,
      description: 'Description',
      imageUrls: const [],
      isAvailable: available,
      createdAt: createdAt,
    );
  }

  group('search', () {
    final rooms = [
      room(id: 'one', title: 'Quiet Studio', location: 'Lazimpat'),
      room(id: 'two', title: 'Shared Room', location: 'Baneshwor'),
      room(id: 'hidden', available: false),
    ];

    test('empty and whitespace queries return all available rooms', () {
      expect(filterAndSortRooms(rooms, const RoomDiscoveryCriteria()),
          hasLength(2));
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(query: '   '),
        ),
        hasLength(2),
      );
    });

    test('matches title and location case-insensitively with trimming', () {
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(query: '  STUDIO '),
        ).single.id,
        'one',
      );
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(query: 'baneshWOR'),
        ).single.id,
        'two',
      );
    });

    test('returns no result for no match', () {
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(query: 'Patan'),
        ),
        isEmpty,
      );
    });

    test('excludes unavailable rooms defensively', () {
      expect(filterAndSortRooms(rooms, const RoomDiscoveryCriteria()),
          isNot(contains(predicate<RoomModel>((value) => !value.isAvailable))));
    });
  });

  group('rent', () {
    final rooms = [
      room(id: 'low', rent: 5000),
      room(id: 'decimal', rent: 7500.50),
      room(id: 'high', rent: 10000),
    ];

    test('supports no bound, minimum, maximum, and inclusive range', () {
      expect(filterAndSortRooms(rooms, const RoomDiscoveryCriteria()),
          hasLength(3));
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(minRent: 7500.50),
        ).map((value) => value.id),
        containsAll(['decimal', 'high']),
      );
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(maxRent: 7500.50),
        ).map((value) => value.id),
        containsAll(['low', 'decimal']),
      );
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(minRent: 5000, maxRent: 10000),
        ),
        hasLength(3),
      );
    });

    test('parses blank, integer, and decimal optional rent', () {
      expect(parseOptionalRent('  '), isNull);
      expect(parseOptionalRent('5000'), 5000);
      expect(parseOptionalRent(' 7500.50 '), 7500.5);
    });

    test('rejects invalid and negative rent input', () {
      expect(() => parseOptionalRent('abc'), throwsFormatException);
      expect(() => parseOptionalRent('-1'), throwsFormatException);
      expect(() => parseOptionalRent('Infinity'), throwsFormatException);
    });

    test('rejects a minimum greater than the maximum', () {
      expect(validateRentRange(9000, 8000), isNotNull);
      expect(validateRentRange(8000, 8000), isNull);
      expect(validateRentRange(null, 8000), isNull);
    });
  });

  group('gender', () {
    final rooms = [
      room(id: 'boys', gender: ' Boys '),
      room(id: 'girls', gender: 'girls'),
      room(id: 'family', gender: 'Family'),
      room(id: 'any', gender: 'Any'),
      room(id: 'legacy', gender: 'Students'),
    ];

    test('no filter includes recognized and unknown legacy values', () {
      expect(filterAndSortRooms(rooms, const RoomDiscoveryCriteria()),
          hasLength(5));
    });

    test('specific filter normalizes case and whitespace', () {
      final result = filterAndSortRooms(
        rooms,
        const RoomDiscoveryCriteria(genderPreference: ' boys '),
      );
      expect(result.map((value) => value.id), containsAll(['boys', 'any']));
      expect(result, hasLength(2));
    });

    for (final preference in ['Boys', 'Girls', 'Family']) {
      test('Any room matches $preference', () {
        final result = filterAndSortRooms(
          rooms,
          RoomDiscoveryCriteria(genderPreference: preference),
        );
        expect(result.map((value) => value.id), contains('any'));
      });
    }

    test('unknown legacy value only matches its normalized value', () {
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(genderPreference: 'Boys'),
        ).map((value) => value.id),
        isNot(contains('legacy')),
      );
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(genderPreference: ' students '),
        ).map((value) => value.id),
        contains('legacy'),
      );
    });
  });

  test('combines query, rent, and gender filters', () {
    final rooms = [
      room(
        id: 'match',
        title: 'Central Room',
        location: 'Baneshwor',
        rent: 9000,
        gender: 'Girls',
      ),
      room(id: 'wrong-rent', title: 'Central Room', rent: 15000),
      room(id: 'wrong-gender', title: 'Central Room', gender: 'Boys'),
    ];

    expect(
      filterAndSortRooms(
        rooms,
        const RoomDiscoveryCriteria(query: 'central'),
      ),
      hasLength(3),
    );
    expect(
      filterAndSortRooms(
        rooms,
        const RoomDiscoveryCriteria(query: 'central', minRent: 8000),
      ),
      hasLength(3),
    );
    expect(
      filterAndSortRooms(
        rooms,
        const RoomDiscoveryCriteria(
          query: 'central',
          genderPreference: 'Girls',
        ),
      ).map((value) => value.id),
      containsAll(['match', 'wrong-rent']),
    );
    expect(
      filterAndSortRooms(
        rooms,
        const RoomDiscoveryCriteria(
          query: 'central',
          minRent: 8000,
          maxRent: 10000,
          genderPreference: 'Girls',
        ),
      ).single.id,
      'match',
    );
  });

  group('sorting', () {
    test('newest puts null timestamps last and breaks ties by ID', () {
      final result = filterAndSortRooms(
        [
          room(id: 'z-null'),
          room(id: 'b-new', createdAt: newest),
          room(id: 'a-new', createdAt: newest),
          room(id: 'old', createdAt: older),
        ],
        const RoomDiscoveryCriteria(),
      );
      expect(
          result.map((value) => value.id), ['a-new', 'b-new', 'old', 'z-null']);
    });

    test('sorts rent ascending and descending with newest as a tie-breaker',
        () {
      final rooms = [
        room(id: 'high', rent: 10000, createdAt: older),
        room(id: 'low-old', rent: 5000, createdAt: older),
        room(id: 'low-new', rent: 5000, createdAt: newest),
      ];
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(
            sortOption: RoomSortOption.rentLowToHigh,
          ),
        ).map((value) => value.id),
        ['low-new', 'low-old', 'high'],
      );
      expect(
        filterAndSortRooms(
          rooms,
          const RoomDiscoveryCriteria(
            sortOption: RoomSortOption.rentHighToLow,
          ),
        ).map((value) => value.id),
        ['high', 'low-new', 'low-old'],
      );
    });

    test('places non-positive legacy rent after valid rent in both directions',
        () {
      final rooms = [room(id: 'unknown', rent: 0), room(id: 'valid', rent: 1)];
      for (final sort in [
        RoomSortOption.rentLowToHigh,
        RoomSortOption.rentHighToLow,
      ]) {
        expect(
          filterAndSortRooms(
            rooms,
            RoomDiscoveryCriteria(sortOption: sort),
          ).map((value) => value.id),
          ['valid', 'unknown'],
        );
      }
    });

    test('does not mutate the source list', () {
      final source = [
        room(id: 'older', createdAt: older),
        room(id: 'newer', createdAt: newest),
      ];
      filterAndSortRooms(source, const RoomDiscoveryCriteria());
      expect(source.map((value) => value.id), ['older', 'newer']);
    });
  });
}
