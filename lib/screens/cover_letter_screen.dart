import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/job.dart';
import '../services/api_service.dart';

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
      setState(() => _error = 'Failed to generate cover letter — please try again.');
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Cover Letter'),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(icon: const Icon(Icons.copy), onPressed: _copy),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Claude is writing your cover letter...'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(_letter, style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
    );
  }
}