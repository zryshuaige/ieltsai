class PostProcessor {
  const PostProcessor();

  String clean(String raw) {
    var text = raw.trim();
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(
      RegExp(r"^sure[,:\s-]*here (is|'s).{0,30}:\s*", caseSensitive: false),
      '',
    );
    text = text.replaceAll(RegExp(r'^[“”"]+|[“”"]+$'), '');
    text = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = text.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length > 25) {
      return words.take(25).join(' ');
    }
    return words.join(' ');
  }
}
