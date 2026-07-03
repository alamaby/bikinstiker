import 'dart:io';

import 'package:bikin_stiker/data/repositories/legal_consent_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legal consent version', () {
    test('current versions are updated to 2026-07-03', () {
      expect(LegalConsentRepository.currentTermsVersion, '2026-07-03');
      expect(LegalConsentRepository.currentPrivacyVersion, '2026-07-03');
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

    test('both documents have effective date 2026-07-03', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      final terms = File('docs/terms-of-service.md').readAsStringSync();

      expect(privacy, contains('Effective Date:** 2026-07-03'));
      expect(terms, contains('Effective Date:** 2026-07-03'));
    });

    test('privacy policy has filled privacy contact email', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      expect(privacy, contains('privacy@bikinstiker.example'));
      // Legacy bracket placeholder should be gone.
      expect(privacy, isNot(contains('[PRIVACY_CONTACT_EMAIL]')));
    });

    test('terms of service has filled support email', () {
      final terms = File('docs/terms-of-service.md').readAsStringSync();
      expect(terms, contains('support@bikinstiker.example'));
      expect(terms, isNot(contains('[SUPPORT_EMAIL]')));
    });

    test('terms of service declares Republic of Indonesia as governing law', () {
      final terms = File('docs/terms-of-service.md').readAsStringSync();
      expect(terms, contains('Republic of Indonesia'));
    });

    test('documents reference current AI providers (Pixazo, Mistral)', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      final terms = File('docs/terms-of-service.md').readAsStringSync();

      expect(privacy, contains('Pixazo'));
      expect(privacy, contains('Mistral'));
      expect(terms, contains('Pixazo'));
      expect(terms, contains('Mistral'));
    });

    test('documents describe guest migration token mechanism', () {
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      expect(privacy, contains('guest_migration_tokens'));
    });

    test('documents retain explicit placeholder for legal entity / address', () {
      // Per release plan, [TO_BE_FILLED_BY_LEGAL] is intentional and must be
      // resolved by legal counsel before publish. It appears at least once in
      // each document (entity + address sections).
      final privacy = File('docs/privacy-policy.md').readAsStringSync();
      final terms = File('docs/terms-of-service.md').readAsStringSync();

      expect(privacy, contains('[TO_BE_FILLED_BY_LEGAL]'));
      expect(terms, contains('[TO_BE_FILLED_BY_LEGAL]'));
    });
  });
}