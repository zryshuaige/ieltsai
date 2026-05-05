import 'dart:convert';

class PostProcessor {
  const PostProcessor();

  static const String _paragraphSentinel = '\u0000';
  static const String _noAutoLeadingSpaceSentinel = '\u0001';

  String clean(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final jsonInsertion = _tryParseJsonInsertion(text);
    if (jsonInsertion != null) {
      return jsonInsertion;
    }

    final looseInsertion = _tryParseLooseJsonInsertion(text);
    if (looseInsertion != null) {
      return looseInsertion;
    }

    final jsonPreview = _tryExtractJsonPreview(text);
    if (jsonPreview != null) {
      return jsonPreview;
    }

    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(
      RegExp(r"^sure[,:\s-]*here (is|'s).{0,30}:\s*", caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'^[“”"]+|[“”"]+$'), '');

    // Normalize paragraph breaks and preserve at most one "\n\n".
    text = text.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    final breaks = RegExp(r'\n\n').allMatches(text).toList(growable: false);
    if (breaks.length > 1) {
      // Keep the first paragraph break; flatten the rest.
      var kept = false;
      text = text.replaceAllMapped(RegExp(r'\n\n'), (match) {
        if (!kept) {
          kept = true;
          return '\n\n';
        }
        return ' ';
      });
    }

    text = text.trim();

    // Preserve "\n\n" while flattening single newlines.
    text = text.replaceAll('\n\n', _paragraphSentinel);
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceAll(_paragraphSentinel, '\n\n');

    // Enforce word limit while keeping the paragraph break token.
    final tokens = text
        .replaceAll('\n\n', ' $_paragraphSentinel ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final out = <String>[];
    var wordCount = 0;
    for (final token in tokens) {
      if (token == _paragraphSentinel) {
        if (out.isNotEmpty && out.last != _paragraphSentinel) {
          out.add(_paragraphSentinel);
        }
        continue;
      }
      if (wordCount >= 25) {
        break;
      }
      out.add(token);
      wordCount += 1;
    }

    var result = out.join(' ');
    result = result.replaceAll(' $_paragraphSentinel ', '\n\n');
    result = result.replaceAll(_paragraphSentinel, '\n\n');
    result = result.replaceAll(RegExp(r' *\n\n *'), '\n\n').trim();
    return result;
  }

  String? _tryParseJsonInsertion(String raw) {
    final candidate = _extractJsonCandidate(raw);
    if (candidate == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is! Map) {
        return null;
      }
      final textValue = decoded['text'];
      if (textValue == null) {
        return null;
      }
      final leadingSpace = decoded['leadingSpace'] == true;
      final paragraphBreak = decoded['paragraphBreak'] == true;
      return _buildJsonInsertion(
        textValue.toString(),
        leadingSpace: leadingSpace,
        paragraphBreak: paragraphBreak,
      );
    } catch (_) {
      return null;
    }
  }

  String? _tryParseLooseJsonInsertion(String raw) {
    if (!raw.contains('{') || !raw.contains('}')) {
      return null;
    }
    final textResult = _extractJsonString(raw, 'text');
    if (textResult == null || !textResult.closed) {
      return null;
    }
    final leadingSpace = _extractJsonBool(raw, 'leadingSpace');
    final paragraphBreak = _extractJsonBool(raw, 'paragraphBreak');
    if (leadingSpace == null && paragraphBreak == null) {
      return null;
    }
    if (leadingSpace == null && paragraphBreak == false) {
      return null;
    }
    return _buildJsonInsertion(
      textResult.value,
      leadingSpace: leadingSpace ?? false,
      paragraphBreak: paragraphBreak ?? false,
    );
  }

  String? _tryExtractJsonPreview(String raw) {
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('{') && !raw.contains('"text"')) {
      return null;
    }
    final textResult = _extractJsonString(raw, 'text');
    if (textResult == null) {
      return '';
    }
    final normalized = _normalizeJsonText(textResult.value);
    if (normalized.isEmpty) {
      return '';
    }

    final leadingSpace = _extractJsonBool(raw, 'leadingSpace');
    final paragraphBreak = _extractJsonBool(raw, 'paragraphBreak');
    final previewOnly = leadingSpace == null && paragraphBreak == null;

    return _buildJsonInsertion(
      normalized,
      leadingSpace: leadingSpace ?? false,
      paragraphBreak: paragraphBreak ?? false,
      previewOnly: previewOnly,
    );
  }

  String _buildJsonInsertion(
    String rawText, {
    required bool leadingSpace,
    required bool paragraphBreak,
    bool previewOnly = false,
  }) {
    var text = _normalizeJsonText(rawText);
    if (text.isEmpty) {
      return '';
    }

    text = _truncateWords(text, 25);

    final buffer = StringBuffer();
    if (paragraphBreak) {
      buffer.write('\n\n');
      buffer.write(text);
      return buffer.toString();
    }

    if (leadingSpace) {
      buffer.write(' ');
      buffer.write(text);
      return buffer.toString();
    }

    if (!previewOnly) {
      buffer.write(_noAutoLeadingSpaceSentinel);
    }
    buffer.write(text);
    return buffer.toString();
  }

  String _normalizeJsonText(String text) {
    var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Contract: "text" should be single-line; enforce it.
    normalized = normalized.replaceAll('\n', ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  String _truncateWords(String text, int maxWords) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length <= maxWords) {
      return text;
    }
    return words.take(maxWords).join(' ');
  }

  _JsonStringResult? _extractJsonString(String raw, String key) {
    final pattern = RegExp('"${RegExp.escape(key)}"\\s*:' );
    final match = pattern.firstMatch(raw);
    if (match == null) {
      return null;
    }
    var index = match.end;
    while (index < raw.length && _isJsonWhitespace(raw[index])) {
      index += 1;
    }
    if (index >= raw.length || raw[index] != '"') {
      return const _JsonStringResult('', false);
    }
    index += 1;
    final buffer = StringBuffer();
    var escaped = false;
    while (index < raw.length) {
      final char = raw[index];
      if (escaped) {
        buffer.write(_unescapeJsonChar(raw, index));
        escaped = false;
        if (raw[index] == 'u') {
          index += 5;
          continue;
        }
        index += 1;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        index += 1;
        continue;
      }
      if (char == '"') {
        return _JsonStringResult(buffer.toString(), true);
      }
      buffer.write(char);
      index += 1;
    }
    return _JsonStringResult(buffer.toString(), false);
  }

  String _unescapeJsonChar(String raw, int index) {
    if (index >= raw.length) {
      return '';
    }
    final char = raw[index];
    switch (char) {
      case '"':
        return '"';
      case '\\':
        return '\\';
      case '/':
        return '/';
      case 'b':
        return '\b';
      case 'f':
        return '\f';
      case 'n':
        return '\n';
      case 'r':
        return '\r';
      case 't':
        return '\t';
      case 'u':
        if (index + 4 < raw.length) {
          final hex = raw.substring(index + 1, index + 5);
          final value = int.tryParse(hex, radix: 16);
          if (value != null) {
            return String.fromCharCode(value);
          }
        }
        return 'u';
      default:
        return char;
    }
  }

  bool? _extractJsonBool(String raw, String key) {
    final pattern = RegExp('"${RegExp.escape(key)}"\\s*:\\s*(true|false)');
    final match = pattern.firstMatch(raw);
    if (match == null) {
      return null;
    }
    return match.group(1) == 'true';
  }

  bool _isJsonWhitespace(String char) {
    return char == ' ' || char == '\n' || char == '\t' || char == '\r';
  }

  String? _extractJsonCandidate(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // If model wrapped JSON in code fences, extract the first fenced block.
    if (trimmed.startsWith('```')) {
      final fenceStart = trimmed.indexOf('\n');
      final fenceEnd = trimmed.lastIndexOf('```');
      if (fenceStart > 0 && fenceEnd > fenceStart) {
        final inside = trimmed.substring(fenceStart + 1, fenceEnd).trim();
        if (inside.startsWith('{') && inside.endsWith('}')) {
          return inside;
        }
      }
    }

    // Otherwise, take the first JSON-looking object.
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final candidate = trimmed.substring(start, end + 1).trim();
      if (candidate.startsWith('{') && candidate.endsWith('}')) {
        return candidate;
      }
    }
    return null;
  }
}

class _JsonStringResult {
  const _JsonStringResult(this.value, this.closed);

  final String value;
  final bool closed;
}
