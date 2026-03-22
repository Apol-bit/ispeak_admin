import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class CreateResourceScreen extends StatefulWidget {
  final Map<String, dynamic>? resource; // Allows the screen to accept existing data!

  const CreateResourceScreen({super.key, this.resource});

  @override
  _CreateResourceScreenState createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends State<CreateResourceScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Common Fields ---
  late String _type;
  late String _title;
  late String _description;
  late String _difficulty;
  late String _language;

  // --- Script Fields ---
  late String _content;

  // --- Challenge Fields ---
  late int _timeLimitSeconds;
  late String _targetMetric;
  late String _prompt;
  late String _tipsRaw; // We will split this by newlines into an array

  // --- Guided Task Fields ---
  late String _category;
  late String _iconName;
  late String _stepsRaw; // We will split this by newlines into an array
  late String _proTip;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.resource; // Grab the passed data (if any)

    // Pre-fill the variables. If 'r' is null, it defaults to the empty creation state!
    _type = r?['type'] ?? 'Script';
    _title = r?['title'] ?? '';
    _description = r?['description'] ?? '';
    
    // Safety checks for Enums just in case DB data is missing
    _difficulty = r?['difficulty'] ?? 'Beginner';
    if (!['Beginner', 'Intermediate', 'Advanced', 'None'].contains(_difficulty)) _difficulty = 'Beginner';
    
    _language = r?['language'] ?? 'English';
    if (!['English', 'Filipino', 'Bilingual', 'None'].contains(_language)) _language = 'English';

    _content = r?['content'] ?? '';

    _timeLimitSeconds = r?['timeLimitSeconds'] ?? 60;
    _targetMetric = r?['targetMetric'] ?? '';
    _prompt = r?['prompt'] ?? '';
    _tipsRaw = (r?['tips'] as List<dynamic>?)?.join('\n') ?? '';

    _category = r?['category'] ?? '';
    _iconName = r?['iconName'] ?? '';
    _stepsRaw = (r?['steps'] as List<dynamic>?)?.join('\n') ?? '';
    _proTip = r?['proTip'] ?? '';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.resource != null;
      
      // Dynamic URL: If editing, target the specific ID with a PUT request. Else, POST.
      final url = isEdit 
          ? Uri.parse('${ApiConfig.baseUrl}/admin/resources/${widget.resource!['_id']}')
          : Uri.parse('${ApiConfig.baseUrl}/admin/resources');
      
      Map<String, dynamic> payload = {
        'type': _type,
        'title': _title,
        'description': _description,
        'difficulty': _difficulty,
        'language': _language,
      };

      if (_type == 'Script') {
        payload['content'] = _content;
      } else if (_type == 'Challenge') {
        payload['timeLimitSeconds'] = _timeLimitSeconds;
        payload['targetMetric'] = _targetMetric;
        payload['prompt'] = _prompt;
        payload['tips'] = _tipsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList();
      } else if (_type == 'GuidedTask') {
        payload['category'] = _category;
        payload['iconName'] = _iconName;
        payload['proTip'] = _proTip;
        payload['steps'] = _stepsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList();
      }

      final response = isEdit
          ? await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(payload))
          : await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Resource Updated Successfully!' : 'Resource Saved Successfully!'), 
            backgroundColor: Colors.green
          ),
        );
        // UX Magic: Automatically close the modal when save is successful!
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isEdit = widget.resource != null;

    InputDecoration _inputStyle(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.subtleTextColor),
        filled: true,
        fillColor: theme.scaffoldColor,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? "Edit Learning Resource" : "Add New Learning Resource",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.headingColor,
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _inputStyle('Resource Type'),
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: theme.bodyTextColor),
                    items: ['Script', 'Challenge', 'GuidedTask'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) => setState(() => _type = newValue!),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _title,
                    style: TextStyle(color: theme.bodyTextColor),
                    decoration: _inputStyle('Title (e.g., Quick Pitch)'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _title = value!,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _description,
                    style: TextStyle(color: theme.bodyTextColor),
                    decoration: _inputStyle('Short Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _description = value!,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _difficulty,
                          decoration: _inputStyle('Difficulty'),
                          dropdownColor: theme.cardColor,
                          style: TextStyle(color: theme.bodyTextColor),
                          items: ['Beginner', 'Intermediate', 'Advanced', 'None'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (newValue) => setState(() => _difficulty = newValue!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _language,
                          decoration: _inputStyle('Language'),
                          dropdownColor: theme.cardColor,
                          style: TextStyle(color: theme.bodyTextColor),
                          items: ['English', 'Filipino', 'Bilingual', 'None'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (newValue) => setState(() => _language = newValue!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Divider(color: theme.borderColor),
                  const SizedBox(height: 24),

                  if (_type == 'Script')
                    TextFormField(
                      initialValue: _content,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Full Script Text').copyWith(alignLabelWithHint: true),
                      maxLines: 10,
                      onSaved: (value) => _content = value ?? '',
                    ),

                  if (_type == 'Challenge') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _timeLimitSeconds.toString(),
                            style: TextStyle(color: theme.bodyTextColor),
                            decoration: _inputStyle('Time Limit (Seconds)'),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _timeLimitSeconds = int.tryParse(value ?? '60') ?? 60,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _targetMetric,
                            style: TextStyle(color: theme.bodyTextColor),
                            decoration: _inputStyle('Target Metric (e.g., 120-140 WPM)'),
                            onSaved: (value) => _targetMetric = value ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _prompt,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Prompt / Context'),
                      maxLines: 3,
                      onSaved: (value) => _prompt = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _tipsRaw,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Tips (Press Enter for a new bullet point)'),
                      maxLines: 4,
                      onSaved: (value) => _tipsRaw = value ?? '',
                    ),
                  ],

                  if (_type == 'GuidedTask') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _category,
                            style: TextStyle(color: theme.bodyTextColor),
                            decoration: _inputStyle('Category (e.g., Foundation)'),
                            onSaved: (value) => _category = value ?? '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _iconName,
                            style: TextStyle(color: theme.bodyTextColor),
                            decoration: _inputStyle('Icon Name (e.g., volume_up)'),
                            onSaved: (value) => _iconName = value ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _stepsRaw,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Steps (Press Enter for a new numbered step)'),
                      maxLines: 6,
                      onSaved: (value) => _stepsRaw = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _proTip,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Pro Tip'),
                      maxLines: 2,
                      onSaved: (value) => _proTip = value ?? '',
                    ),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 24, width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            ) 
                          : Text(isEdit ? 'Update Resource' : 'Save Resource', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}