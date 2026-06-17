import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class CvUploadScreen extends StatefulWidget {
  final VoidCallback onProfileSaved;
  const CvUploadScreen({super.key, required this.onProfileSaved});

  @override
  State<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends State<CvUploadScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _extractedData;

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
      setState(() => _extractedData = parsed);
    } catch (e) {
      setState(() => _error = 'Couldn\'t read that CV — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      widget.onProfileSaved();
    } catch (e) {
      setState(() => _error = 'Couldn\'t save your profile — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _extractedData != null;
    final skills = (_extractedData?['skills'] as List<dynamic>? ?? []);
    final experience = (_extractedData?['experience'] as List<dynamic>? ?? []);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.pineLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasData ? Icons.task_alt_rounded : Icons.upload_file_rounded,
                  color: AppColors.pine,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hasData ? 'Here\'s what we found' : 'Let JobHero read your CV',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                hasData
                    ? 'Review the details below, then save to start matching with jobs.'
                    : 'Upload a PDF and we\'ll pull out your skills and experience automatically.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.emberLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.ember),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.ember, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              if (hasData) ...[
                _SectionLabel('Skills'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => Chip(label: Text(s.toString()))).toList(),
                ),
                const SizedBox(height: 24),
                if (experience.isNotEmpty) ...[
                  _SectionLabel('Experience'),
                  const SizedBox(height: 10),
                  ...experience.map((exp) {
                    final e = exp as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${e['company'] ?? ''}',
                              style: const TextStyle(color: AppColors.pine, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e['start'] ?? ''} – ${e['end'] ?? ''}',
                              style: const TextStyle(color: AppColors.stone, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                        )
                      : const Text('Save & continue'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _isLoading ? null : _pickAndUpload,
                  child: const Text('Re-upload'),
                ),
              ] else
                Column(
                  children: [
                    DottedUploadCard(
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _pickAndUpload,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.stone,
      ),
    );
  }
}

class DottedUploadCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const DottedUploadCard({super.key, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sand, width: 1.5),
        ),
        child: Column(
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pine),
              const SizedBox(height: 16),
              const Text(
                'JobHero is reading your CV...',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.stone, fontSize: 14),
              ),
            ] else ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.pine),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select PDF',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to choose a file',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.stone, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}