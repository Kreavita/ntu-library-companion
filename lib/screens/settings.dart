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

  _get(String key) {
    return _settings.get(key);
  }

  void _set(String key, dynamic value) {
    _settings.set(key, value);
  }

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
            (_get("credentials") != null)
                ? SettingTile(
                  name: _get("accountHolder")?.name ?? "Logged in",
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
                  value: _get('notifications') ?? false,
                  onChanged: (bool value) => _set('notifications', value),
                ),
                SwitchListTile(
                  title: Text("Dark Mode"),
                  value: _get("darkMode") ?? false,
                  onChanged: (bool value) => _set('darkMode', value),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Settings saved!')));
                  },
                  child: Text("Save Settings"),
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
      _set("credentials", data);
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
    if (_get('accountHolder') is Account) return;

    final authToken = _get("authToken") ?? "";
    final studentId = _get("credentials")?["user"] ?? "";

    if (authToken == "" || studentId == "") return;

    final student = await _api.getMember(
      studentId: studentId,
      authToken: authToken,
    );

    _set("accountHolder", student);
  }
}
