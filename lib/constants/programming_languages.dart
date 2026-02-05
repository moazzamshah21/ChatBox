/// Display name and value used for API/conversion.
class ProgrammingLanguage {
  const ProgrammingLanguage(this.displayName, this.value);
  final String displayName;
  final String value;
}

const List<ProgrammingLanguage> programmingLanguages = [
  ProgrammingLanguage('Dart', 'dart'),
  ProgrammingLanguage('Python', 'python'),
  ProgrammingLanguage('JavaScript', 'javascript'),
  ProgrammingLanguage('TypeScript', 'typescript'),
  ProgrammingLanguage('React JS', 'react'),
  ProgrammingLanguage('React Native', 'reactnative'),
  ProgrammingLanguage('Flutter', 'flutter'),
  ProgrammingLanguage('Java', 'java'),
  ProgrammingLanguage('Kotlin', 'kotlin'),
  ProgrammingLanguage('Swift', 'swift'),
  ProgrammingLanguage('C', 'c'),
  ProgrammingLanguage('C++', 'cpp'),
  ProgrammingLanguage('C#', 'csharp'),
  ProgrammingLanguage('Go', 'go'),
  ProgrammingLanguage('Rust', 'rust'),
  ProgrammingLanguage('Ruby', 'ruby'),
  ProgrammingLanguage('PHP', 'php'),
  ProgrammingLanguage('SQL', 'sql'),
  ProgrammingLanguage('HTML', 'html'),
  ProgrammingLanguage('CSS', 'css'),
  ProgrammingLanguage('Shell', 'shell'),
  ProgrammingLanguage('R', 'r'),
  ProgrammingLanguage('Scala', 'scala'),
  ProgrammingLanguage('Perl', 'perl'),
  ProgrammingLanguage('Lua', 'lua'),
  ProgrammingLanguage('Haskell', 'haskell'),
  ProgrammingLanguage('Unknown', 'plaintext'),
];

String normalizeLanguage(String? raw) {
  if (raw == null || raw.isEmpty) return 'plaintext';
  final lower = raw.toLowerCase();
  for (final l in programmingLanguages) {
    if (l.value == lower || l.displayName.toLowerCase() == lower) return l.value;
  }
  return raw;
}

String displayNameFor(String? value) {
  if (value == null || value.isEmpty) return 'Unknown';
  final lower = value.toLowerCase();
  for (final l in programmingLanguages) {
    if (l.value == lower) return l.displayName;
  }
  return value;
}
