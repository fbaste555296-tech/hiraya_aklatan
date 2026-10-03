import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hiraya_aklatan/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects null and empty values', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('rejects invalid formats', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
      expect(Validators.email('spaces in@email.com'), isNotNull);
    });

    test('accepts valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last@domain.co.ph'), isNull);
      expect(Validators.email('user+tag@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects null and empty values', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('abc'), isNotNull);
    });

    test('accepts passwords of 6 characters or more', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('long-password'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects null and empty values', () {
      expect(Validators.confirmPassword(null, 'pass'), isNotNull);
      expect(Validators.confirmPassword('', 'pass'), isNotNull);
    });

    test('rejects mismatched passwords', () {
      expect(Validators.confirmPassword('different', 'password'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('password', 'password'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects null and empty values', () {
      expect(Validators.name(null), 'Name is required');
      expect(Validators.name(''), 'Name is required');
    });

    test('rejects single-character names', () {
      expect(Validators.name('A'), isNotNull);
    });

    test('rejects names with numbers or symbols', () {
      expect(Validators.name('John123'), isNotNull);
      expect(Validators.name('John_Doe'), isNotNull);
    });

    test('accepts valid names', () {
      expect(Validators.name('Maria Clara'), isNull);
      expect(Validators.name('Jose'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects null and empty values', () {
      expect(Validators.required(null), 'This field is required');
      expect(Validators.required(''), 'This field is required');
      expect(Validators.required('  '), 'This field is required');
    });

    test('uses custom field name in message', () {
      expect(
        Validators.required('', fieldName: 'Title'),
        'Title is required',
      );
    });

    test('accepts non-empty values', () {
      expect(Validators.required('value'), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('rejects null and empty values', () {
      expect(Validators.positiveNumber(null), 'Value is required');
      expect(Validators.positiveNumber(''), 'Value is required');
    });

    test('rejects non-numeric values', () {
      expect(Validators.positiveNumber('abc'), isNotNull);
    });

    test('rejects zero and negative values', () {
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-5'), isNotNull);
    });

    test('accepts positive numbers', () {
      expect(Validators.positiveNumber('10'), isNull);
      expect(Validators.positiveNumber('99.99'), isNull);
    });
  });

  group('Validators.referenceNumber', () {
    test('rejects null and empty values', () {
      expect(Validators.referenceNumber(null), 'Reference number is required');
      expect(Validators.referenceNumber(''), 'Reference number is required');
    });

    test('rejects values shorter than 5 characters', () {
      expect(Validators.referenceNumber('1234'), isNotNull);
    });

    test('accepts valid reference numbers', () {
      expect(Validators.referenceNumber('12345'), isNull);
      expect(Validators.referenceNumber('ABC1234567'), isNull);
    });
  });

  group('Validators.chapterNumber', () {
    test('rejects null and empty values', () {
      expect(Validators.chapterNumber(null), 'Chapter number is required');
      expect(Validators.chapterNumber(''), 'Chapter number is required');
    });

    test('rejects non-numeric and sub-1 values', () {
      expect(Validators.chapterNumber('abc'), isNotNull);
      expect(Validators.chapterNumber('0'), isNotNull);
      expect(Validators.chapterNumber('-1'), isNotNull);
    });

    test('accepts valid chapter numbers', () {
      expect(Validators.chapterNumber('1'), isNull);
      expect(Validators.chapterNumber('42'), isNull);
    });
  });

  group('Validators.textLength', () {
    test('rejects null and empty values', () {
      expect(
        Validators.textLength(null, min: 1, max: 10),
        'Text is required',
      );
    });

    test('rejects values below minimum', () {
      expect(
        Validators.textLength('ab', min: 3, max: 10),
        'Text must be at least 3 characters',
      );
    });

    test('rejects values above maximum', () {
      expect(
        Validators.textLength('abcdefghijk', min: 1, max: 10),
        'Text must not exceed 10 characters',
      );
    });

    test('accepts values within range', () {
      expect(Validators.textLength('hello', min: 1, max: 10), isNull);
    });
  });
}
