import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'main_shell.dart';

class CvUploadScreen extends StatefulWidget {
  const CvUploadScreen({super.key});

  @override
  State<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends State<CvUploadScreen> {
  bool _isLoading = false;
  bool _isCheckingProfile = true;
  String? _error;
  Map<String, dynamic>? _extractedData;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  // If the user already has a profile, skip straight to the main app shell
  Future<void> _checkExistingProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } catch (_) {
      // No profile yet — show upload screen
    } finally {
      if (mounted) setState(() => _isCheckingProfile = false);
    }
  }

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = result.files.single;
      final parsed = await ApiService.parseCv(file.bytes!, file.name);
      print('Full parsed response: $parsed');
      setState(() => _extractedData = parsed);
    } catch (e) {
      print('CV parse error: $e');
      setState(() => _error = 'Failed to parse CV: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndContinue() async {
    if (_extractedData == null) return;
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').upsert({
        'user_id': userId,
        'extracted_skills': _extractedData!['skills'],
        'extracted_experience': _extractedData!['experience'],
        'raw_cv_text': _extractedData!['raw_text'],
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } catch (e) {
      setState(() => _error = 'Failed to save profile — please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Your CV')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.upload_file, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Let Claude read your CV',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a PDF and Claude will extract your skills and experience.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_extractedData != null) ...[
                const Text('Extracted skills:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (_extractedData!['skills'] as List<dynamic>? ?? [])
                      .map((s) => Chip(label: Text(s.toString())))
                      .toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save & Continue'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _isLoading ? null : _pickAndUpload,
                  child: const Text('Re-upload'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickAndUpload,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_isLoading ? 'Claude is reading your CV...' : 'Select PDF'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}