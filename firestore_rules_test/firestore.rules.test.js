import { after, afterEach, before, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  where,
  writeBatch,
  Timestamp,
} from 'firebase/firestore';
import {
  inquiryData,
  roomData,
  savedRoomData,
  seed,
  userData,
  verificationRequestData,
} from './fixtures.js';

const projectId = 'demo-staynest-rules';
let env;

const ids = {
  customer: 'customer-a',
  otherCustomer: 'customer-b',
  inactiveCustomer: 'customer-inactive',
  owner: 'owner-a',
  otherOwner: 'owner-b',
  unverifiedOwner: 'owner-unverified',
  inactiveOwner: 'owner-inactive',
  admin: 'admin-a',
  inactiveAdmin: 'admin-inactive',
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

afterEach(async () => env.clearFirestore());
after(async () => env.cleanup());

function dbFor(uid) {
  return uid == null
    ? env.unauthenticatedContext().firestore()
    : env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
}

async function seedCore(options = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      seed(db, `users/${ids.customer}`, userData(ids.customer, 'customer')),
      seed(db, `users/${ids.otherCustomer}`, userData(ids.otherCustomer, 'customer')),
      seed(db, `users/${ids.inactiveCustomer}`, userData(ids.inactiveCustomer, 'customer', { isActive: false })),
      seed(db, `users/${ids.owner}`, userData(ids.owner, 'owner', { verificationStatus: 'approved' })),
      seed(db, `users/${ids.otherOwner}`, userData(ids.otherOwner, 'owner', { verificationStatus: 'approved' })),
      seed(db, `users/${ids.unverifiedOwner}`, userData(ids.unverifiedOwner, 'owner')),
      seed(db, `users/${ids.inactiveOwner}`, userData(ids.inactiveOwner, 'owner', { isActive: false, verificationStatus: 'approved' })),
      seed(db, `users/${ids.admin}`, userData(ids.admin, 'admin')),
      seed(db, `users/${ids.inactiveAdmin}`, userData(ids.inactiveAdmin, 'admin', { isActive: false })),
      seed(db, 'rooms/available-room', roomData(ids.owner)),
      seed(db, 'rooms/unavailable-room', roomData(ids.owner, { isAvailable: false })),
      seed(db, 'rooms/other-room', roomData(ids.otherOwner)),
      ...(options.extraSeeds ?? []).map(({ path, data }) => seed(db, path, data)),
    ]);
  });
}

test('users enforce self get, deny list, and deny unauthenticated get', async () => {
  await seedCore();
  await assertFails(getDoc(doc(dbFor(null), `users/${ids.customer}`)));
  await assertSucceeds(getDoc(doc(dbFor(ids.customer), `users/${ids.customer}`)));
  await assertFails(getDoc(doc(dbFor(ids.customer), `users/${ids.otherCustomer}`)));
  await assertFails(getDocs(collection(dbFor(ids.customer), 'users')));
  await assertFails(getDocs(collection(dbFor(ids.admin), 'users')));
});

test('users allow valid customer self-create but deny owner/admin creation', async () => {
  const customerDb = dbFor('new-customer');
  await assertSucceeds(setDoc(doc(customerDb, 'users/new-customer'), {
    ...userData('new-customer', 'customer'),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  for (const role of ['owner', 'admin']) {
    const uid = `new-${role}`;
    await assertFails(setDoc(doc(dbFor(uid), `users/${uid}`), {
      ...userData(uid, role),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
  }
});

test('users allow safe profile update and deny protected field changes', async () => {
  await seedCore();
  const ref = doc(dbFor(ids.customer), `users/${ids.customer}`);
  await assertSucceeds(updateDoc(ref, {
    fullName: 'Updated Customer',
    phoneNumber: '9811111111',
    updatedAt: serverTimestamp(),
  }));
  for (const mutation of [
    { role: 'admin' },
    { isActive: false },
    { uid: 'other' },
    { email: 'other@example.com' },
    { createdAt: serverTimestamp() },
    { verificationStatus: 'approved' },
  ]) {
    await assertFails(updateDoc(ref, { ...mutation, updatedAt: serverTimestamp() }));
  }
});

test('rooms enforce intended reads and queries', async () => {
  await seedCore({ extraSeeds: [{
    path: `savedRooms/${ids.customer}_unavailable-room`,
    data: savedRoomData(ids.customer, 'unavailable-room'),
  }] });
  await assertFails(getDoc(doc(dbFor(null), 'rooms/available-room')));
  await assertSucceeds(getDocs(query(collection(dbFor(ids.customer), 'rooms'), where('isAvailable', '==', true))));
  await assertFails(getDocs(collection(dbFor(ids.customer), 'rooms')));
  await assertFails(getDoc(doc(dbFor(ids.otherCustomer), 'rooms/unavailable-room')));
  await assertSucceeds(getDoc(doc(dbFor(ids.customer), 'rooms/unavailable-room')));
  await assertSucceeds(getDocs(query(collection(dbFor(ids.owner), 'rooms'), where('ownerId', '==', ids.owner))));
});

test('only verified active owner can create a valid room', async () => {
  await seedCore();
  const create = (uid, roomId) => setDoc(doc(dbFor(uid), `rooms/${roomId}`), {
    ...roomData(uid),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await assertSucceeds(create(ids.owner, 'new-room'));
  await assertFails(create(ids.unverifiedOwner, 'unverified-room'));
  await assertFails(create(ids.inactiveOwner, 'inactive-room'));
  await assertFails(create(ids.customer, 'customer-room'));
  await assertFails(create(ids.admin, 'admin-room'));
});

test('room mutations enforce ownership, verification, and immutable fields', async () => {
  await seedCore();
  await assertSucceeds(updateDoc(doc(dbFor(ids.owner), 'rooms/available-room'), {
    title: 'Updated Room', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.otherOwner), 'rooms/available-room'), {
    title: 'Stolen', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.customer), 'rooms/available-room'), {
    title: 'Customer edit', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.owner), 'rooms/available-room'), {
    ownerId: ids.otherOwner, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.owner), 'rooms/available-room'), {
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(doc(dbFor(ids.unverifiedOwner), 'rooms/available-room')));
  await assertFails(deleteDoc(doc(dbFor(ids.inactiveOwner), 'rooms/available-room')));
  await assertSucceeds(deleteDoc(doc(dbFor(ids.owner), 'rooms/available-room')));
});

test('availability-only updates preserve legacy room compatibility', async () => {
  await seedCore({ extraSeeds: [
    { path: 'rooms/empty-images', data: roomData(ids.owner, { overrides: { imageUrls: [] } }) },
    { path: 'rooms/asset-image', data: roomData(ids.owner, { overrides: { imageUrls: ['assets/images/legacy.jpeg'] } }) },
    { path: 'rooms/oversized-legacy', data: roomData(ids.owner, { overrides: { description: 'x'.repeat(5001), imageUrls: Array(11).fill('legacy') } }) },
  ] });
  for (const roomId of ['empty-images', 'asset-image', 'oversized-legacy']) {
    await assertSucceeds(updateDoc(doc(dbFor(ids.owner), `rooms/${roomId}`), {
      isAvailable: false,
      updatedAt: serverTimestamp(),
    }));
  }
});

test('availability-only updates cannot change protected or detail fields', async () => {
  await seedCore({ extraSeeds: [{
    path: 'rooms/oversized-legacy',
    data: roomData(ids.owner, { overrides: { description: 'x'.repeat(5001) } }),
  }] });
  const reference = doc(dbFor(ids.owner), 'rooms/oversized-legacy');
  await assertFails(updateDoc(reference, {
    isAvailable: false, title: 'Changed', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    isAvailable: false, ownerId: ids.otherOwner, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(reference, {
    isAvailable: false, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
});

test('room detail updates continue to enforce Phase 11 bounds', async () => {
  await seedCore();
  await assertFails(updateDoc(doc(dbFor(ids.owner), 'rooms/available-room'), {
    description: 'x'.repeat(5001), updatedAt: serverTimestamp(),
  }));
});

test('unverified/inactive owners and admins cannot mutate any room', async () => {
  await seedCore({ extraSeeds: [
    { path: 'rooms/unverified-owned', data: roomData(ids.unverifiedOwner) },
    { path: 'rooms/inactive-owned', data: roomData(ids.inactiveOwner) },
  ] });
  for (const [uid, roomId] of [
    [ids.unverifiedOwner, 'unverified-owned'],
    [ids.inactiveOwner, 'inactive-owned'],
    [ids.admin, 'available-room'],
  ]) {
    await assertFails(updateDoc(doc(dbFor(uid), `rooms/${roomId}`), {
      title: 'Forbidden', updatedAt: serverTimestamp(),
    }));
    await assertFails(deleteDoc(doc(dbFor(uid), `rooms/${roomId}`)));
  }
});

test('saved rooms enforce deterministic customer ownership and room availability', async () => {
  await seedCore();
  const customerDb = dbFor(ids.customer);
  await assertSucceeds(setDoc(doc(customerDb, `savedRooms/${ids.customer}_available-room`), {
    customerId: ids.customer, roomId: 'available-room', savedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(customerDb, 'savedRooms/wrong-id'), {
    customerId: ids.customer, roomId: 'available-room', savedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(customerDb, `savedRooms/${ids.customer}_other`), {
    customerId: ids.otherCustomer, roomId: 'available-room', savedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(customerDb, `savedRooms/${ids.customer}_unavailable-room`), {
    customerId: ids.customer, roomId: 'unavailable-room', savedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(customerDb, `savedRooms/${ids.customer}_missing`), {
    customerId: ids.customer, roomId: 'missing', savedAt: serverTimestamp(),
  }));
});

test('saved room queries and mutations are isolated', async () => {
  await seedCore({ extraSeeds: [{
    path: `savedRooms/${ids.customer}_available-room`,
    data: savedRoomData(ids.customer, 'available-room'),
  }] });
  await assertSucceeds(getDocs(query(collection(dbFor(ids.customer), 'savedRooms'), where('customerId', '==', ids.customer))));
  await assertFails(getDocs(query(collection(dbFor(ids.otherCustomer), 'savedRooms'), where('customerId', '==', ids.customer))));
  for (const uid of [ids.owner, ids.admin, ids.inactiveCustomer]) {
    await assertFails(getDoc(doc(dbFor(uid), `savedRooms/${ids.customer}_available-room`)));
  }
  await assertFails(updateDoc(doc(dbFor(ids.customer), `savedRooms/${ids.customer}_available-room`), { savedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(dbFor(ids.otherCustomer), `savedRooms/${ids.customer}_available-room`)));
  await assertSucceeds(deleteDoc(doc(dbFor(ids.customer), `savedRooms/${ids.customer}_available-room`)));
});

test('non-customers and inactive customers cannot create or delete saves', async () => {
  await seedCore({ extraSeeds: [{
    path: `savedRooms/${ids.customer}_available-room`,
    data: savedRoomData(ids.customer, 'available-room'),
  }] });
  for (const uid of [ids.owner, ids.admin, ids.inactiveCustomer]) {
    await assertFails(setDoc(doc(dbFor(uid), `savedRooms/${uid}_available-room`), {
      customerId: uid, roomId: 'available-room', savedAt: serverTimestamp(),
    }));
    await assertFails(deleteDoc(doc(dbFor(uid), `savedRooms/${ids.customer}_available-room`)));
  }
});

test('inquiries enforce valid creation identity and available room', async () => {
  await seedCore();
  const create = (id, overrides = {}) => setDoc(doc(dbFor(ids.customer), `inquiries/${id}`), {
    ...inquiryData(ids.customer, ids.owner, 'available-room'),
    ...overrides,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await assertSucceeds(create('valid'));
  await assertFails(create('spoof-customer', { customerId: ids.otherCustomer }));
  await assertFails(create('spoof-owner', { ownerId: ids.otherOwner }));
  await assertFails(create('missing-room', { roomId: 'missing' }));
  await assertFails(create('unavailable', { roomId: 'unavailable-room' }));
});

test('inquiry queries are isolated while assigned unverified owners may read', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/customer-inquiry', data: inquiryData(ids.customer, ids.owner, 'available-room') },
    { path: 'inquiries/unverified-inquiry', data: inquiryData(ids.customer, ids.unverifiedOwner, 'available-room') },
  ] });
  await assertSucceeds(getDocs(query(collection(dbFor(ids.customer), 'inquiries'), where('customerId', '==', ids.customer))));
  await assertFails(getDocs(query(collection(dbFor(ids.otherCustomer), 'inquiries'), where('customerId', '==', ids.customer))));
  await assertSucceeds(getDocs(query(collection(dbFor(ids.owner), 'inquiries'), where('ownerId', '==', ids.owner))));
  await assertFails(getDocs(query(collection(dbFor(ids.otherOwner), 'inquiries'), where('ownerId', '==', ids.owner))));
  await assertSucceeds(getDoc(doc(dbFor(ids.unverifiedOwner), 'inquiries/unverified-inquiry')));
});

async function transitionInquiry(uid, inquiryId, status) {
  await updateDoc(doc(dbFor(uid), `inquiries/${inquiryId}`), {
    status, updatedAt: serverTimestamp(),
  });
}

test('verified owner transitions follow the workflow', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/pending-a', data: inquiryData(ids.customer, ids.owner, 'available-room') },
    { path: 'inquiries/pending-b', data: inquiryData(ids.customer, ids.owner, 'available-room') },
    { path: 'inquiries/accepted', data: inquiryData(ids.customer, ids.owner, 'available-room', { status: 'accepted' }) },
    { path: 'inquiries/declined', data: inquiryData(ids.customer, ids.owner, 'available-room', { status: 'declined' }) },
  ] });
  await assertSucceeds(transitionInquiry(ids.owner, 'pending-a', 'accepted'));
  await assertSucceeds(transitionInquiry(ids.owner, 'pending-b', 'declined'));
  await assertSucceeds(transitionInquiry(ids.owner, 'accepted', 'completed'));
  await assertFails(transitionInquiry(ids.owner, 'declined', 'accepted'));
});

test('unverified/inactive owners cannot mutate and customer can only hide own inquiry', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/unverified', data: inquiryData(ids.customer, ids.unverifiedOwner, 'available-room') },
    { path: 'inquiries/inactive', data: inquiryData(ids.customer, ids.inactiveOwner, 'available-room') },
    { path: 'inquiries/customer', data: inquiryData(ids.customer, ids.owner, 'available-room') },
  ] });
  await assertFails(transitionInquiry(ids.unverifiedOwner, 'unverified', 'accepted'));
  await assertFails(transitionInquiry(ids.inactiveOwner, 'inactive', 'accepted'));
  await assertSucceeds(updateDoc(doc(dbFor(ids.customer), 'inquiries/customer'), {
    hiddenByCustomer: true, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.customer), 'inquiries/customer'), {
    status: 'accepted', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.customer), 'inquiries/customer'), {
    ownerId: ids.otherOwner, updatedAt: serverTimestamp(),
  }));
});

async function ownerSubmission(uid, ownerDisplayName = `User ${uid}`) {
  const db = dbFor(uid);
  await runTransaction(db, async (transaction) => {
    transaction.set(doc(db, `verificationRequests/${uid}`), {
      ownerId: uid,
      status: 'pending',
      submittedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      rejectionReason: null,
      ownerDisplayName,
      ownerEmail: `${uid}@example.com`,
    });
    transaction.update(doc(db, `users/${uid}`), {
      verificationStatus: 'pending', updatedAt: serverTimestamp(),
    });
  });
}

test('owner first verification submission and rejected resubmission are atomic', async () => {
  await seedCore({ extraSeeds: [
    { path: 'users/owner-new', data: userData('owner-new', 'owner') },
    { path: 'users/owner-rejected', data: userData('owner-rejected', 'owner', { verificationStatus: 'rejected' }) },
    { path: 'verificationRequests/owner-rejected', data: verificationRequestData('owner-rejected', 'rejected') },
  ] });
  await assertSucceeds(ownerSubmission('owner-new'));
  await assertSucceeds(ownerSubmission('owner-rejected'));
});

test('invalid owner verification submissions are denied', async () => {
  await seedCore({ extraSeeds: [
    { path: 'users/owner-pending', data: userData('owner-pending', 'owner', { verificationStatus: 'pending' }) },
    { path: 'verificationRequests/owner-pending', data: verificationRequestData('owner-pending', 'pending') },
    { path: 'users/owner-approved', data: userData('owner-approved', 'owner', { verificationStatus: 'approved' }) },
  ] });
  await assertFails(ownerSubmission('owner-pending'));
  await assertFails(ownerSubmission('owner-approved'));
  await assertFails(updateDoc(doc(dbFor('owner-pending'), 'verificationRequests/owner-pending'), {
    status: 'approved', rejectionReason: null, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor('owner-pending'), 'verificationRequests/owner-pending'), {
    status: 'rejected', rejectionReason: 'No', updatedAt: serverTimestamp(),
  }));
});

test('single-document owner verification submission writes are denied', async () => {
  await seedCore({ extraSeeds: [{ path: 'users/owner-new', data: userData('owner-new', 'owner') }] });
  await assertFails(setDoc(doc(dbFor('owner-new'), 'verificationRequests/owner-new'), {
    ...verificationRequestData('owner-new', 'pending'),
    submittedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor('owner-new'), 'users/owner-new'), {
    verificationStatus: 'pending', updatedAt: serverTimestamp(),
  }));
});

async function adminDecision(adminUid, ownerUid, status, reason = null, mutations = {}) {
  const db = dbFor(adminUid);
  const batch = writeBatch(db);
  batch.update(doc(db, `verificationRequests/${ownerUid}`), {
    status,
    rejectionReason: reason,
    updatedAt: serverTimestamp(),
    ...(mutations.request ?? {}),
  });
  batch.update(doc(db, `users/${ownerUid}`), {
    verificationStatus: status,
    updatedAt: serverTimestamp(),
    ...(mutations.user ?? {}),
  });
  await batch.commit();
}

async function seedPendingOwner(ownerUid = 'owner-pending') {
  await seedCore({ extraSeeds: [
    { path: `users/${ownerUid}`, data: userData(ownerUid, 'owner', { verificationStatus: 'pending' }) },
    { path: `verificationRequests/${ownerUid}`, data: verificationRequestData(ownerUid, 'pending') },
  ] });
}

test('active admin can atomically approve or reject pending owner', async () => {
  await seedPendingOwner('owner-approve');
  await assertSucceeds(adminDecision(ids.admin, 'owner-approve', 'approved'));
  await env.clearFirestore();
  await seedPendingOwner('owner-reject');
  await assertSucceeds(adminDecision(ids.admin, 'owner-reject', 'rejected', 'Insufficient details.'));
});

test('non-admin and inactive admin decisions are denied', async () => {
  for (const uid of [ids.inactiveAdmin, ids.owner, ids.customer]) {
    await seedPendingOwner();
    await assertFails(adminDecision(uid, 'owner-pending', 'approved'));
    await env.clearFirestore();
  }
});

test('single-document and mismatched admin decisions are denied', async () => {
  await seedPendingOwner();
  await assertFails(updateDoc(doc(dbFor(ids.admin), 'verificationRequests/owner-pending'), {
    status: 'approved', rejectionReason: null, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.admin), 'users/owner-pending'), {
    verificationStatus: 'approved', updatedAt: serverTimestamp(),
  }));
  await assertFails(adminDecision(ids.admin, 'owner-pending', 'approved', null, {
    user: { verificationStatus: 'rejected' },
  }));
});

test('admin cannot mutate verification identity or owner integrity fields', async () => {
  await seedPendingOwner();
  await assertFails(adminDecision(ids.admin, 'owner-pending', 'approved', null, {
    request: { ownerId: ids.otherOwner },
  }));
  for (const userMutation of [
    { uid: 'changed' }, { role: 'admin' }, { isActive: false },
  ]) {
    await assertFails(adminDecision(ids.admin, 'owner-pending', 'approved', null, {
      user: userMutation,
    }));
  }
});

test('admin cannot re-decide completed verification requests', async () => {
  for (const status of ['approved', 'rejected']) {
    await seedCore({ extraSeeds: [
      { path: 'users/owner-done', data: userData('owner-done', 'owner', { verificationStatus: status }) },
      { path: 'verificationRequests/owner-done', data: verificationRequestData('owner-done', status) },
    ] });
    await assertFails(adminDecision(ids.admin, 'owner-done', 'approved'));
    await env.clearFirestore();
  }
});

test('admin can query pending requests but cannot list users', async () => {
  await seedPendingOwner();
  const pending = await assertSucceeds(getDocs(query(
    collection(dbFor(ids.admin), 'verificationRequests'),
    where('status', '==', 'pending'),
  )));
  assert.equal(pending.size, 1);
  await assertFails(getDocs(collection(dbFor(ids.admin), 'users')));
});

test('corrupted stored UIDs make customer and owner roles fail closed', async () => {
  await seedCore({ extraSeeds: [
    { path: 'users/corrupt-customer', data: userData('corrupt-customer', 'customer', { overrides: { uid: 'wrong' } }) },
    { path: 'users/corrupt-owner', data: userData('corrupt-owner', 'owner', { verificationStatus: 'approved', overrides: { uid: 'wrong' } }) },
    { path: 'rooms/corrupt-owner-room', data: roomData('corrupt-owner') },
    { path: 'savedRooms/corrupt-customer_available-room', data: savedRoomData('corrupt-customer', 'available-room') },
  ] });
  await assertFails(getDocs(query(collection(dbFor('corrupt-customer'), 'savedRooms'), where('customerId', '==', 'corrupt-customer'))));
  await assertFails(updateDoc(doc(dbFor('corrupt-owner'), 'rooms/corrupt-owner-room'), {
    title: 'Changed', updatedAt: serverTimestamp(),
  }));
});

test('inquiry snapshot metadata must match authoritative room and customer data', async () => {
  await seedCore();
  const create = (id, overrides) => setDoc(doc(dbFor(ids.customer), `inquiries/${id}`), {
    ...inquiryData(ids.customer, ids.owner, 'available-room'),
    ...overrides,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await assertFails(create('spoof-title', { roomTitle: 'Fake room' }));
  await assertFails(create('spoof-location', { roomLocation: 'Fake location' }));
  await assertFails(create('spoof-name', { customerDisplayName: 'Another person' }));
});

test('accepted visit scheduling requires a future timestamp', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/visit-future', data: inquiryData(ids.customer, ids.owner, 'available-room', { type: 'visitRequest', status: 'accepted' }) },
    { path: 'inquiries/visit-past', data: inquiryData(ids.customer, ids.owner, 'available-room', { type: 'visitRequest', status: 'accepted' }) },
    { path: 'inquiries/normal-inquiry', data: inquiryData(ids.customer, ids.owner, 'available-room', { status: 'accepted' }) },
    { path: 'inquiries/pending-visit', data: inquiryData(ids.customer, ids.owner, 'available-room', { type: 'visitRequest' }) },
    { path: 'inquiries/declined-visit', data: inquiryData(ids.customer, ids.owner, 'available-room', { type: 'visitRequest', status: 'declined' }) },
    { path: 'inquiries/completed-visit', data: inquiryData(ids.customer, ids.owner, 'available-room', { type: 'visitRequest', status: 'completed' }) },
  ] });
  const futureVisit = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const pastVisit = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const schedule = (id, date) => updateDoc(doc(dbFor(ids.owner), `inquiries/${id}`), {
    scheduledVisitAt: Timestamp.fromDate(date),
    updatedAt: serverTimestamp(),
  });
  await assertSucceeds(schedule('visit-future', futureVisit));
  await assertFails(schedule('visit-past', pastVisit));
  await assertFails(schedule('normal-inquiry', futureVisit));
  await assertFails(schedule('pending-visit', futureVisit));
  await assertFails(schedule('declined-visit', futureVisit));
  await assertFails(schedule('completed-visit', futureVisit));
});

test('legacy inquiry metadata does not block safe owner status transitions', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/legacy-message', data: inquiryData(ids.customer, ids.owner, 'available-room', { overrides: { message: 'x'.repeat(2001) } }) },
    { path: 'inquiries/legacy-snapshots', data: inquiryData(ids.customer, ids.owner, 'available-room', { overrides: { roomTitle: 'x'.repeat(151), roomLocation: 'x'.repeat(201), customerDisplayName: 'x'.repeat(121) } }) },
  ] });
  await assertSucceeds(transitionInquiry(ids.owner, 'legacy-message', 'accepted'));
  await assertSucceeds(transitionInquiry(ids.owner, 'legacy-snapshots', 'accepted'));
});

test('owner inquiry transitions cannot alter immutable fields', async () => {
  await seedCore({ extraSeeds: [{
    path: 'inquiries/immutable',
    data: inquiryData(ids.customer, ids.owner, 'available-room'),
  }] });
  const reference = doc(dbFor(ids.owner), 'inquiries/immutable');
  for (const mutation of [
    { message: 'Changed message' },
    { roomTitle: 'Changed title' },
    { roomLocation: 'Changed location' },
    { customerDisplayName: 'Changed customer' },
    { customerId: ids.otherCustomer },
    { ownerId: ids.otherOwner },
    { roomId: 'other-room' },
  ]) {
    await assertFails(updateDoc(reference, {
      status: 'accepted',
      updatedAt: serverTimestamp(),
      ...mutation,
    }));
  }
});

test('inquiry no-op hide and status timestamp churn are denied', async () => {
  await seedCore({ extraSeeds: [
    { path: 'inquiries/already-hidden', data: inquiryData(ids.customer, ids.owner, 'available-room', { hiddenByCustomer: true }) },
    { path: 'inquiries/pending-noop', data: inquiryData(ids.customer, ids.owner, 'available-room') },
  ] });
  await assertFails(updateDoc(doc(dbFor(ids.customer), 'inquiries/already-hidden'), {
    hiddenByCustomer: true, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(dbFor(ids.owner), 'inquiries/pending-noop'), {
    status: 'pending', updatedAt: serverTimestamp(),
  }));
});

test('practical user, room, saved-room, and inquiry bounds reject oversized data', async () => {
  const newDb = dbFor('bounded-user');
  await assertFails(setDoc(doc(newDb, 'users/bounded-user'), {
    ...userData('bounded-user', 'customer', { overrides: { fullName: 'x'.repeat(121) } }),
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await seedCore();
  await assertFails(setDoc(doc(dbFor(ids.owner), 'rooms/too-many-images'), {
    ...roomData(ids.owner, { overrides: { imageUrls: Array(11).fill('legacy') } }),
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(dbFor(ids.customer), `savedRooms/${ids.customer}_${'x'.repeat(129)}`), {
    customerId: ids.customer, roomId: 'x'.repeat(129), savedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(dbFor(ids.customer), 'inquiries/oversized-message'), {
    ...inquiryData(ids.customer, ids.owner, 'available-room', { overrides: { message: 'x'.repeat(2001) } }),
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
});

test('admin reads only own or matching pending-owner profiles', async () => {
  await seedPendingOwner();
  await assertSucceeds(getDoc(doc(dbFor(ids.admin), `users/${ids.admin}`)));
  await assertSucceeds(getDoc(doc(dbFor(ids.admin), 'users/owner-pending')));
  await assertFails(getDoc(doc(dbFor(ids.admin), `users/${ids.customer}`)));
  await assertFails(getDoc(doc(dbFor(ids.admin), `users/${ids.owner}`)));
});

test('verification request queries are least privilege', async () => {
  await seedPendingOwner();
  await assertSucceeds(getDocs(query(
    collection(dbFor(ids.admin), 'verificationRequests'),
    where('status', '==', 'pending'),
  )));
  await assertFails(getDocs(collection(dbFor(ids.admin), 'verificationRequests')));
  await assertFails(getDocs(query(
    collection(dbFor(ids.owner), 'verificationRequests'),
    where('ownerId', '==', ids.owner),
  )));
  await assertFails(getDoc(doc(dbFor(ids.admin), 'verificationRequests/nonexistent')));
});

test('verification field bounds reject invalid owner metadata and rejection reasons', async () => {
  const oversizedName = 'x'.repeat(121);
  await seedCore({ extraSeeds: [{
    path: 'users/owner-new',
    data: userData('owner-new', 'owner', { overrides: { fullName: oversizedName } }),
  }] });
  const db = dbFor('owner-new');
  const invalidSubmission = writeBatch(db);
  invalidSubmission.set(doc(db, 'verificationRequests/owner-new'), {
    ...verificationRequestData('owner-new', 'pending', {
      overrides: { ownerDisplayName: oversizedName },
    }),
    submittedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  invalidSubmission.update(doc(db, 'users/owner-new'), {
    verificationStatus: 'pending', updatedAt: serverTimestamp(),
  });
  await assertFails(invalidSubmission.commit());

  await env.clearFirestore();
  const boundaryName = 'x'.repeat(120);
  await seedCore({ extraSeeds: [{
    path: 'users/owner-boundary',
    data: userData('owner-boundary', 'owner', { overrides: { fullName: boundaryName } }),
  }] });
  await assertSucceeds(ownerSubmission('owner-boundary', boundaryName));

  await env.clearFirestore();
  await seedPendingOwner();
  await assertFails(adminDecision(ids.admin, 'owner-pending', 'rejected', ''));
  await assertFails(adminDecision(ids.admin, 'owner-pending', 'rejected', 'x'.repeat(501)));
});
