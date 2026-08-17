import 'package:flutter_test/flutter_test.dart';

import 'package:stay_nest/services/inquiry_service.dart';
import 'package:stay_nest/services/room_service.dart';
import 'package:stay_nest/services/saved_rooms_service.dart';
import 'package:stay_nest/services/user_service.dart';

void main() {
  group('profile validation', () {
    test('accepts practical profile fields', () {
      expect(
        () => validateUserProfileFields(
          fullName: 'StayNest User',
          phoneNumber: '9800000000',
        ),
        returnsNormally,
      );
    });

    test('rejects empty or oversized profile fields', () {
      expect(
        () => validateUserProfileFields(fullName: '   ', phoneNumber: ''),
        throwsArgumentError,
      );
      expect(
        () => validateUserProfileFields(
          fullName: List.filled(121, 'x').join(),
          phoneNumber: '',
        ),
        throwsArgumentError,
      );
      expect(
        () => validateUserProfileFields(
          fullName: 'User',
          phoneNumber: List.filled(31, '1').join(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('room validation', () {
    void validRoom({num rent = 10000, List<String> images = const []}) {
      validateRoomFields(
        title: 'Room',
        location: 'Kathmandu',
        monthlyRent: rent,
        genderPreference: 'Any',
        description: 'Description',
        imageUrls: images,
      );
    }

    test('keeps empty legacy image lists compatible', () {
      expect(validRoom, returnsNormally);
    });

    test('rejects unsafe rent and oversized image lists', () {
      expect(() => validRoom(rent: 0), throwsArgumentError);
      expect(
        () => validRoom(images: List.filled(11, 'legacy-image')),
        throwsArgumentError,
      );
    });
  });

  test('saved room IDs reject empty, oversized, and path values', () {
    expect(() => validateSavedRoomId('room-id'), returnsNormally);
    expect(() => validateSavedRoomId(''), throwsArgumentError);
    expect(() => validateSavedRoomId('rooms/id'), throwsArgumentError);
    expect(
      () => validateSavedRoomId(List.filled(129, 'x').join()),
      throwsArgumentError,
    );
  });

  group('inquiry validation', () {
    test('message requires 1 to 2000 trimmed characters', () {
      expect(() => validateInquiryMessage('Hello'), returnsNormally);
      expect(() => validateInquiryMessage('   '), throwsArgumentError);
      expect(
        () => validateInquiryMessage(List.filled(2001, 'x').join()),
        throwsArgumentError,
      );
    });

    test('scheduled visit must be in the future', () {
      final now = DateTime.utc(2026, 8, 17, 8);
      expect(
        () => validateScheduledVisitAt(
          now.add(const Duration(hours: 1)),
          now: now,
        ),
        returnsNormally,
      );
      expect(
        () => validateScheduledVisitAt(now, now: now),
        throwsArgumentError,
      );
      expect(
        () => validateScheduledVisitAt(
          now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
