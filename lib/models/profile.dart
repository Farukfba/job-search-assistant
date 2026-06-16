class Profile {
  final String userId;
  final List<String> skills;
  final List<Map<String, dynamic>> experience;
  final List<String> keywords;
  final String? rawCvText;

  Profile({
    required this.userId,
    required this.skills,
    required this.experience,
    required this.keywords,
    this.rawCvText,
  });

  Map<String, dynamic> toJson() => {
        'skills': skills,
        'experience': experience,
        'keywords': keywords,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json['user_id'] ?? '',
        skills: List<String>.from(json['extracted_skills'] ?? json['skills'] ?? []),
        experience: List<Map<String, dynamic>>.from(
            json['extracted_experience'] ?? json['experience'] ?? []),
        keywords: List<String>.from(json['keywords'] ?? []),
        rawCvText: json['raw_cv_text'],
      );
}