class Job {
  final String title;
  final String company;
  final String location;
  final String description;
  final String url;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.url,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        title: json['title'] ?? '',
        company: json['company'] ?? '',
        location: json['location'] ?? '',
        description: json['description'] ?? '',
        url: json['url'] ?? '',
      );
}