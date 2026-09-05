import 'dart:convert';
import 'package:http/http.dart' as http;

class CareerAnalysisResult {
  final int matchScore;
  final List<String> strengths;
  final List<String> skillGaps;
  final List<String> roadmap;
  final String recommendation;

  CareerAnalysisResult({
    required this.matchScore,
    required this.strengths,
    required this.skillGaps,
    required this.roadmap,
    required this.recommendation,
  });

  factory CareerAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CareerAnalysisResult(
      matchScore: json['match_score'] as int? ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      skillGaps: List<String>.from(json['skill_gaps'] ?? []),
      roadmap: List<String>.from(json['roadmap'] ?? []),
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

class ApiService {
  // Using localhost to match Edge/Chrome browser origin
  static const String baseUrl = 'http://localhost:8000';

  static Future<CareerAnalysisResult> analyzeCareer({
    required String name,
    required String currentRole,
    required String skills,
    required String experience,
    required String careerGoal,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'current_role': currentRole,
        'skills': skills,
        'experience': experience,
        'career_goal': careerGoal,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return CareerAnalysisResult.fromJson(decoded);
    } else {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
  }
}