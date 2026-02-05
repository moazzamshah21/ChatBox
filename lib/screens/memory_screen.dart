import 'package:flutter/material.dart';

import '../models/user_memory.dart';
import '../services/memory_service.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final MemoryService _memoryService = MemoryService();
  UserMemory _memory = const UserMemory();

  static const _brandy = Color(0xFFD4A574);
  static const _surfaceHigh = Color(0xFF2C2520);
  static const _surfaceTop = Color(0xFF231C18);
  static const _onSurface = Color(0xFFEDE6DF);
  static const _onSurfaceVariant = Color(0xFFC4B5A4);

  final _nameController = TextEditingController();
  final _goalsController = TextEditingController();
  final _preferencesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show form immediately so we never get stuck on the spinner if load hangs or throws
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final m = await _memoryService.load();
      if (!mounted) return;
      setState(() {
        _memory = m;
        _nameController.text = m.name ?? '';
        _goalsController.text = m.goals.join('\n');
        _preferencesController.text = m.preferences.join('\n');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memory = const UserMemory();
        _nameController.clear();
        _goalsController.clear();
        _preferencesController.clear();
      });
    }
  }

  Future<void> _save() async {
    final goals = _goalsController.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final preferences = _preferencesController.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final name = _nameController.text.trim();
    final updated = _memory.copyWith(
      name: name.isEmpty ? null : name,
      goals: goals,
      preferences: preferences,
    );
    await _memoryService.save(updated);
    if (!mounted) return;
    setState(() => _memory = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Memory saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceHigh,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1512),
      appBar: AppBar(
        title: const Text('Your memory', style: TextStyle(color: _onSurface)),
        backgroundColor: _surfaceTop,
        iconTheme: const IconThemeData(color: _brandy),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: _brandy, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'The AI will remember these so it feels personal.',
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      hintText: 'e.g. Alex',
                      labelStyle: TextStyle(color: _onSurfaceVariant),
                      hintStyle: TextStyle(color: Color(0xFF8B7B6A)),
                    ),
                    style: const TextStyle(color: _onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _goalsController,
                    decoration: const InputDecoration(
                      labelText: 'Goals (one per line or comma-separated)',
                      hintText: 'e.g. learning Flutter\nbuilding an app',
                      labelStyle: TextStyle(color: _onSurfaceVariant),
                      hintStyle: TextStyle(color: Color(0xFF8B7B6A)),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(color: _onSurface),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _preferencesController,
                    decoration: const InputDecoration(
                      labelText: 'Preferences',
                      hintText: 'e.g. likes short answers\nprefers code examples',
                      labelStyle: TextStyle(color: _onSurfaceVariant),
                      hintStyle: TextStyle(color: Color(0xFF8B7B6A)),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(color: _onSurface),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save memory'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _brandy,
                      foregroundColor: const Color(0xFF2C1810),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
