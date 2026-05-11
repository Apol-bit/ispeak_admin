import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileDialog extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  final Function(String newName, String newEmail) onSave;

  const ProfileDialog({
    super.key,
    required this.adminName,
    required this.adminEmail,
    required this.onSave,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adminName);
    _emailController = TextEditingController(text: widget.adminEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context)!;
    final isDark = theme.isDarkMode;

    return Dialog(
      backgroundColor: theme.scaffoldColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER WITH AVATAR ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, Colors.blueAccent],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.scaffoldColor,
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Admin Profile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.headingColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "ROLE: SUPER ADMIN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.headingColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: theme.borderColor),
                const SizedBox(height: 20),

                // --- EDITABLE FIELDS ---
                Text(
                  "Display Name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: theme.headingColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 16),

                Text(
                  "Email Address",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: theme.headingColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurface : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Email cannot be empty' : null,
                ),
                const SizedBox(height: 24),

                // --- DETAILS CARDS ---
                Text(
                  "System Permissions & Security",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.shield, color: AppTheme.primaryColor, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              "Security Tier",
                              style: TextStyle(fontSize: 11, color: theme.subtleTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Level 1",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.headingColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.verified_user, color: Colors.blue, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              "Access Level",
                              style: TextStyle(fontSize: 11, color: theme.subtleTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Unlimited",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.headingColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // --- SAVE / CANCEL BUTTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: theme.subtleTextColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onSave(
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
