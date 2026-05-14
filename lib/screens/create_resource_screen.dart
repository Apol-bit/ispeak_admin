import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
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
  late String _transcript; // Renamed from _content for clarity
  late int _estimatedMinutes;

  // --- Reference Audio ---
  PlatformFile? _pickedAudioFile; // The newly picked file (for upload)
  String? _existingAudioPath; // Path of already-uploaded reference audio

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
    if (!['English', 'Filipino', 'Taglish', 'None'].contains(_language)) _language = 'English';

    // Pull estimatedMinutes from existing data, default to 2
    _estimatedMinutes = r?['estimatedMinutes'] ?? 2;
    
    // Transcript (was previously called 'content')
    _transcript = r?['transcript'] ?? r?['content'] ?? '';
    
    // Existing reference audio path (if editing)
    _existingAudioPath = r?['referenceAudioPath'];

    _timeLimitSeconds = r?['timeLimitSeconds'] ?? 60;
    _targetMetric = r?['targetMetric'] ?? '';
    _prompt = r?['prompt'] ?? '';
    _tipsRaw = (r?['tips'] as List<dynamic>?)?.join('\n') ?? '';

    _category = r?['category'] ?? '';
    _iconName = r?['iconName'] ?? '';
    _stepsRaw = (r?['steps'] as List<dynamic>?)?.join('\n') ?? '';
    _proTip = r?['proTip'] ?? '';
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'm4a', 'flac', 'ogg', 'aac'],
      withData: true, // Needed for web
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedAudioFile = result.files.first;
      });
    }
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
      
      // Use MultipartRequest to support file upload
      final request = http.MultipartRequest(
        isEdit ? 'PUT' : 'POST',
        url,
      );

      // Add common text fields
      request.fields['type'] = _type;
      request.fields['title'] = _title;
      request.fields['description'] = _description;
      request.fields['difficulty'] = _difficulty;
      request.fields['language'] = _language;

      if (_type == 'Script') {
        request.fields['transcript'] = _transcript;
        request.fields['content'] = _transcript; // Also set content for backward compat
        request.fields['estimatedMinutes'] = _estimatedMinutes.toString();
        
        // Attach reference audio file if one was picked
        if (_pickedAudioFile != null) {
          if (_pickedAudioFile!.bytes != null) {
            // Web platform — use bytes
            request.files.add(http.MultipartFile.fromBytes(
              'referenceAudio',
              _pickedAudioFile!.bytes!,
              filename: _pickedAudioFile!.name,
            ));
          } else if (_pickedAudioFile!.path != null) {
            // Desktop/Mobile — use file path
            request.files.add(await http.MultipartFile.fromPath(
              'referenceAudio',
              _pickedAudioFile!.path!,
            ));
          }
        }
      } else if (_type == 'Challenge') {
        request.fields['timeLimitSeconds'] = _timeLimitSeconds.toString();
        request.fields['targetMetric'] = _targetMetric;
        request.fields['prompt'] = _prompt;
        request.fields['tips'] = json.encode(
          _tipsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList()
        );
      } else if (_type == 'GuidedTask') {
        request.fields['category'] = _category;
        request.fields['iconName'] = _iconName;
        request.fields['proTip'] = _proTip;
        request.fields['steps'] = json.encode(
          _stepsRaw.split('\n').where((s) => s.trim().isNotEmpty).toList()
        );
        request.fields['estimatedMinutes'] = _estimatedMinutes.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
                          items: ['English', 'Filipino', 'Taglish', 'None'].map((String value) {
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

                  if (_type == 'Script') ...[
                    // ── REFERENCE AUDIO UPLOAD MODULE ────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.scaffoldColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _pickedAudioFile != null || (_existingAudioPath != null && _existingAudioPath!.isNotEmpty)
                              ? Colors.green.withOpacity(0.5)
                              : theme.borderColor,
                          width: _pickedAudioFile != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.audiotrack, color: AppTheme.primaryColor, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Reference Audio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.headingColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload a reference audio file of how this script should be spoken. '
                            'The AI will compare user recordings against this baseline.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.subtleTextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Show existing audio info (if editing)
                          if (_existingAudioPath != null && _existingAudioPath!.isNotEmpty && _pickedAudioFile == null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Reference audio already uploaded',
                                      style: TextStyle(
                                        color: theme.bodyTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Show newly picked file info
                          if (_pickedAudioFile != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pickedAudioFile!.name,
                                          style: TextStyle(
                                            color: theme.bodyTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(_pickedAudioFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            color: theme.subtleTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                    onPressed: () => setState(() => _pickedAudioFile = null),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickAudioFile,
                              icon: Icon(
                                _pickedAudioFile != null || (_existingAudioPath != null && _existingAudioPath!.isNotEmpty)
                                    ? Icons.swap_horiz
                                    : Icons.upload_file,
                                size: 18,
                              ),
                              label: Text(
                                _pickedAudioFile != null
                                    ? 'Replace Audio File'
                                    : (_existingAudioPath != null && _existingAudioPath!.isNotEmpty)
                                        ? 'Replace Existing Audio'
                                        : 'Choose Audio File',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // ── TRANSCRIPT FIELD ─────────────────────────────────────
                    TextFormField(
                      initialValue: _estimatedMinutes.toString(),
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Estimated Time (Minutes)'),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _estimatedMinutes = int.tryParse(value ?? '2') ?? 2,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _transcript,
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Transcript (The text the user will read)').copyWith(
                        alignLabelWithHint: true,
                        helperText: 'This is the script text shown to users during practice',
                        helperStyle: TextStyle(color: theme.subtleTextColor, fontSize: 11),
                      ),
                      maxLines: 10,
                      onSaved: (value) => _transcript = value ?? '',
                    ),
                  ],

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
                      initialValue: _estimatedMinutes.toString(),
                      style: TextStyle(color: theme.bodyTextColor),
                      decoration: _inputStyle('Estimated Time (Minutes)'),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _estimatedMinutes = int.tryParse(value ?? '5') ?? 5,
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