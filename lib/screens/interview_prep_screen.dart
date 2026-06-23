import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InterviewPrepScreen extends StatefulWidget {
  final Job job;
  final Map<String, dynamic> cvData;
  const InterviewPrepScreen({super.key, required this.job, required this.cvData});
  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _QA {
  final int number;
  final String question;
  final String answer;
  bool expanded;
  _QA({required this.number, required this.question, required this.answer,
      this.expanded = false});
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  bool _isLoading = true;
  String? _error;
  List<_QA> _qas = [];
  String _raw = '';

  @override
  void initState() { super.initState(); _generate(); }

  Future<void> _generate() async {
    setState(() { _isLoading = true; _error = null; _qas = []; });
    try {
      final content = await ApiService.interviewPrep(widget.cvData, widget.job.description);
      setState(() { _raw = content; _qas = _parse(content); if (_qas.isNotEmpty) _qas[0].expanded = true; });
    } catch (e) {
      setState(() => _error = 'Couldn\'t generate interview prep — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_QA> _parse(String text) {
    final qas = <_QA>[];
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    String currentQ = '', currentA = '';
    int qNum = 0;
    bool inAnswer = false;

    for (final line in lines) {
      final qMatch = RegExp(r'^Q(\d+)[.:\s](.*)').firstMatch(line);
      final aMatch = RegExp(r'^(?:>?A|A)(\d+)[.:\s](.*)').firstMatch(line);
      if (qMatch != null) {
        if (currentQ.isNotEmpty) {
          qas.add(_QA(number: qNum, question: currentQ.trim(), answer: currentA.trim()));
        }
        qNum = int.tryParse(qMatch.group(1) ?? '0') ?? qas.length + 1;
        currentQ = qMatch.group(2) ?? '';
        currentA = ''; inAnswer = false;
      } else if (aMatch != null) {
        currentA = aMatch.group(2) ?? ''; inAnswer = true;
      } else if (inAnswer) {
        currentA += ' $line';
      } else if (currentQ.isNotEmpty) {
        currentQ += ' $line';
      }
    }
    if (currentQ.isNotEmpty) {
      qas.add(_QA(number: qNum, question: currentQ.trim(), answer: currentA.trim()));
    }
    return qas;
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final company = widget.job.company;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Interview Prep', style: TextStyle(fontFamily: sans,
            fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (!_isLoading && _error == null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _raw));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.copy_outlined, size: 18, color: AppColors.muted)),
            ),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$company · ${widget.job.title.split(' ').take(2).join(' ')}',
                            style: TextStyle(fontFamily: sans, fontSize: 18,
                                fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text('${_qas.length} questions generated from job description',
                              style: TextStyle(fontFamily: sans, fontSize: 13,
                                  color: AppColors.green, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: AppColors.green, width: 3)),
                            color: AppColors.greenLight,
                          ),
                          child: Text('Answers are tailored to your CV. Tap Q to expand, >A to reveal the model answer.',
                              style: TextStyle(fontFamily: sans, fontSize: 13,
                                  color: AppColors.muted, height: 1.4)),
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                    Expanded(
                      child: _qas.isEmpty
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: SelectableText(_raw, style: TextStyle(fontFamily: sans,
                                  fontSize: 14, color: AppColors.ink, height: 1.6)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _qas.length,
                              itemBuilder: (context, i) {
                                final qa = _qas[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(children: [
                                    // Question row
                                    GestureDetector(
                                      onTap: () => setState(() => qa.expanded = !qa.expanded),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Q${qa.number}',
                                                style: TextStyle(fontFamily: sans, fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.green)),
                                            const SizedBox(width: 16),
                                            Expanded(child: Text(qa.question,
                                                style: TextStyle(fontFamily: sans, fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.ink, height: 1.35))),
                                            const SizedBox(width: 10),
                                            Icon(qa.expanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                                size: 20, color: AppColors.muted),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Answer
                                    if (qa.expanded && qa.answer.isNotEmpty) ...[
                                      const Divider(color: AppColors.divider, height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('>A${qa.number}',
                                                style: TextStyle(fontFamily: sans, fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.muted)),
                                            const SizedBox(width: 16),
                                            Expanded(child: Text(qa.answer,
                                                style: TextStyle(fontFamily: sans, fontSize: 14,
                                                    color: AppColors.muted, height: 1.55))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ]),
                                );
                              },
                            ),
                    ),
                    // Regenerate button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      decoration: const BoxDecoration(color: AppColors.white),
                      child: OutlinedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text('Regenerate all questions',
                            style: TextStyle(fontFamily: sans, fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
    );
  }
}