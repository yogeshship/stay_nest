import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_model.dart';

class RoomService {
  RoomService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  Stream<List<RoomModel>> watchAvailableRooms() {
    return _rooms.where('isAvailable', isEqualTo: true).snapshots().map(
          (snapshot) => _sortedRooms(snapshot.docs),
        );
  }

  Stream<List<RoomModel>> watchOwnerRooms() {
    final ownerId = _requireAuthenticatedUid();
    return _rooms.where('ownerId', isEqualTo: ownerId).snapshots().map(
          (snapshot) => _sortedRooms(snapshot.docs),
        );
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    final document = await _rooms.doc(roomId).get();
    return document.exists ? RoomModel.fromFirestore(document) : null;
  }

  Future<String> addRoom({
    required String title,
    required String location,
    required num monthlyRent,
    required String genderPreference,
    required String description,
    required List<String> imageUrls,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    final document = _rooms.doc();
    await document.set({
      'ownerId': ownerId,
      'title': title.trim(),
      'location': location.trim(),
      'monthlyRent': monthlyRent,
      'genderPreference': genderPreference.trim(),
      'description': description.trim(),
      'imageUrls': imageUrls,
      'isAvailable': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateRoom({
    required String roomId,
    required String title,
    required String location,
    required num monthlyRent,
    required String genderPreference,
    required String description,
    required List<String> imageUrls,
  }) async {
    _requireAuthenticatedUid();
    await _rooms.doc(roomId).update({
      'title': title.trim(),
      'location': location.trim(),
      'monthlyRent': monthlyRent,
      'genderPreference': genderPreference.trim(),
      'description': description.trim(),
      'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAvailability(String roomId, bool isAvailable) async {
    _requireAuthenticatedUid();
    await _rooms.doc(roomId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoom(String roomId) async {
    _requireAuthenticatedUid();
    await _rooms.doc(roomId).delete();
  }

  String _requireAuthenticatedUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }

  List<RoomModel> _sortedRooms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final rooms = documents.map(RoomModel.fromFirestore).toList();
    rooms.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return rooms;
  }
}

String friendlyRoomError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'You do not have permission to manage this room.',
      'unavailable' =>
        'The room service is temporarily unavailable. Please try again.',
      'not-found' => 'This room no longer exists.',
      _ => 'The room could not be saved. Please try again.',
    };
  }
  return 'The room could not be saved. Please try again.';
}
