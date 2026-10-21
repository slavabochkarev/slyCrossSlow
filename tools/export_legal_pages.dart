import 'dart:convert';
import 'dart:io';

import 'package:cross_slow/features/menu/info_content.dart';

const _escape = HtmlEscape();
const _style = '''
body { margin:0; background:#0a1019; color:#eaf5f5; font:17px/1.65 system-ui,sans-serif; }
main { max-width:800px; margin:auto; padding:40px 22px; }
h1 { line-height:1.2; }
a { color:#85f5be; overflow-wrap:anywhere; }
nav { display:flex; flex-wrap:wrap; gap:12px 24px; margin:0 0 32px; }
footer { margin-top:40px; border-top:1px solid #2e4a51; padding-top:20px; }
''';

String _page(
  String title,
  String description,
  String body, {
  String language = 'ru',
  String? russianPath,
}) =>
    '''<!doctype html>
<html lang="$language">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="${_escape.convert(description)}">
<title>КроссСлов — ${_escape.convert(title)}</title>
<style>$_style</style>
</head>
<body><main>
<nav><a href="/crossslov/">КроссСлов</a>${language == 'en' ? '<a href="/crossslov/en/privacy/">Privacy Policy</a><a href="/crossslov/en/eula/">EULA</a><a href="$russianPath">Русский</a>' : '<a href="/crossslov/privacy/">Политика конфиденциальности</a><a href="/crossslov/eula/">Пользовательское соглашение</a>'}</nav>
<h1>КроссСлов<br>${_escape.convert(title)}</h1>
$body
<footer><p>${language == 'en' ? 'Developer' : 'Разработчик'}: ${_escape.convert(developerName)}</p>
<p>Email: <a href="mailto:${_escape.convert(developerEmail)}">${_escape.convert(developerEmail)}</a><br>
Telegram: <a href="https://t.me/${_escape.convert(developerTelegram.substring(1))}">${_escape.convert(developerTelegram)}</a></p></footer>
</main></body></html>
''';

String _document(
  InfoDocument document, {
  String language = 'ru',
  String? russianPath,
}) {
  final paragraphs = document.sections
      .expand((section) => section.text.split(RegExp(r'\n\s*\n')))
      .map((text) => text.trim())
      .where((text) => text.isNotEmpty)
      .map((text) => '<p>${_escape.convert(text)}</p>')
      .join('\n');
  return _page(
    document.title,
    language == 'en'
        ? '${document.title} for КроссСлов'
        : '${document.title} игры КроссСлов',
    paragraphs,
    language: language,
    russianPath: russianPath,
  );
}

void main() {
  const root = 'release/legal/crossslov';
  final english = jsonDecode(
    File('lib/l10n/app_en.arb').readAsStringSync(encoding: utf8),
  ) as Map<String, dynamic>;
  final pages = <String, String>{
    '$root/index.html': _page(
      'Документы',
      'Документы игры КроссСлов',
      '<p>Документы игры «КроссСлов»:</p>\n'
          '<p><a href="/crossslov/privacy/">Политика конфиденциальности</a></p>\n'
          '<p><a href="/crossslov/eula/">Пользовательское соглашение</a></p>',
    ),
    '$root/privacy/index.html': _document(privacyDocument),
    '$root/eula/index.html': _document(termsDocument),
    for (final entry in {'privacy': 'privacy', 'eula': 'terms'}.entries)
      '$root/en/${entry.key}/index.html': _document(
        InfoDocument(english['${entry.value}Title'] as String, [
          InfoSection('', english['${entry.value}Body'] as String),
        ], plainText: true),
        language: 'en',
        russianPath: '/crossslov/${entry.key}/',
      ),
  };
  for (final entry in pages.entries) {
    final output = File(entry.key);
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(entry.value, encoding: utf8);
    stdout.writeln('Saved ${output.path}');
  }
}
