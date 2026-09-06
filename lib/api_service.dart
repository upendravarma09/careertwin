import 'dart:convert';

import 'package:http/http.dart' as http;

class CareerProfile {
  final String currentRole;
  final String targetRole;
  final String skills;

  CareerProfile({
    required this.currentRole,
    required this.targetRole,
    required this.skills,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_role': currentRole,
      'target_role': targetRole,
      'skills': skills,
    };
  }
}

class AnalysisResult {
  final int matchScore;
  final List<String> missingSkills;
  final List<String> recommendedProjects;
  final List<String> learningRoadmap;
  final String summary;

  AnalysisResult({
    required this.matchScore,
    required this.missingSkills,
    required this.recommendedProjects,
    required this.learningRoadmap,
    required this.summary,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      matchScore: json['match_score'] ?? 0,
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      recommendedProjects: List<String>.from(
        json['recommended_projects'] ?? [],
      ),
      learningRoadmap: List<String>.from(json['learning_roadmap'] ?? []),
      summary: json['summary'] ?? '',
    );
  }

  String toMarkdownReport({
    required String currentRole,
    required String targetRole,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# CareerTwin Transition Report');
    buffer.writeln('**Current Role:** $currentRole');
    buffer.writeln('**Target Role:** $targetRole');
    buffer.writeln('**Readiness Match Score:** $matchScore%\n');
    buffer.writeln('## Summary\n$summary\n');
    buffer.writeln('## Missing Skills');
    for (final skill in missingSkills) {
      buffer.writeln('- $skill');
    }
    buffer.writeln('\n## Recommended Projects');
    for (final project in recommendedProjects) {
      buffer.writeln('- $project');
    }
    buffer.writeln('\n## Learning Roadmap');
    for (int i = 0; i < learningRoadmap.length; i++) {
      buffer.writeln('${i + 1}. ${learningRoadmap[i]}');
    }
    return buffer.toString();
  }
}

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
      matchScore: json['match_score'] is int
          ? json['match_score'] as int
          : int.tryParse(json['match_score']?.toString() ?? '0') ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      skillGaps: List<String>.from(json['skill_gaps'] ?? []),
      roadmap: List<String>.from(json['roadmap'] ?? []),
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class ApiService {
  // Your live Render backend URL
  static const String _baseUrl = 'https://careertwin-backend-6gxx.onrender.com';

  static Future<CareerAnalysisResult> analyzeCareer({
    required String name,
    required String currentRole,
    required String skills,
    required String experience,
    required String careerGoal,
  }) async {
    final url = Uri.parse('$_baseUrl/analyze');

    try {
      final response = await http.post(
        url,
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
      }

      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('detail')) {
          throw Exception(errorBody['detail']);
        }
      } catch (_) {}

      throw Exception(
        'Server returned status code ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AnalysisResult> sendProfile(CareerProfile profile) async {
    final url = Uri.parse('$_baseUrl/analyze');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResult.fromJson(data);
    } else {
      throw Exception(
        'Server returned status code ${response.statusCode}: ${response.body}',
      );
    }
  }
}
