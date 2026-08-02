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
    test('privacy policy English markdown exists and is non-empty', () {
      final file = File('docs/privacy-policy-en.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
      expect(content, contains('GDPR'));
      expect(content, contains('PDP'));
      expect(content, contains('Google Sign-In'));
      expect(content, contains('OAuth'));
      expect(content, contains('Pixazo'));
      expect(content, contains('Mistral'));
      expect(content, contains('guest_migration_tokens'));
      expect(content, contains('[TO_BE_FILLED_BY_LEGAL]'));
      expect(content, contains('Effective Date:** 2026-07-03'));
      expect(content, contains('privacy@bikinstiker.example'));
    });

    test('privacy policy Indonesian markdown exists and is non-empty', () {
      final file = File('docs/privacy-policy-id.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
      expect(content, contains('Ringkasan'));
      expect(content, contains('Keamanan'));
      expect(content, contains('[TO_BE_FILLED_BY_LEGAL]'));
    });

    test('terms of service English markdown exists and is non-empty', () {
      final file = File('docs/terms-of-service-en.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
      expect(content, contains('AI-Generated Content'));
      expect(content, contains('artificial intelligence'));
      expect(content, contains('WhatsApp'));
      expect(content, contains('Sticker Pack'));
      expect(content, contains('Pixazo'));
      expect(content, contains('Mistral'));
      expect(content, contains('[TO_BE_FILLED_BY_LEGAL]'));
      expect(content, contains('Effective Date:** 2026-07-03'));
      expect(content, contains('support@bikinstiker.example'));
      expect(content, contains('Republic of Indonesia'));
    });

    test('terms of service Indonesian markdown exists and is non-empty', () {
      final file = File('docs/terms-of-service-id.md');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(500));
      expect(content, contains('Ketentuan Layanan'));
      expect(content, contains('Jaminan'));
      expect(content, contains('[TO_BE_FILLED_BY_LEGAL]'));
    });
  });
}
