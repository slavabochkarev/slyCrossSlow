import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level.dart';

class LevelRepository {
  Future<List<Level>> load() async {
    final source = await rootBundle.loadString('assets/levels.json');
    return (jsonDecode(source) as List)
        .map((item) => Level.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
