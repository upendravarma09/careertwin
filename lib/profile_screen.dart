import 'package:flutter/material.dart';
import 'api_service.dart';
import 'career_analysis_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: "Upendra");
  final _roleController = TextEditingController(text: "Student");
  final _skillsController = TextEditingController(text: "Python, SQL, Excel");
  final _goalController = TextEditingController(text: "Cybersecurity Analyst");

  String _selectedExperience = "Student";
  final List<String> _experienceLevels = [
    "Student",
    "Beginner",
    "Intermediate",
    "Experienced",
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _skillsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.analyzeCareer(
        name: _nameController.text.trim(),
        currentRole: _roleController.text.trim(),
        skills: _skillsController.text.trim(),
        experience: _selectedExperience,
        careerGoal: _goalController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CareerAnalysisScreen(
            careerGoal: _goalController.text.trim(),
            analysis: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('CareerTwin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Set up your profile",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Gemini AI benchmarks your current abilities against any target profession.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(label: "Full Name", controller: _nameController, hint: "e.g. Upendra"),
                  const SizedBox(height: 16),
                  _buildTextField(label: "Current Role / Education", controller: _roleController, hint: "e.g. Student"),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "Current Skills (comma-separated)",
                    controller: _skillsController,
                    hint: "e.g. Python, SQL, Excel",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text("Experience Level", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedExperience,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(),
                    items: _experienceLevels.map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExperience = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "Target Career Goal (Any role)",
                    controller: _goalController,
                    hint: "e.g. Cybersecurity Analyst, Game Developer, Pilot",
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 14),
                                Text("Analyzing with Gemini...", style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : const Text("Generate CareerTwin Analysis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(hint: hint),
          validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}