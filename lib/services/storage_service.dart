import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseAuth? firebaseAuth})
      : _storage = storage ?? FirebaseStorage.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const int maximumRoomImages = 5;

  final FirebaseStorage _storage;
  final FirebaseAuth _firebaseAuth;

  Future<List<String>> uploadRoomImages({
    required String roomId,
    required List<XFile> images,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    if (images.isEmpty || images.length > maximumRoomImages) {
      throw ArgumentError('Choose between 1 and $maximumRoomImages images.');
    }

    final uploadedReferences = <Reference>[];
    final downloadUrls = <String>[];
    final batchId = DateTime.now().microsecondsSinceEpoch;
    try {
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final fileName = roomImageFileName(
          originalName: image.name,
          batchId: batchId,
          index: index,
        );
        final reference = _storage.ref().child(
              'room_images/$ownerId/$roomId/$fileName',
            );
        final metadata = SettableMetadata(
          contentType: image.mimeType ?? roomImageContentType(image.name),
        );
        await reference.putFile(File(image.path), metadata);
        uploadedReferences.add(reference);
        downloadUrls.add(await reference.getDownloadURL());
      }
      return downloadUrls;
    } catch (error) {
      final cleanupSucceeded = await _deleteReferences(uploadedReferences);
      if (!cleanupSucceeded) {
        throw StateError(
          'The upload failed and some uploaded images could not be cleaned up. Please try deleting the listing again or contact support.',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteRoomImages({required String roomId}) async {
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    final folder = _storage.ref().child('room_images/$ownerId/$roomId');
    final result = await folder.listAll();
    final cleanupSucceeded = await _deleteReferences(result.items);
    if (!cleanupSucceeded) {
      throw StateError(
        'Some room images could not be deleted. The listing was kept so you can try again.',
      );
    }
  }

  Future<void> deleteRoomImageUrls({
    required String roomId,
    required List<String> urls,
  }) async {
    final ownerId = _requireAuthenticatedUid();
    _validateRoomId(roomId);
    final expectedPrefix = 'room_images/$ownerId/$roomId/';
    final references = <Reference>[];
    for (final url in urls) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) continue;
      final reference = _storage.refFromURL(url);
      if (reference.fullPath.startsWith(expectedPrefix)) {
        references.add(reference);
      }
    }
    if (!await _deleteReferences(references)) {
      throw StateError(
        'The room was updated, but some old images could not be cleaned up.',
      );
    }
  }

  Future<bool> _deleteReferences(Iterable<Reference> references) async {
    var succeeded = true;
    for (final reference in references) {
      try {
        await reference.delete();
      } on FirebaseException {
        succeeded = false;
      }
    }
    return succeeded;
  }

  String _requireAuthenticatedUid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }

  void _validateRoomId(String roomId) {
    if (roomId.trim().isEmpty || roomId.contains('/')) {
      throw ArgumentError('A valid room ID is required.');
    }
  }
}

String roomImageFileName({
  required String originalName,
  required int batchId,
  required int index,
}) {
  final extension = _safeExtension(originalName);
  return '${batchId}_$index.$extension';
}

String roomImageContentType(String fileName) {
  return switch (_safeExtension(fileName)) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };
}

String _safeExtension(String fileName) {
  final separator = fileName.lastIndexOf('.');
  if (separator < 0 || separator == fileName.length - 1) return 'jpg';
  final extension = fileName.substring(separator + 1).toLowerCase();
  const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
  return allowed.contains(extension) ? extension : 'jpg';
}

String friendlyStorageError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'unauthenticated' => 'Please sign in again before uploading images.',
      'unauthorized' => 'You do not have permission to manage these images.',
      'canceled' => 'The image upload was cancelled.',
      'retry-limit-exceeded' =>
        'The upload timed out. Check your connection and try again.',
      'object-not-found' => 'One of the room images no longer exists.',
      _ => 'The room images could not be uploaded. Please try again.',
    };
  }
  if (error is ArgumentError || error is StateError) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Invalid argument|Bad state): '), '');
  }
  return 'The room images could not be uploaded. Please try again.';
}
