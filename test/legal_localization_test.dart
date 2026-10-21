import 'dart:convert';
import 'dart:io';

import 'package:cross_slow/features/menu/info_content.dart';
import 'package:cross_slow/features/menu/menu_screen.dart';
import 'package:cross_slow/game_language.dart';
import 'package:cross_slow/l10n/app_localizations.dart';
import 'package:cross_slow/l10n/app_localizations_en.dart';
import 'package:cross_slow/l10n/app_localizations_ru.dart';
import 'package:cross_slow/l10n/localized_content.dart';
import 'package:cross_slow/progress/campaign_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'КроссСлов',
      packageName: 'ru.bochk.crossslov',
      version: '1.1.2',
      buildNumber: '2',
      buildSignature: '',
    );
  });
  test('Russian legal sources are unchanged and translations preserve paragraph structure', () {
    final ru = AppLocalizationsRu();
    final en = AppLocalizationsEn();
    expect(ru.privacyBody, privacyDocument.sections.single.text);
    expect(ru.termsBody, termsDocument.sections.single.text);
    expect(en.privacyBody.trim().split('\n\n'), hasLength(4));
    expect(en.termsBody.trim().split('\n\n'), hasLength(7));
    expect(
      en.privacyBody,
      contains('Cloud synchronization of game data is not used.'),
    );
    expect(
      en.privacyBody,
      contains('does not transmit game progress to the developer'),
    );
    expect(en.privacyBody, contains('email or Telegram'));
    expect(
      en.termsBody,
      contains('have no monetary value and cannot be exchanged for money'),
    );
    expect(en.termsBody, contains('stored locally on the device'));
    expect(en.termsBody, contains('"as is"'));
    final raw = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(raw.containsKey('russianDocumentNotice'), isFalse);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: 1.1.2+2'),
    );
  });
  for (final ui in ['ru', 'en']) {
    for (final game in GameLanguage.values) {
      testWidgets(
        '$ui legal documents and Info version are independent of ${game.code} crosswords',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final l10n = ui == 'ru' ? AppLocalizationsRu() : AppLocalizationsEn();
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(ui),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MenuScreen(
                themeMode: ThemeMode.dark,
                onThemeChanged: (_) {},
                progress: CampaignProgress(),
                levels: const [],
                language: game,
                englishAvailable: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.infoTab));
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.text(l10n.appVersion('1.1.2')),
            150,
            scrollable: scrollable,
          );
          expect(find.text(l10n.appVersion('1.1.2')), findsOneWidget);
          for (final document in [privacyDocument, termsDocument]) {
            final localized = l10n.document(document);
            await tester.scrollUntilVisible(
              find.text(localized.title),
              -150,
              scrollable: scrollable,
            );
            await tester.tap(find.text(localized.title));
            await tester.pumpAndSettle();
            expect(find.text(localized.title), findsOneWidget);
            expect(find.text(localized.sections.single.text), findsOneWidget);
            expect(
              find.text('This document is available in Russian only.'),
              findsNothing,
            );
            await tester.tap(find.byType(BackButton).last);
            await tester.pumpAndSettle();
          }
        },
      );
    }
  }
}
