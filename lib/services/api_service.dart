import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl =
      'https://skill-seeker-service.lovable.app';

  static String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-user-id': _userId ?? '',
      };

  static Future<Map<String, dynamic>> parseCv(List<int> fileBytes, String fileName) async {
  final uri = Uri.parse('$baseUrl/api/public/parse-cv');
  final request = http.MultipartRequest('POST', uri)
    ..headers['x-user-id'] = _userId ?? ''
    ..files.add(http.MultipartFile.fromBytes('cv', fileBytes, filename: fileName));

  print('Sending to: $uri');
  print('User ID header: ${_userId ?? "MISSING"}');

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  print('Status code: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception('Failed to parse CV (${response.statusCode}): ${response.body}');
}

  static Future<List<dynamic>> searchJobs(String title, String location) async {
    final uri = Uri.parse('$baseUrl/api/public/search-jobs');
    final response = await http.post(uri,
        headers: _headers,
        body: jsonEncode({'title': title, 'location': location}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['jobs'];
    }
    throw Exception('Failed to search jobs: ${response.body}');
  }

  static Future<Map<String, dynamic>> matchJob(
      Map<String, dynamic> cvData, String jobDescription) async {
    final uri = Uri.parse('$baseUrl/api/public/match-job');
    final response = await http.post(uri,
        headers: _headers,
        body: jsonEncode({'cv_data': cvData, 'job_description': jobDescription}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to match job: ${response.body}');
  }

  static Future<String> coverLetter(
      Map<String, dynamic> cvData, String jobDescription) async {
    final uri = Uri.parse('$baseUrl/api/public/cover-letter');
    final response = await http.post(uri,
        headers: _headers,
        body: jsonEncode({'cv_data': cvData, 'job_description': jobDescription}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cover_letter'] ?? response.body;
    }
    throw Exception('Failed to generate cover letter: ${response.body}');
  }

  static Future<List<dynamic>> interviewPrep(
      Map<String, dynamic> cvData, String jobDescription) async {
    final uri = Uri.parse('$baseUrl/api/public/interview-prep');
    final response = await http.post(uri,
        headers: _headers,
        body: jsonEncode({'cv_data': cvData, 'job_description': jobDescription}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['questions'] ?? [];
    }
    throw Exception('Failed to generate interview prep: ${response.body}');
  }
}