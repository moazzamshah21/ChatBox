import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_memory.dart';

class MemoryService {
  static const _key = 'user_memory';

  Future<UserMemory> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return UserMemory.fromJsonString(raw);
  }

  Future<void> save(UserMemory memory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, memory.toJsonString());
  }
}
