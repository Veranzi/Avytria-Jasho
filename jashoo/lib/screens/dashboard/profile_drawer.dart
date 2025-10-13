import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  bool _showAllSkills = false;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final gamificationProvider = context.watch<GamificationProvider>();
    final user = context.watch<UserProvider>().profile;
    final isEnglish = localeProvider.languageCode == 'en';

    return Drawer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 700;
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile image - separate from header, left-aligned
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: isSmallScreen ? 28 : 32,
                      backgroundColor: const Color(0xFF10B981),
                      child: Icon(Icons.person, size: isSmallScreen ? 36 : 42, color: Colors.white),
                    ),
                  ),
                  
                  // Name and work info - separate from image
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16.0 : 18.0,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        if ((user?.skills ?? []).isNotEmpty) ...[
                          Wrap(
                            spacing: isSmallScreen ? 4 : 6,
                            runSpacing: isSmallScreen ? 4 : 6,
                            children: [
                              for (final skill in (user!.skills)
                                  .take(_showAllSkills ? user.skills.length : 1))
                                Chip(
                                  label: Text(skill, style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  side: const BorderSide(color: Color(0xFF10B981)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                                ),
                              if (!_showAllSkills && user.skills.length > 1)
                                TextButton(
                                  onPressed: () => setState(() => _showAllSkills = true),
                                  child: Text('Show all', style: TextStyle(fontSize: isSmallScreen ? 12 : 13)),
                                ),
                              if (_showAllSkills && user.skills.length > 1)
                                TextButton(
                                  onPressed: () => setState(() => _showAllSkills = false),
                                  child: Text('Show fewer', style: TextStyle(fontSize: isSmallScreen ? 12 : 13)),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        const Divider(),
                      ],
                    ),
                  ),

                  // Badges section
                  if (gamificationProvider.badges.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Badges',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14.0 : 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          SizedBox(
                            height: isSmallScreen ? 70 : 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: gamificationProvider.badges.length,
                              separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 6 : 8),
                              itemBuilder: (_, i) {
                                final badge = gamificationProvider.badges[i];
                                return Container(
                                  width: isSmallScreen ? 140 : 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.emoji_events, color: Colors.amber, size: isSmallScreen ? 18 : 20),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              badge.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 11 : 12,
                                              ),
                                            ),
                                            Text(
                                              badge.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],

                  // Community
                  ListTile(
                    leading: Icon(Icons.group, color: const Color(0xFF10B981), size: isSmallScreen ? 22 : 24),
                    title: Text("Community", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/community');
                    },
                  ),

                  // Jobs Marketplace
                  ListTile(
                    leading: Icon(Icons.work, color: Colors.orange, size: isSmallScreen ? 22 : 24),
                    title: Text("Jobs Marketplace", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/jobs');
                    },
                  ),

                  // Update Profile
                  ListTile(
                    leading: Icon(Icons.person_outline, color: Colors.teal, size: isSmallScreen ? 22 : 24),
                    title: Text("Update Profile", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profileUpdate');
                    },
                  ),

                  // Change Password
                  ListTile(
                    leading: Icon(Icons.lock, color: Colors.deepPurple, size: isSmallScreen ? 22 : 24),
                    title: Text("Change Password", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/changePassword');
                    },
                  ),

                  // Help
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.green, size: isSmallScreen ? 22 : 24),
                    title: Text("Help & Support", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/help');
                    },
                  ),

                  const Divider(),

                  // Language switch
                  SwitchListTile(
                    secondary: Icon(Icons.language, color: const Color(0xFF10B981), size: isSmallScreen ? 22 : 24),
                    title: Text("Language", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    subtitle: Text(
                      isEnglish ? 'English' : 'Swahili',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                    ),
                    value: isEnglish,
                    onChanged: (val) {
                      final newCode = val ? 'en' : 'sw';
                      context.read<LocaleProvider>().setLanguage(newCode);
                    },
                  ),

                  // Logout
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red, size: isSmallScreen ? 22 : 24),
                    title: Text("Logout", style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/logout');
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
