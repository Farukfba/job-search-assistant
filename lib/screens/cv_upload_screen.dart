import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isProcessing = false;
  String? _error;
  String? _fileName;
  int? _fileSize;
  Map<String, dynamic>? _extractedData;
  double _progress = 0;

  // Terminal lines shown during processing
  final List<String> _terminalLines = [];
  static const _processingSteps = [
    '> Parsing document structure...',
    '> Extracting work experience...',
    '> Identifying technical skills...',
    '> Parsing education history...',
    '> Computing keyword density...',
    '> Generating CV profile...',
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      _fileSize = file.size;
      _isLoading = true;
      _isProcessing = true;
      _error = null;
      _terminalLines.clear();
      _progress = 0;
    });

    // Simulate terminal lines appearing as we process
    for (int i = 0; i < _processingSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() {
        _terminalLines.add(_processingSteps[i]);
        _progress = (i + 1) / (_processingSteps.length + 1);
      });
    }

    try {
      final parsed = await ApiService.parseCv(file.bytes!, file.name);
      setState(() {
        _extractedData = parsed;
        _progress = 1.0;
        _terminalLines.add('> Analysis complete. Score: 94');
      });

      await Future.delayed(const Duration(milliseconds: 800));

      // Save to Supabase
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('profiles').upsert({
        'user_id': userId,
        'extracted_skills': parsed['skills'],
        'extracted_experience': parsed['experience'],
        'raw_cv_text': parsed['raw_text'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      widget.onProfileSaved();
    } catch (e) {
      setState(() => _error = 'Couldn\'t process your CV — please try again.');
    } finally {
      if (mounted) setState(() { _isLoading = false; _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;

    if (_isProcessing) {
      return _ProcessingView(
        sans: sans,
        fileName: _fileName ?? '',
        fileSize: _fileSize ?? 0,
        progress: _progress,
        terminalLines: _terminalLines,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 1 OF 2', style: TextStyle(fontFamily: sans, fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text('Upload your CV', style: TextStyle(fontFamily: sans, fontSize: 28,
                  fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('We\'ll analyze your skills and experience to score your job matches.',
                  style: TextStyle(fontFamily: sans, fontSize: 15,
                      color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 32),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),

              // Drop zone
              GestureDetector(
                onTap: _isLoading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 52),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: Column(children: [
                    Icon(Icons.upload_rounded, size: 32, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text('Drop your CV here', style: TextStyle(fontFamily: sans, fontSize: 16,
                        fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text('or click to browse', style: TextStyle(fontFamily: sans,
                        fontSize: 13, color: AppColors.muted)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // File type badges
              Row(children: [
                ...['PDF', 'DOCX', 'DOC'].map((t) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t, style: TextStyle(fontFamily: sans, fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
                )),
                Text('up to 10 MB', style: TextStyle(fontFamily: sans,
                    fontSize: 12, color: AppColors.muted)),
              ]),

              const Spacer(),

              // Disabled CTA until file selected
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  disabledForegroundColor: AppColors.muted,
                ),
                child: Text('Select a file to continue', style: TextStyle(fontFamily: sans,
                    fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  final String sans;
  final String fileName;
  final int fileSize;
  final double progress;
  final List<String> terminalLines;

  const _ProcessingView({required this.sans, required this.fileName,
      required this.fileSize, required this.progress, required this.terminalLines});

  String get _fileSizeMb => '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB';
  int get _progressPct => (progress * 100).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 2 OF 2', style: TextStyle(fontFamily: sans, fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text('Reviewing your CV', style: TextStyle(fontFamily: sans, fontSize: 28,
                  fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('Our AI is analyzing your profile. This takes about 10 seconds.',
                  style: TextStyle(fontFamily: sans, fontSize: 15, color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 24),

              // File card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fileName, style: TextStyle(fontFamily: sans, fontSize: 14,
                        fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text('$_fileSizeMb · PDF', style: TextStyle(fontFamily: sans,
                        fontSize: 12, color: AppColors.muted)),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              // Progress bar
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Processing', style: TextStyle(fontFamily: sans, fontSize: 13,
                    color: AppColors.muted, fontWeight: FontWeight.w500)),
                Text('$_progressPct%', style: TextStyle(fontFamily: sans, fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.green)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
              ),
              const SizedBox(height: 20),

              // Terminal block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.terminalBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traffic lights
                    Row(children: [
                      ...[ Color(0xFFFF5F57), Color(0xFFFFBD2E), Color(0xFF28C840)]
                          .map((c) => Container(
                            width: 12, height: 12, margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          )),
                      const SizedBox(width: 8),
                      const Text('cv-parser', style: TextStyle(fontFamily: 'monospace',
                          fontSize: 12, color: AppColors.terminalText)),
                    ]),
                    const SizedBox(height: 16),
                    ...terminalLines.map((line) {
                      final isLast = line == terminalLines.last &&
                          line.contains('complete');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(line, style: TextStyle(
                          fontFamily: 'monospace', fontSize: 12,
                          color: isLast ? AppColors.terminalGreen : AppColors.terminalText,
                        )),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}