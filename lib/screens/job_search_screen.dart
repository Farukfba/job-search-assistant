import 'package:flutter/material.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Job> _jobs = [];
  bool _hasSearched = false;

  Future<void> _search() async {
    if (_titleController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      setState(() => _error = 'Enter both a job title and location.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchJobs(
        _titleController.text.trim(),
        _locationController.text.trim(),
      );
      setState(() => _jobs = results.map((j) => Job.fromJson(j)).toList());
    } catch (e) {
      setState(() => _error = 'Failed to search jobs — please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job title',
                hintText: 'e.g. Flutter Developer',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. London',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _search,
              icon: _isLoading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Searching live job listings...' : 'Search Jobs'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: !_hasSearched
                  ? const Center(child: Text('Search for jobs to get started.'))
                  : _jobs.isEmpty && !_isLoading
                      ? const Center(
                          child: Text('No jobs found — try a broader location or title.'),
                        )
                      : ListView.builder(
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
                            return JobCard(
                              job: job,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobDetailScreen(job: job),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}