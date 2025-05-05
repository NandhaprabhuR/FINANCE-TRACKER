import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:moneynest/main.dart'; // Import main.dart to access ThemeProvider

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage; // To store the selected image
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        debugPrint("Profile image selected: ${image.path}");
      } else {
        debugPrint("No image selected");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    debugPrint("Signing out and navigating to login screen");
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      debugPrint("Navigation stack cleared, navigated to /login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF4CAF50),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'No name available',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'No email available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Dark/Light Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Theme Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                          debugPrint("Toggled theme to ${themeProvider.isDarkMode ? 'dark' : 'light'}");
                        },
                        activeColor: const Color(0xFF4CAF50),
                      ),
                      Icon(
                        themeProvider.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        color: const Color(0xFF4CAF50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _signOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE57373),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}