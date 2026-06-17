import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final letter = await ApiService.coverLetter(widget.cvData, widget.job.description);
      setState(() => _letter = letter);
    } catch (e) {
      setState(() => _error = 'Couldn\'t generate a cover letter — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _letter));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cover letter'),
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
          ? const _GeneratingState(message: 'JobHero is writing your cover letter...')
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
                      _letter,
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