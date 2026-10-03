import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_constants.dart';

/// Firestore service for database operations
/// Provides low-level access to Firestore collections
class FirestoreService {
  FirestoreService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Collection references
  CollectionReference get users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference get books =>
      _firestore.collection(AppConstants.booksCollection);

  CollectionReference bookRatings(String bookId) =>
      books.doc(bookId).collection('ratings');

  CollectionReference get chapterContents =>
      _firestore.collection(AppConstants.chapterContentsCollection);

  CollectionReference get unlockedChapters =>
      _firestore.collection(AppConstants.unlockedChaptersCollection);

  CollectionReference get payments =>
      _firestore.collection(AppConstants.paymentsCollection);

  CollectionReference get libraries =>
      _firestore.collection(AppConstants.librariesCollection);

  CollectionReference get settings =>
      _firestore.collection(AppConstants.settingsCollection);

  /// Gets chapters subcollection for a book
  CollectionReference chapters(String bookId) {
    return books.doc(bookId).collection(AppConstants.chaptersCollection);
  }

  /// Gets library books subcollection for a user
  CollectionReference libraryBooks(String userId) {
    return libraries.doc(userId).collection(AppConstants.booksCollection);
  }

  /// Gets app settings document
  DocumentReference get appSettings =>
      settings.doc(AppConstants.appSettingsDoc);

  /// Creates a new document with auto-generated ID
  DocumentReference createDoc(CollectionReference collection) {
    return collection.doc();
  }

  /// Executes a batch write operation
  Future<void> executeBatch(
    Future<void> Function(WriteBatch batch) operation,
  ) async {
    final batch = _firestore.batch();
    await operation(batch);
    await batch.commit();
  }

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) operation,
  ) {
    return _firestore.runTransaction(operation);
  }

  /// Checks if a document exists
  Future<bool> docExists(DocumentReference doc) async {
    final snapshot = await doc.get();
    return snapshot.exists;
  }

  /// Gets server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Gets current timestamp
  Timestamp get now => Timestamp.now();
}
