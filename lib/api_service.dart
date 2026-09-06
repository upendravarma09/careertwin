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

  Map<String, dynamic> toJson() => {
    'current_role': currentRole,
    'career_goal': targetRole, // Satisfies backend "career_goal" field
    'target_role': targetRole, // Kept for compatibility
    'skills': skills, // Sent as a plain String
  };
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
    // Helper to safely parse lists even if backend returns them as strings or null
    List<String> parseList(dynamic field) {
      if (field == null) return [];
      if (field is List) return field.map((e) => e.toString()).toList();
      if (field is String) {
        return field
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return AnalysisResult(
      matchScore: json['match_score'] is int
          ? json['match_score'] as int
          : int.tryParse(json['match_score']?.toString() ?? '0') ?? 0,
      missingSkills: parseList(json['missing_skills']),
      recommendedProjects: parseList(json['recommended_projects']),
      learningRoadmap: parseList(json['learning_roadmap']),
      summary:
          json['summary']?.toString() ??
          json['recommendations']?.toString() ??
          'No summary available.',
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
    buffer.writeln('**Readiness Score:** $matchScore%\n');
    buffer.writeln('## Summary\n$summary\n');
    if (missingSkills.isNotEmpty) {
      buffer.writeln('## Missing Skills');
      for (var s in missingSkills) {
        buffer.writeln('- $s');
      }
      buffer.writeln();
    }
    if (recommendedProjects.isNotEmpty) {
      buffer.writeln('## Recommended Projects');
      for (var p in recommendedProjects) {
        buffer.writeln('- $p');
      }
      buffer.writeln();
    }
    if (learningRoadmap.isNotEmpty) {
      buffer.writeln('## Learning Roadmap');
      for (var i = 0; i < learningRoadmap.length; i++) {
        buffer.writeln('${i + 1}. ${learningRoadmap[i]}');
      }
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
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

class ApiService {
  // Uses 127.0.0.1 to match your active backend server address
  static const String _baseUrl = 'http://127.0.0.1:8000';

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

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return AnalysisResult.fromJson(decoded);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            throw Exception(errorBody['detail']);
          }
        } catch (_) {}
        throw Exception(
          'Server returned status code ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
