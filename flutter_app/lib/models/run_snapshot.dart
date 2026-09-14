import 'dart:convert';

/// Versioned local checkpoint; validate before passing data into physics.
class RunSnapshot {
  final Map<String, dynamic> data;
  RunSnapshot(Map<String, dynamic> source)
      : data = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  String get id => data['id'] as String;
  int get score => data['score'] as int;

  static RunSnapshot? parse(dynamic value) {
    try {
      final s = RunSnapshot(Map<String, dynamic>.from(value as Map));
      if (s.data['version'] != 1 || s.id.isEmpty || s.score < 0) return null;
      double number(dynamic v) {
        final n = (v as num).toDouble();
        if (!n.isFinite) throw const FormatException();
        return n;
      }
      for (final key in ['current', 'next']) {
        final i = s.data[key] as int;
        if (i < 0 || i > 4) return null;
      }
      if (number(s.data['clock']) < 0 || number(s.data['cooldown']) < 0 ||
          number(s.data['cooldown']) > 320) return null;
      number(s.data['dropX']);
      final fruits = s.data['fruits'] as List;
      if (fruits.length > 1000) return null;
      for (final f in fruits) {
        final level = f['index'] as int;
        if (level < 0 || level > 9) return null;
        for (final key in ['x','y','vx','vy','angle','angular','age','over','flash']) {
          number(f[key]);
        }
        if (number(f['age']) < 0 || number(f['over']) < 0) return null;
      }
      return s;
    } catch (_) { return null; }
  }
}
