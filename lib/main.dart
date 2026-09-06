import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareerTwinApp());
}

class CareerTwinApp extends StatelessWidget {
  const CareerTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerTwin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentRoleController = TextEditingController();
  final _targetRoleController = TextEditingController();
  final _skillsController = TextEditingController();

  final ApiService _apiService = ApiService();
  AnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  // Retrieve cached profile inputs and analysis result on startup
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedCurrentRole = prefs.getString('cached_current_role');
    final cachedTargetRole = prefs.getString('cached_target_role');
    final cachedSkills = prefs.getString('cached_skills');
    final cachedAnalysisRaw = prefs.getString('cached_analysis');

    setState(() {
      _currentRoleController.text =
          cachedCurrentRole ?? 'Junior Frontend Developer';
      _targetRoleController.text = cachedTargetRole ?? 'Full Stack Engineer';
      _skillsController.text =
          cachedSkills ?? 'HTML, CSS, JavaScript, React, Git';

      if (cachedAnalysisRaw != null) {
        try {
          final decoded = jsonDecode(cachedAnalysisRaw) as Map<String, dynamic>;
          _analysisResult = AnalysisResult.fromJson(decoded);
        } catch (_) {
          // If cached data is corrupted, ignore and proceed
        }
      }
    });
  }

  // Persist latest analysis and form state to browser local storage
  Future<void> _persistData(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();

    final payload = {
      'match_score': result.matchScore,
      'missing_skills': result.missingSkills,
      'recommended_projects': result.recommendedProjects,
      'learning_roadmap': result.learningRoadmap,
      'summary': result.summary,
    };

    await prefs.setString('cached_analysis', jsonEncode(payload));
    await prefs.setString(
      'cached_current_role',
      _currentRoleController.text.trim(),
    );
    await prefs.setString(
      'cached_target_role',
      _targetRoleController.text.trim(),
    );
    await prefs.setString('cached_skills', _skillsController.text.trim());
  }

  Future<void> _handleAnalyze() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = CareerProfile(
        currentRole: _currentRoleController.text.trim(),
        targetRole: _targetRoleController.text.trim(),
        skills: _skillsController.text.trim(),
      );

      final result = await _apiService.sendProfile(profile);
      await _persistData(result);

      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyReportToClipboard() {
    if (_analysisResult == null) return;
    final markdown = _analysisResult!.toMarkdownReport(
      currentRole: _currentRoleController.text.trim(),
      targetRole: _targetRoleController.text.trim(),
    );
    Clipboard.setData(ClipboardData(text: markdown));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markdown report copied to clipboard!')),
    );
  }

  @override
  void dispose() {
    _currentRoleController.dispose();
    _targetRoleController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareerTwin // AI Career Architect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'Copy Report as Markdown',
              onPressed: _copyReportToClipboard,
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Form
          SizedBox(
            width: 400,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Text(
                        'Profile Parameters',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentRoleController,
                        decoration: const InputDecoration(
                          labelText: 'Current Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Current role required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetRoleController,
                        decoration: const InputDecoration(
                          labelText: 'Target Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.ads_click),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Target role required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skillsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Skills (comma separated)',
                          hintText: 'e.g. Flutter, Dart, Python, SQL',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'List at least one skill'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _handleAnalyze,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.bolt),
                        label: Text(
                          _isLoading
                              ? 'Generating Roadmap...'
                              : 'Analyze Readiness',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right Output Pane
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: _buildRightPane(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Synthesizing career gap analysis with Gemini...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _handleAnalyze,
                  child: const Text('Retry Analysis'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_analysisResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Fill in your background on the left and run analysis.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final res = _analysisResult!;

    return ListView(
      children: [
        // Score Card
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: res.matchScore / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade300,
                        color: res.matchScore > 70
                            ? Colors.green
                            : (res.matchScore > 40
                                  ? Colors.orange
                                  : Colors.red),
                      ),
                      Text(
                        '${res.matchScore}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Readiness Verdict',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(res.summary, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Skills Gap Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missing Skill Inventory',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: res.missingSkills.map((skill) {
                    return Chip(
                      avatar: const Icon(
                        Icons.add_task,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: Text(skill),
                      backgroundColor: Colors.red.withValues(alpha: 0.06),
                      side: BorderSide(color: Colors.red.shade200),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Projects Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Projects to Build',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...res.recommendedProjects.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code, color: Colors.indigo),
                    title: Text(p),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Transition Roadmap
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transition Roadmap',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: res.learningRoadmap.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(res.learningRoadmap[index]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
