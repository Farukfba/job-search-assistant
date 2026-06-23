import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CoverLetterScreen extends StatefulWidget {
  final Job job;
  final Map<String, dynamic> cvData;
  const CoverLetterScreen({super.key, required this.job, required this.cvData});
  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  bool _isLoading = true;
  String? _error;
  String _letter = '';

  @override
  void initState() { super.initState(); _generate(); }

  Future<void> _generate() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final letter = await ApiService.coverLetter(widget.cvData, widget.job.description);
      setState(() => _letter = letter);
    } catch (e) {
      setState(() => _error = 'Couldn\'t generate the cover letter — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _letter));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')));
  }

  /// Parse plain text into sections using "— SECTION" markers
  List<MapEntry<String?, String>> _parseSections(String text) {
    final sections = <MapEntry<String?, String>>[];
    final lines = text.split('\n');
    String? currentSection;
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      // Match "— SECTION NAME" or "- SECTION NAME"
      final sectionMatch = RegExp(r'^[—\-]\s+([A-Z][A-Z\s]+)$').firstMatch(trimmed);
      if (sectionMatch != null) {
        if (buffer.isNotEmpty) {
          sections.add(MapEntry(currentSection, buffer.toString().trim()));
          buffer.clear();
        }
        currentSection = sectionMatch.group(1);
      } else if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(trimmed);
      }
    }
    if (buffer.isNotEmpty) {
      sections.add(MapEntry(currentSection, buffer.toString().trim()));
    }
    return sections;
  }

  Color _avatarColor(String company) {
    final colors = [0xFF6366F1, 0xFF1C1C1C, 0xFF16A34A, 0xFFDC2626, 0xFFF59E0B];
    return Color(colors[company.hashCode % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final company = widget.job.company;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Cover Letter', style: TextStyle(fontFamily: sans,
            fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (!_isLoading && _error == null) ...[
            GestureDetector(
              onTap: _copy,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.copy_outlined, size: 18, color: AppColors.muted)),
            ),
            GestureDetector(
              onTap: _generate,
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.muted)),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _generate, child: const Text('Retry')),
                ]))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Company + score card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _avatarColor(company),
                                  borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(
                                  company.isNotEmpty ? company[0].toUpperCase() : '?',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                                      fontWeight: FontWeight.w700, color: Colors.white))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(company, style: TextStyle(fontFamily: sans, fontSize: 15,
                                    fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text('${widget.job.title} · Match 94',
                                    style: TextStyle(fontFamily: sans, fontSize: 13,
                                        color: AppColors.muted)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.green, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('94', style: TextStyle(fontFamily: sans,
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppColors.green)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          // Parsed letter sections
                          ..._parseSections(_letter).map((entry) {
                            final sectionName = entry.key;
                            final content = entry.value;

                            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (sectionName != null) ...[
                                const SizedBox(height: 16),
                                Row(children: [
                                  const Text('—', style: TextStyle(color: AppColors.green,
                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Text(sectionName, style: TextStyle(fontFamily: sans,
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: AppColors.green, letterSpacing: 0.8)),
                                ]),
                                const SizedBox(height: 8),
                              ] else
                                const SizedBox(height: 4),
                              SelectableText(content, style: TextStyle(fontFamily: sans,
                                  fontSize: 15, color: AppColors.ink, height: 1.6)),
                            ]);
                          }),
                        ]),
                      ),
                    ),

                    // Bottom actions
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(top: BorderSide(color: AppColors.divider)),
                      ),
                      child: Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          label: Text('Copy', style: TextStyle(fontFamily: sans,
                              fontSize: 15, fontWeight: FontWeight.w600)),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('Regenerate', style: TextStyle(fontFamily: sans,
                              fontSize: 15, fontWeight: FontWeight.w600)),
                        )),
                      ]),
                    ),
                  ],
                ),
    );
  }
}