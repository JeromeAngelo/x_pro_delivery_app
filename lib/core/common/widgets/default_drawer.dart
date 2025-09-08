import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class DefaultDrawer extends StatefulWidget {
  const DefaultDrawer({super.key});

  @override
  State<DefaultDrawer> createState() => _DefaultDrawerState();
}

class _DefaultDrawerState extends State<DefaultDrawer> {
  late final AuthBloc _authBloc;
  String? _userName;
  String? _userEmail;
  String? _userAvatar;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      final userData = jsonDecode(storedData);
      final userId = userData['id'];

      setState(() {
        _userName = userData['name'];
        _userEmail = userData['email'];
        _userAvatar = userData['avatar']; // If available in stored data
      });

      if (userId != null) {
        debugPrint('🔄 Loading user data for drawer: $userId');
        _authBloc.add(LoadUserByIdEvent(userId));
      }
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is UserByIdLoaded) {
                setState(() {
                  _userName = state.user.name;
                  _userEmail = state.user.email;
                  _userAvatar = state.user.profilePic;
                });
              }
            },
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                child:
                    _userAvatar != null && _userAvatar!.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            _userAvatar!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default_user.png',
                              );
                            },
                          ),
                        )
                        : Image.asset('assets/images/default_user.png'),
              ),
              accountName: Text(
                _userName ?? 'Loading...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              accountEmail: Text(
                _userEmail != null ? '@$_userEmail' : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => context.go('/homepage'),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('My Performance'),
            onTap: () {
              context.go('/user-performance');
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_circle),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Server Address'),
                Text(
                  'https://delivery-app.winganmarketing.com',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.app_settings_alt),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('App Version'), Text('1.0.0')],
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('App Logs'),
            onTap: () {
              context.go('/app-logs');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              _authBloc.add(const SignOutEvent());
              context.go('/sign-in');
            },
          ),
        ],
      ),
    );
  }
}
