import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'resources_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  bool _isDarkMode = false;

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 72;
  static const Duration _animDuration = Duration(milliseconds: 200);

  final List<Widget> _screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const ResourcesScreen(),
    const Center(
      child: Text("AI Logs Screen - Coming Soon",
          style: TextStyle(fontSize: 18, color: Colors.grey)),
    ),
  ];

  Color get _sidebarColor => _isDarkMode ? AppTheme.darkSidebar : AppTheme.accentColor;
  Color get _bodyColor =>
      _isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundColor;
  Color get _topBarColor =>
      _isDarkMode ? AppTheme.darkSurface : Colors.white;
  Color get _topBarText =>
      _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _topBarBorder =>
      _isDarkMode ? AppTheme.darkBorder : Colors.grey.shade200;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return ThemeProvider(
      isDarkMode: _isDarkMode,
      child: Scaffold(
        backgroundColor: _bodyColor,
        appBar: !isDesktop
            ? AppBar(
                backgroundColor: _sidebarColor,
                title: Row(
                  children: [
                    Image.asset('assets/images/whitelogo.png',
                        height: 36, width: 36, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Text("iSpeak Admin",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: Icon(
                        _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white),
                    onPressed: () =>
                        setState(() => _isDarkMode = !_isDarkMode),
                  ),
                ],
              )
            : null,
        drawer: !isDesktop ? _buildDrawer() : null,
        body: Row(
          children: [
            if (isDesktop) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop) _buildTopBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: _animDuration,
      width: _isSidebarExpanded ? _expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sidebarColor.withOpacity(0.95),
            _sidebarColor.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                setState(() => _isSidebarExpanded = !_isSidebarExpanded),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: _isSidebarExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  // Logo — always visible
                  Image.asset(
                    'assets/images/whitelogo.png',
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                  if (_isSidebarExpanded)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 186,
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "iSpeak Admin",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.menu,
                                  color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _navItem(Icons.dashboard, "Dashboard", 0),
          _navItem(Icons.people, "Users", 1),
          _navItem(Icons.library_books, "Resources", 2),
          _navItem(Icons.analytics, "AI Logs", 3),

          const Spacer(),

          _buildModernDarkModeToggle(),

          SizedBox(height: _isSidebarExpanded ? 20 : 12),
        ],
      ),
    );
  }

  Widget _buildModernDarkModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isDarkMode = !_isDarkMode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 44,
              padding: EdgeInsets.symmetric(
                  horizontal: _isSidebarExpanded ? 12.0 : 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.04)
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                      color: Colors.amber[300],
                      size: 16,
                    ),
                  ),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isDarkMode ? "Dark Mode" : "Light Mode",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isDarkMode
                                ? "Switch to light mode"
                                : "Switch to dark mode",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    final bool active = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: _animDuration,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(
                  horizontal: _isSidebarExpanded ? 12.0 : 6.0),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: active
                    ? Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      color: active ? Colors.white : Colors.white70, size: 16),
                  if (_isSidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white70,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _topBarColor,
        border: Border(bottom: BorderSide(color: _topBarBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Admin Control Center",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _topBarText,
              letterSpacing: -0.3,
            ),
          ),
          
          // --- THE NEW ADMIN DROPDOWN MENU ---
          Theme(
            data: Theme.of(context).copyWith(
              // Styles the popup menu background
              popupMenuTheme: PopupMenuThemeData(
                color: _isDarkMode ? AppTheme.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _isDarkMode ? AppTheme.darkBorder : Colors.grey.shade200),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50), // Drops the menu neatly below the icon
              tooltip: 'Admin Account',
              onSelected: (value) {
                // Here is where we handle the clicks!
                if (value == 'logout') {
                  // TODO: Clear local storage/token and go to Login Screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logging out...')),
                  );
                } else if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Settings coming soon!')),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // 1. Admin Info Header
                PopupMenuItem<String>(
                  enabled: false, // Make this part unclickable, it's just for info
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'admin@ispeak.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                
                // 2. Settings Option
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: _isDarkMode ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 12),
                      Text('My Profile', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
                
                // 3. Logout Option
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              // The shield icon that triggers the menu
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 18,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _sidebarColor.withOpacity(0.95),
              _sidebarColor.withOpacity(0.85),
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/whitelogo.png',
                        height: 36, width: 36, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    const Text(
                      "iSpeak Admin",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            _drawerItem(Icons.dashboard, "Dashboard", 0),
            _drawerItem(Icons.people, "Users", 1),
            _drawerItem(Icons.library_books, "Resources", 2),
            _drawerItem(Icons.analytics, "AI Logs", 3),
            const Spacer(),
            ListTile(
              leading: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white70),
              title: Text(_isDarkMode ? "Light Mode" : "Dark Mode",
                  style: const TextStyle(color: Colors.white70)),
              onTap: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}