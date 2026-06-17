import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  static const _stages = ['Applied', 'Interview', 'Offer', 'Rejected'];
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await ApiService.getSavedJobs();
      setState(() => _jobs = jobs);
    } catch (e) {
      setState(() => _error = 'Failed to load tracker — please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _advanceStage(Map<String, dynamic> job) async {
    final currentIndex = _stages.indexOf(job['status'] ?? 'Applied');
    if (currentIndex >= _stages.length - 1) return;
    final newStatus = _stages[currentIndex + 1];

    try {
      await ApiService.updateJobStatus(job['id'], newStatus);
      setState(() => job['status'] = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status — please try again.')),
        );
      }
    }
  }

  Future<void> _markRejected(Map<String, dynamic> job) async {
    try {
      await ApiService.updateJobStatus(job['id'], 'Rejected');
      setState(() => job['status'] = 'Rejected');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status — please try again.')),
        );
      }
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'Interview':
        return Colors.blue;
      case 'Offer':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Tracker')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _jobs.isEmpty
                    ? const Center(child: Text('No saved jobs yet — save one from a job\'s detail screen.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stages.length,
                        itemBuilder: (context, stageIndex) {
                          final stage = _stages[stageIndex];
                          final stageJobs =
                              _jobs.where((j) => (j['status'] ?? 'Applied') == stage).toList();

                          if (stageJobs.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _stageColor(stage),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$stage (${stageJobs.length})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              ...stageJobs.map((job) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(job['job_title'] ?? ''),
                                      subtitle: Text(
                                          '${job['company'] ?? ''} • Match: ${job['match_score'] ?? '—'}%'),
                                      trailing: stage == 'Rejected'
                                          ? null
                                          : PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'advance') _advanceStage(job);
                                                if (value == 'reject') _markRejected(job);
                                              },
                                              itemBuilder: (context) => [
                                                if (stage != 'Offer')
                                                  const PopupMenuItem(
                                                      value: 'advance', child: Text('Move to next stage')),
                                                const PopupMenuItem(
                                                    value: 'reject', child: Text('Mark as Rejected')),
                                              ],
                                            ),
                                    ),
                                  )),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}