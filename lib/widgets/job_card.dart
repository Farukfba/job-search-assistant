import 'package:flutter/material.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${job.company} • ${job.location}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}