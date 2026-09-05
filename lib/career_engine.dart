class CareerAnalysis {
  final int matchScore;
  final List<String> strengths;
  final List<String> skillGaps;
  final List<String> roadmap;

  CareerAnalysis({
    required this.matchScore,
    required this.strengths,
    required this.skillGaps,
    required this.roadmap,
  });
}

class CareerEngine {
  static CareerAnalysis analyze({
    required String careerGoal,
    required String skills,
    required String experience,
  }) {
    final userSkills = skills
        .toLowerCase()
        .split(RegExp(r'[,;\n]'))
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    final strengths = userSkills.take(5).toList();

    final gaps = <String>[
      'Career-specific knowledge',
      'Practical experience',
      'Professional portfolio',
    ];

    final roadmap = <String>[
      'Understand the fundamentals of $careerGoal',
      'Learn the core skills required',
      'Build practical projects or experience',
      'Develop a professional portfolio',
      'Prepare for real-world opportunities',
    ];

    int experienceScore;

    switch (experience) {
      case 'Beginner':
        experienceScore = 10;
        break;
      case 'Intermediate':
        experienceScore = 20;
        break;
      case 'Experienced':
        experienceScore = 30;
        break;
      default:
        experienceScore = 5;
    }

    final skillScore = userSkills.isEmpty ? 0 : 30;
    final goalScore = careerGoal.trim().isNotEmpty ? 10 : 0;

    final score = (skillScore + experienceScore + goalScore).clamp(0, 100);

    return CareerAnalysis(
      matchScore: score,
      strengths: strengths.isEmpty
          ? ['Problem Solving', 'Learning Ability']
          : strengths,
      skillGaps: gaps,
      roadmap: roadmap,
    );
  }
}