import 'dart:io';

import 'package:bikin_stiker/data/repositories/legal_consent_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legal consent version', () {
    test('current versions are updated to 2026-07-01', () {
      expect(LegalConsentRepository.currentTermsVersion, '2026-07-01');
      expect(LegalConsentRepository.currentPrivacyVersion, '2026-07-01');
    });

    test('terms and privacy versions match', () {
      expect(
        LegalConsentRepository.currentTermsVersion,
        LegalConsentRepository.currentPrivacyVersion,
      );
    });
  });

  group('Legal document files', () {
    test('privacy policy markdown exists and is non-empty', () {
      final file = File('docs/privacy-policy.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
    });

    test('terms of service markdown exists and is non-empty', () {
      final file = File('docs/terms-of-service.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
    });

    test('privacy policy contains GDPR references', () {
      final content = File('docs/privacy-policy.md').readAsStringSync();
      expect(content, contains('GDPR'));
      expect(content, contains('PDP'));
    });

    test('privacy policy contains Google Sign-In section', () {
      final content = File('docs/privacy-policy.md').readAsStringSync();
      expect(content, contains('Google Sign-In'));
      expect(content, contains('OAuth'));
    });

    test('terms contain AI-generated content disclaimer', () {
      final content = File('docs/terms-of-service.md').readAsStringSync();
      expect(content, contains('AI-Generated Content'));
      expect(content, contains('artificial intelligence'));
    });

    test('terms contain WhatsApp export section', () {
      final content = File('docs/terms-of-service.md').readAsStringSync();
      expect(content, contains('WhatsApp'));
      expect(content, contains('Sticker Pack'));
    });

    test('both documents are bilingual (contain English and Indonesian)', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      final terms = File('docs/terms-of-service.md').readAsStringSync();

      expect(privacy, contains('Bahasa Indonesia'));
      expect(terms, contains('Bahasa Indonesia'));
      expect(privacy, contains('English'));
      expect(terms, contains('English'));
    });

    test('both documents have placeholder fields', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      final terms = File('docs/terms-of-service.md').readAsStringSync();

      expect(privacy, contains('[LEGAL_ENTITY_NAME]'));
      expect(privacy, contains('[PRIVACY_CONTACT_EMAIL]'));
      expect(privacy, contains('[LEGAL_ADDRESS]'));
      expect(terms, contains('[SUPPORT_EMAIL]'));
      expect(terms, contains('[LEGAL_ADDRESS]'));
    });
  });
}
