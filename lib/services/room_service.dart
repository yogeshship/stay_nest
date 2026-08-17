import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_model.dart';
import 'storage_service.dart';

class RoomService {
  RoomService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storageService = storageService ?? StorageService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final StorageService _storageService;

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

  String createRoomId() {
    _requireAuthenticatedUid();
    return _rooms.doc().id;
  }

  Future<void> addRoomWithId({
    required String roomId,
    required String title,
    required String location,
    required num monthlyRent,
    required String genderPreference,
    required String description,
    required List<String> imageUrls,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    validateRoomFields(
      title: title,
      location: location,
      monthlyRent: monthlyRent,
      genderPreference: genderPreference,
      description: description,
      imageUrls: imageUrls,
    );
    if (imageUrls.isEmpty ||
        imageUrls.any((url) =>
            !url.startsWith('https://firebasestorage.googleapis.com/'))) {
      throw ArgumentError(
          'New rooms require uploaded Firebase Storage images.');
    }
    final document = _rooms.doc(roomId);
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
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    validateRoomFields(
      title: title,
      location: location,
      monthlyRent: monthlyRent,
      genderPreference: genderPreference,
      description: description,
      imageUrls: imageUrls,
    );
    final currentRoom = await _requireOwnedRoom(roomId, ownerId);
    if (imageUrls.isEmpty ||
        imageUrls.any((url) =>
            !url.startsWith('https://firebasestorage.googleapis.com/'))) {
      throw ArgumentError('Room images must be Firebase Storage URLs.');
    }
    await _rooms.doc(roomId).update({
      'title': title.trim(),
      'location': location.trim(),
      'monthlyRent': monthlyRent,
      'genderPreference': genderPreference.trim(),
      'description': description.trim(),
      'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final replacedUrls = currentRoom.imageUrls
        .where((url) => !imageUrls.contains(url))
        .toList(growable: false);
    await _storageService.deleteRoomImageUrls(
      roomId: roomId,
      urls: replacedUrls,
    );
  }

  Future<void> updateAvailability(String roomId, bool isAvailable) async {
    _requireAuthenticatedUid();
    await _rooms.doc(roomId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoom(String roomId) async {
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    await _requireOwnedRoom(roomId, ownerId);
    await _rooms.doc(roomId).delete();
    try {
      if (_requireAuthenticatedUid() != ownerId) {
        throw StateError('The signed-in owner changed during deletion.');
      }
      await _storageService.deleteRoomImages(roomId: roomId);
    } catch (_) {
      throw StateError(
        'The room listing was deleted, but some image files could not be cleaned up. They are now orphaned and may require a later cleanup.',
      );
    }
  }

  Future<RoomModel> _requireOwnedRoom(String roomId, String ownerId) async {
    final document = await _rooms.doc(roomId).get();
    if (!document.exists) throw StateError('This room no longer exists.');
    final room = RoomModel.fromFirestore(document);
    if (room.ownerId != ownerId) {
      throw StateError('You can only manage your own room images.');
    }
    return room;
  }

  void _validateRoomId(String roomId) {
    if (roomId.trim().isEmpty || roomId.length > 128 || roomId.contains('/')) {
      throw ArgumentError('A valid room ID is required.');
    }
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
      'aborted' =>
        'The room changed while it was being saved. Please try again.',
      'failed-precondition' =>
        'The room is no longer in a state that can be changed.',
      _ => 'The room could not be saved. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'The room could not be saved. Please try again.';
}

void validateRoomFields({
  required String title,
  required String location,
  required num monthlyRent,
  required String genderPreference,
  required String description,
  required List<String> imageUrls,
}) {
  void requireLength(String value, String label, int maximum) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > maximum) {
      throw ArgumentError('$label must be between 1 and $maximum characters.');
    }
  }

  requireLength(title, 'Title', 150);
  requireLength(location, 'Location', 200);
  requireLength(genderPreference, 'Gender preference', 50);
  requireLength(description, 'Description', 5000);
  if (monthlyRent <= 0 || monthlyRent > 1000000000) {
    throw ArgumentError('Monthly rent must be greater than 0 and realistic.');
  }
  if (imageUrls.length > 10) {
    throw ArgumentError('A room cannot contain more than 10 image references.');
  }
}
