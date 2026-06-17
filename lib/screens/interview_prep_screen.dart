import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  bool _isLoading = true;
  String? _error;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final content = await ApiService.interviewPrep(widget.cvData, widget.job.description);
      setState(() => _content = content);
    } catch (e) {
      setState(() => _error = 'Couldn\'t generate interview prep — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview prep'),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              tooltip: 'Copy',
              onPressed: _copy,
            ),
        ],
      ),
      body: _isLoading
          ? const _GeneratingState(message: 'JobHero is preparing your questions...')
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _generate)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.sand),
                    ),
                    child: SelectableText(
                      _content,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.6),
                    ),
                  ),
                ),
    );
  }
}

class _GeneratingState extends StatelessWidget {
  final String message;
  const _GeneratingState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.pine),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontFamily: 'Inter', color: AppColors.stone)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.emberLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.ember, size: 26),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}