import 'package:flutter/material.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/screens/settings/account_details.dart';
import 'package:ntu_library_companion/screens/settings/ntu_login_form.dart';
import 'package:ntu_library_companion/screens/settings/setting_tile.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:ntu_library_companion/widgets/confirm_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsProvider _settings = Provider.of<SettingsProvider>(
    context,
  );
  final LibraryService _api = LibraryService();

  @override
  Widget build(BuildContext context) {
    _refreshAccountHolder();
    return CenterContent(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.settings_outlined,
                size: 84,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            Text('Settings', style: TextStyle(fontSize: 24)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 16)),
            (_settings.get("credentials") != null)
                ? SettingTile(
                  name: _settings.get("accountHolder")?.name ?? "Logged in",
                  description: "Tap to view your account",
                  //_get("credentials")["user"],
                  onTap: () async {
                    final bool didAuthenticate = await localAuth(
                      "Display Sensitive Personal Information",
                    );

                    if (!didAuthenticate) return;

                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AccountDetails(),
                        ),
                      );
                    }
                  },
                  child: ElevatedButton(
                    onPressed: _logout,
                    child: Text("Log out"),
                  ),
                )
                : SettingTile(
                  name: "Not logged in",
                  description: "Please log in with your NTU ID",
                  onTap: _loginPrompt,
                  child: ElevatedButton(
                    onPressed: _loginPrompt,
                    child: Text("Log in"),
                  ),
                ),
            ...ListTile.divideTiles(
              context: context,
              tiles: [
                SwitchListTile(
                  title: Text("Enable Notifications"),
                  value: _settings.get('notifications') ?? false,
                  onChanged: null,
                  //(bool value) => _settings.set('notifications', value),
                ),
                SwitchListTile(
                  title: Text("Dark Mode"),
                  value: _settings.get("darkMode") ?? false,
                  onChanged: (bool value) => _settings.set('darkMode', value),
                ),
                ListTile(
                  title: Text("Further Actions"),
                  subtitle: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          prefs.clear();
                          await DefaultCacheManager().emptyCache();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cleared Caches!')),
                          );
                        },
                        child: Text("Clear Caches"),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (_settings.get("authToken") == "") return;

                          _api.logout(_settings.get("authToken"));
                          _settings.set("authToken", "");

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Token deleted!')),
                          );
                        },
                        child: Text("Reset Token"),
                      ),
                    ],
                  ),
                ),

                AboutListTile(
                  applicationVersion: "Version 1.2",
                  applicationIcon: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      16.0,
                    ), // Set the radius for rounded corners
                    child: Image.asset(
                      'assets/images/icon.jpg',
                      width: 96,
                      height: 96,
                    ),
                  ),
                  applicationLegalese: """
Copyright (C) 2025  The NTU Library Companion Authors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.""",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loginPrompt() async {
    Map<String, String>? data = await showDialog(
      context: context,
      builder: (context) => LoginForm(settings: _settings),
    );

    if (data == null) {
      return;
    }

    setState(() {
      AuthService.authFailed = false;
      _settings.set("credentials", data);
    });
  }

  void _logout() async {
    bool deleteToken = await showDialog(
      context: context,
      builder:
          (context) => const ConfirmDialog(
            title: "Log out?",
            content:
                "You are about to be logged out. You will have to enter your Credentials again the next time",
            confirmString: "Log out",
            icon: Icons.logout,
          ),
    );

    if (deleteToken) {
      _settings.set("credentials", null);
      _settings.set("accountHolder", null);
      _settings.set("authToken", "");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Logged out!")));
      }
    }
  }

  void _refreshAccountHolder() async {
    if (_settings.get('accountHolder') is Account) return;

    final authToken = _settings.get("authToken") ?? "";
    final studentId = _settings.get("credentials")?["user"] ?? "";

    if (authToken == "" || studentId == "") return;

    final student = await _api.getMember(
      studentId: studentId,
      authToken: authToken,
    );

    _settings.set("accountHolder", student);
  }
}
