import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/programming_languages.dart';
import '../services/openai_service.dart';

class CodeBlockView extends StatefulWidget {
  const CodeBlockView({
    super.key,
    required this.code,
    this.language,
    required this.openAIService,
  });

  final String code;
  final String? language;
  final OpenAIService openAIService;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  late String _code;
  late String _languageValue;
  bool _isConverting = false;
  String? _error;

  static const _brandy = Color(0xFFD4A574);
  static const _surfaceBar = Color(0xFF2C2520);
  static const _onSurface = Color(0xFFEDE6DF);
  static const _onSurfaceVariant = Color(0xFFC4B5A4);

  @override
  void initState() {
    super.initState();
    _code = widget.code;
    _languageValue = normalizeLanguage(widget.language);
  }

  @override
  void didUpdateWidget(CodeBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.language != widget.language) {
      _code = widget.code;
      _languageValue = normalizeLanguage(widget.language);
      _error = null;
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A3728),
        ),
      );
    }
  }

  Future<void> _share() async {
    await Share.share(
      _code,
      subject: 'Code (${displayNameFor(_languageValue)})',
    );
  }

  void _showLanguagePicker() {
    if (_isConverting) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Convert to language',
                  style: TextStyle(
                    color: _onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: programmingLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = programmingLanguages[index];
                    final isSelected = lang.value == _languageValue;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.code_rounded,
                        color: isSelected ? _brandy : _onSurfaceVariant,
                        size: 22,
                      ),
                      title: Text(
                        lang.displayName,
                        style: TextStyle(
                          color: isSelected ? _brandy : _onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (lang.value != _languageValue) {
                          _convertToLanguage(lang.value, lang.displayName);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _convertToLanguage(String toValue, String toDisplayName) async {
    setState(() {
      _isConverting = true;
      _error = null;
    });

    try {
      final converted = await widget.openAIService.convertCodeToLanguage(
        _code,
        displayNameFor(_languageValue),
        toDisplayName,
      );
      if (!mounted) return;
      setState(() {
        _code = converted;
        _languageValue = toValue;
        _isConverting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1512),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D342C), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: _surfaceBar,
            child: Row(
              children: [
                InkWell(
                  onTap: _isConverting ? null : _showLanguagePicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayNameFor(_languageValue),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _brandy,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (!_isConverting) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: _brandy,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_isConverting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _brandy,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _copyToClipboard(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          foregroundColor: _onSurfaceVariant,
                        ),
                        tooltip: 'Copy',
                      ),
                      IconButton(
                        onPressed: _share,
                        icon: const Icon(Icons.share_rounded, size: 18),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          foregroundColor: _onSurfaceVariant,
                        ),
                        tooltip: 'Share',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE07D6A), fontSize: 12),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(14, _error != null ? 8 : 14, 14, 14),
            child: SelectableText(
              _code,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: _onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
