class SearchTranslator {
  /// Simple mapping to match common Hindi sounds to English characters
  /// This allows "Ram" to match "राम" and vice-versa
  static final Map<String, String> _hindiToEnglish = {
    'अ': 'a', 'आ': 'a', 'इ': 'i', 'ई': 'i', 'उ': 'u', 'ऊ': 'u',
    'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au',
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh',
    'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n',
    'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm',
    'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v', 'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
    'ा': 'a', 'ि': 'i', 'ी': 'i', 'ु': 'u', 'ू': 'u', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au',
    'ं': 'n', '्': '',
  };

  /// Normalizes a string: removes spaces, lowercase, and if Hindi, maps to English sounds
  static String normalize(String input) {
    String normalized = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    // Check if contains Hindi characters
    if (RegExp(r'[\u0900-\u097F]').hasMatch(normalized)) {
      StringBuffer sb = StringBuffer();
      for (int i = 0; i < normalized.length; i++) {
        String char = normalized[i];
        sb.write(_hindiToEnglish[char] ?? char);
      }
      return sb.toString();
    }
    
    return normalized;
  }

  /// Checks if [query] matches [target] regardless of language (Hindi/English)
  static bool isMatch(String query, String target) {
    String normQuery = normalize(query);
    String normTarget = normalize(target);
    
    return normTarget.contains(normQuery) || normQuery.contains(normTarget);
  }
}
