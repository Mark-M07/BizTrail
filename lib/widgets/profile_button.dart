import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileButton extends StatelessWidget {
  final AuthService _authService = AuthService();

  ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      icon: _buildProfileIcon(user),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.email ?? 'User'),
            subtitle: const Text('View Profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            // TODO: Navigate to profile screen
            break;
          case 'settings':
            // TODO: Navigate to settings screen
            break;
          case 'logout':
            await _authService.signOut();
            break;
        }
      },
    );
  }

  Widget _buildProfileIcon(User? user) {
    if (user?.photoURL != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user!.photoURL!),
        radius: 16,
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          (user?.email?[0] ?? 'U').toUpperCase(),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        radius: 16,
      );
    }
  }
}
