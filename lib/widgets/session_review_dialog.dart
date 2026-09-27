import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

// 3. Dynamic Modal to Inspect the Session Output
void showSessionReview(BuildContext context, Map<String, dynamic> session) {
  final theme = ThemeProvider.of(context)!;
  final isDark = theme.isDarkMode;

  String formatUserId(dynamic userIdData) {
    if (userIdData == null) return "Unknown";
    if (userIdData is Map) {
      final firstName = userIdData['firstName'] ?? '';
      final lastName = userIdData['lastName'] ?? '';
      final email = userIdData['email'] ?? '';
      final id = userIdData['_id'] ?? '';

      final namePart = '$firstName $lastName'.trim();
      if (namePart.isNotEmpty) {
        return '$namePart ($email)\nID: $id';
      } else if (email.isNotEmpty) {
        return '$email\nID: $id';
      } else {
        return id.toString();
      }
    }
    return userIdData.toString();
  }

  showDialog(
    context: context,
    builder: (dialogContext) => ThemeProvider(
      isDarkMode: isDark,
      child: Builder(
        builder: (themeContext) {
          final modalTheme = ThemeProvider.of(themeContext)!;
          return Dialog(
            backgroundColor: modalTheme.scaffoldColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600),
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Session Analysis Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: modalTheme.headingColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: modalTheme.headingColor),
                        hoverColor: modalTheme.headingColor.withValues(
                          alpha: 0.08,
                        ),
                        highlightColor: modalTheme.headingColor.withValues(
                          alpha: 0.15,
                        ),
                        splashColor: modalTheme.headingColor.withValues(
                          alpha: 0.12,
                        ),
                        onPressed: () => Navigator.pop(themeContext),
                      ),
                    ],
                  ),
                  Divider(color: modalTheme.borderColor),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection(
                            "Session ID",
                            session['_id']?.toString() ?? 'Unknown',
                            modalTheme,
                          ),
                          _buildDetailSection(
                            "User ID",
                            formatUserId(session['userId']),
                            modalTheme,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            "Raw Transcription",
                            session['transcription']?.toString() ??
                                'No transcription available.',
                            modalTheme,
                            isCode: true,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            "AI Feedback Summary",
                            session['aiFeedback']?.toString() ??
                                'AI is still processing or failed to generate feedback.',
                            modalTheme,
                          ),

                          // ---> THE CRASH FIX: Format the JSON beautifully <---
                          Builder(
                            builder: (context) {
                              String feedbackDisplay;
                              if (session['aiFeedback'] is Map) {
                                // If it's a JSON Object, format it with nice indents!
                                feedbackDisplay = const JsonEncoder.withIndent(
                                  '  ',
                                ).convert(session['aiFeedback']);
                              } else {
                                // Fallback for older string-based records
                                feedbackDisplay =
                                    session['aiFeedback']?.toString() ??
                                    'AI is still processing...';
                              }

                              return _buildDetailSection(
                                "AI Feedback Details",
                                feedbackDisplay,
                                modalTheme,
                                isCode: true,
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _scoreBadge(
                                "Pace",
                                session['paceScore']?.toString() ?? '0',
                                modalTheme.categoryColor('GuidedTask'),
                              ),
                              _scoreBadge(
                                "Clarity",
                                session['clarityScore']?.toString() ?? '0',
                                modalTheme.categoryColor('Script'),
                              ),
                              _scoreBadge(
                                "Energy",
                                session['energyScore']?.toString() ?? '0',
                                Colors.orange,
                              ),
                              _scoreBadge(
                                "Overall",
                                session['overallScore']?.toString() ?? '0',
                                modalTheme.actionColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildDetailSection(
  String title,
  String content,
  dynamic theme, {
  bool isCode = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.headingColor,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: theme.bodyTextColor,
            fontFamily: isCode ? 'monospace' : null,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

Widget _scoreBadge(String label, String score, Color color) {
  return Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          score,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}
