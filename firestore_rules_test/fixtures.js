import {
  Timestamp,
  doc,
  setDoc,
} from 'firebase/firestore';

export const now = Timestamp.fromDate(new Date('2026-08-17T08:00:00Z'));

export function userData(uid, role, options = {}) {
  return {
    uid,
    email: `${uid}@example.com`,
    fullName: `User ${uid}`,
    phoneNumber: '9800000000',
    role,
    verificationStatus: options.verificationStatus ?? 'notRequested',
    isActive: options.isActive ?? true,
    createdAt: now,
    updatedAt: now,
    ...options.overrides,
  };
}

export function roomData(ownerId, options = {}) {
  return {
    ownerId,
    title: 'Test Room',
    location: 'Kathmandu',
    monthlyRent: 10000,
    genderPreference: 'Any',
    description: 'A safe room near campus.',
    imageUrls: ['assets/images/room1.jpeg'],
    isAvailable: options.isAvailable ?? true,
    createdAt: now,
    updatedAt: now,
    ...options.overrides,
  };
}

export function savedRoomData(customerId, roomId, options = {}) {
  return {
    customerId,
    roomId,
    savedAt: now,
    ...options.overrides,
  };
}

export function inquiryData(customerId, ownerId, roomId, options = {}) {
  return {
    roomId,
    customerId,
    ownerId,
    type: options.type ?? 'inquiry',
    message: 'Is this room still available?',
    status: options.status ?? 'pending',
    scheduledVisitAt: options.scheduledVisitAt ?? null,
    hiddenByCustomer: options.hiddenByCustomer ?? false,
    createdAt: now,
    updatedAt: now,
    roomTitle: 'Test Room',
    roomLocation: 'Kathmandu',
    customerDisplayName: `User ${customerId}`,
    ...options.overrides,
  };
}

export function verificationRequestData(ownerId, status, options = {}) {
  return {
    ownerId,
    status,
    submittedAt: now,
    updatedAt: now,
    rejectionReason: status === 'rejected' ? 'More details required.' : null,
    ownerDisplayName: `User ${ownerId}`,
    ownerEmail: `${ownerId}@example.com`,
    ...options.overrides,
  };
}

export async function seed(db, path, data) {
  await setDoc(doc(db, path), data);
}
