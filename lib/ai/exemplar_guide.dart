import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ExemplarGuide {
  ExemplarGuide({
    this.assetPrefix = 'assets/exemplars/',
    this.maxFiles = 6,
    this.maxChars = 900,
  });

  final String assetPrefix;
  final int maxFiles;
  final int maxChars;

  String? _cached;
  Future<String>? _inflight;

  Future<String> getGuideText() {
    final cached = _cached;
    if (cached != null) {
      return Future.value(cached);
    }
    final inflight = _inflight;
    if (inflight != null) {
      return inflight;
    }
    final future = _loadAndSummarize();
    _inflight = future;
    return future;
  }

  Future<String> _loadAndSummarize() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestJson);
      if (manifest is! Map<String, dynamic>) {
        _cached = '';
        return _cached!;
      }

      final paths = manifest.keys
          .where((k) => k.startsWith(assetPrefix))
          .where((k) => !k.endsWith('/'))
          .where((k) => !k.toLowerCase().endsWith('readme.md'))
          .toList();
      paths.sort();

      if (paths.isEmpty) {
        _cached = '';
        return _cached!;
      }

      final selected = paths.take(maxFiles).toList(growable: false);
      final summaries = <String>[];
      for (final path in selected) {
        final content = await rootBundle.loadString(path);
        final summary = _summarizeOne(path: path, content: content);
        if (summary.isNotEmpty) {
          summaries.add(summary);
        }
      }

      var out = summaries.join('\n');
      out = out.trim();
      if (out.length > maxChars) {
        out = out.substring(0, maxChars).trimRight();
        out = '$out…';
      }
      _cached = out;
      return out;
    } catch (_) {
      _cached = '';
      return _cached!;
    } finally {
      _inflight = null;
    }
  }

  String _summarizeOne({required String path, required String content}) {
    final normalized = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      return '';
    }

    final paragraphHeads = <String>[];
    for (final p in paragraphs.take(5)) {
      final head = _firstSentence(p);
      paragraphHeads.add(_clip(head, 90));
    }

    final filename = path.split('/').last;
    final parts = <String>[];
    parts.add('[${filename}] paragraphs=${paragraphs.length}');
    for (var i = 0; i < paragraphHeads.length; i++) {
      parts.add('P${i + 1}: ${paragraphHeads[i]}');
    }
    return parts.join(' | ');
  }

  String _firstSentence(String paragraph) {
    final p = paragraph.replaceAll(RegExp(r'\s+'), ' ').trim();
    final match = RegExp(r'^(.+?[.!?])\s').firstMatch('$p ');
    if (match != null) {
      return (match.group(1) ?? p).trim();
    }
    // Fallback: first ~18 words.
    final words = p.split(' ').where((w) => w.isNotEmpty).toList();
    final take = words.length > 18 ? 18 : words.length;
    return words.take(take).join(' ');
  }

  String _clip(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) {
      return t;
    }
    return '${t.substring(0, maxLen).trimRight()}…';
  }
}
