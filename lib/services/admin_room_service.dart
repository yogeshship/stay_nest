import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';

class AdminRoomPage {
  const AdminRoomPage(
      {required this.rooms, required this.cursor, required this.hasMore});
  final List<RoomModel> rooms;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class AdminRoomService {
  AdminRoomService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Future<AdminRoomPage> loadRooms(
      {int limit = 25,
      bool? isAvailable,
      DocumentSnapshot<Map<String, dynamic>>? startAfter}) async {
    if (limit < 1 || limit > 100) throw ArgumentError('Invalid page size.');
    Query<Map<String, dynamic>> query = _firestore.collection('rooms');
    if (isAvailable != null) {
      query = query.where('isAvailable', isEqualTo: isAvailable);
    }
    query = query.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snapshot = await query.get();
    return AdminRoomPage(
        rooms:
            snapshot.docs.map(RoomModel.fromFirestore).toList(growable: false),
        cursor: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit);
  }

  Future<void> setRoomAvailability(
      {required String roomId,
      required bool isAvailable,
      required String reason}) async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      throw StateError('You must be signed in as an administrator.');
    }
    if (roomId.trim().isEmpty || roomId.length > 128 || roomId.contains('/')) {
      throw ArgumentError('Invalid room ID.');
    }
    if (reason.trim().isEmpty || reason.trim().length > 500) {
      throw ArgumentError('A valid reason is required.');
    }
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final auditRef = _firestore.collection('adminActions').doc();
    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      if (!roomDoc.exists) throw StateError('This room no longer exists.');
      final room = RoomModel.fromFirestore(roomDoc);
      transaction.update(roomRef, {
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp()
      });
      transaction.set(auditRef, {
        'adminId': adminId,
        'actionType':
            isAvailable ? 'restore_room_availability' : 'set_room_unavailable',
        'targetType': 'room',
        'targetId': roomId,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'previousValue': room.isAvailable.toString(),
        'newValue': isAvailable.toString()
      });
    });
  }
}
