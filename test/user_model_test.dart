import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hiraya_aklatan/data/models/user_model.dart';

void main() {
  group('UserModel.fromMap', () {
    test('uses safe defaults when nullable string fields are missing', () {
      final user = UserModel.fromMap({
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      }, 'reader-1');

      expect(user.uid, 'reader-1');
      expect(user.name, 'Reader');
      expect(user.email, isEmpty);
      expect(user.role, 'reader');
      expect(user.isAdmin, isFalse);
    });

    test('preserves provided profile fields', () {
      final user = UserModel.fromMap({
        'name': 'Aklatan Reader',
        'email': 'reader@example.com',
        'role': 'admin',
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      }, 'admin-1');

      expect(user.name, 'Aklatan Reader');
      expect(user.email, 'reader@example.com');
      expect(user.isAdmin, isTrue);
    });
  });
}
