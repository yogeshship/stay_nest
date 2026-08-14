import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_model.dart';

class SavedRoomsService {
  SavedRoomsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _savedRooms =>
      _firestore.collection('savedRooms');

  Stream<Set<String>> watchSavedRoomIds() {
    final customerId = _requireAuthenticatedUid();
    return _savedRooms
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => document.data()['roomId'])
              .whereType<String>()
              .toSet(),
        );
  }

  Stream<List<RoomModel>> watchSavedRooms() {
    final controller = StreamController<List<RoomModel>>();
    final roomSubscriptions =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final rooms = <String, RoomModel>{};
    final initializedRoomIds = <String>{};
    var currentRoomIds = <String>{};
    StreamSubscription<Set<String>>? savedIdsSubscription;

    void emitRooms() {
      if (!initializedRoomIds.containsAll(currentRoomIds)) return;
      final result = currentRoomIds
          .map((roomId) => rooms[roomId])
          .whereType<RoomModel>()
          .toList();
      result.sort((a, b) {
        final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      controller.add(result);
    }

    controller.onListen = () {
      savedIdsSubscription = watchSavedRoomIds().listen(
        (roomIds) {
          final removedIds = currentRoomIds.difference(roomIds);
          for (final roomId in removedIds) {
            unawaited(roomSubscriptions.remove(roomId)?.cancel());
            rooms.remove(roomId);
            initializedRoomIds.remove(roomId);
          }

          final addedIds = roomIds.difference(currentRoomIds);
          currentRoomIds = roomIds;
          for (final roomId in addedIds) {
            roomSubscriptions[roomId] =
                _firestore.collection('rooms').doc(roomId).snapshots().listen(
              (document) {
                initializedRoomIds.add(roomId);
                if (document.exists) {
                  rooms[roomId] = RoomModel.fromFirestore(document);
                } else {
                  rooms.remove(roomId);
                }
                emitRooms();
              },
              onError: controller.addError,
            );
          }
          emitRooms();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () async {
      await savedIdsSubscription?.cancel();
      for (final subscription in roomSubscriptions.values) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Stream<bool> isRoomSavedStream(String roomId) {
    return watchSavedRoomIds().map((roomIds) => roomIds.contains(roomId));
  }

  Future<void> saveRoom(String roomId) async {
    final customerId = _requireAuthenticatedUid();
    await _savedRooms.doc(_saveId(customerId, roomId)).set({
      'customerId': customerId,
      'roomId': roomId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveRoom(String roomId) async {
    final customerId = _requireAuthenticatedUid();
    await _savedRooms.doc(_saveId(customerId, roomId)).delete();
  }

  Future<void> toggleSavedRoom(
    String roomId, {
    required bool isCurrentlySaved,
  }) async {
    if (isCurrentlySaved) {
      await unsaveRoom(roomId);
    } else {
      await saveRoom(roomId);
    }
  }

  String _requireAuthenticatedUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }

  String _saveId(String customerId, String roomId) => '${customerId}_$roomId';
}

String friendlySavedRoomError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to change saved rooms.',
      'unavailable' =>
        'Saved rooms are temporarily unavailable. Please try again.',
      _ => 'Saved rooms could not be updated. Please try again.',
    };
  }
  return 'Saved rooms could not be updated. Please try again.';
}
