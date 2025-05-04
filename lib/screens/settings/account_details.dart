import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';
import 'package:ntu_library_companion/screens/settings/account_tile.dart';
import 'package:ntu_library_companion/widgets/centered_content.dart';
import 'package:provider/provider.dart';

class AccountDetails extends StatefulWidget {
  const AccountDetails({super.key});

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails> {
  final LibraryService _library = LibraryService();
  late final SettingsProvider _settings = Provider.of<SettingsProvider>(
    context,
  );
  Account? _account;
  bool _alreadyRequested = false;

  Future<void> _getAccount() async {
    if (AuthService.authFailed || _alreadyRequested) return;
    _alreadyRequested = true;
    if (!_settings.loggedIn) return;

    final Account? me = await _library.getMyProfile();

    if (me != null && mounted) {
      setState(() {
        _account = me;
      });
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "The Account Data couldn't be loaded, please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _getAccount();

    return Scaffold(
      appBar: AppBar(),
      body: CenterContent(
        child:
            (_account == null)
                ? Center(child: CircularProgressIndicator.adaptive())
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          spacing: 4.0,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.account_circle_outlined, size: 40),
                            Text(
                              _account!.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _account!.account,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      AccountTile(
                        icon: Icons.cake_outlined,
                        onTap:
                            () => _clipboard(
                              DateFormat("MMM d, y").format(_account!.birthDay),
                            ),
                        name: "Birthday: ",
                        value: DateFormat(
                          "MMM d, y",
                        ).format(_account!.birthDay),
                      ),
                      AccountTile(
                        icon: Icons.school_outlined,
                        onTap: () => _clipboard(_account!.titleName),
                        name: "Study Program: ",
                        value: _account!.titleName,
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Row(
                                spacing: 5,
                                children: [
                                  Icon(Icons.mark_email_read_outlined),
                                  Flexible(
                                    child: Text(
                                      "Registered E-Mail Addresses: ",
                                    ),
                                  ),
                                ],
                              ),
                              ..._account!.email.split(",").map((i) {
                                i = i.trim();
                                return ActionChip(
                                  onPressed: () => _clipboard(i),
                                  avatar: Icon(Icons.mail_outline),
                                  label: Text(i),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Row(
                                spacing: 5,
                                children: [
                                  Icon(Icons.phone),
                                  Flexible(
                                    child: Text("Registered Phone Numbers: "),
                                  ),
                                ],
                              ),
                              ..._account!.phone.split(",").map((i) {
                                i = i.trim();
                                return ActionChip(
                                  onPressed: () => _clipboard(i),
                                  avatar: Icon(Icons.phone_outlined),
                                  label: Text(i),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      AccountTile(
                        icon: Icons.credit_card,
                        onTap: () => _clipboard(_account!.cardNo),
                        name: "Card No.: ",
                        value: _account!.cardNo,
                      ),
                      AccountTile(
                        icon: Icons.code,
                        onTap: () => _clipboard(_account!.uuid),
                        name: "UUID: ",
                        value: _account!.uuid,
                      ),
                      AccountTile(
                        icon: Icons.code,
                        onTap:
                            () => _clipboard(
                              _settings.get("authToken") ?? "Unavailable",
                            ),
                        name: "AuthToken: ",
                        value:
                            "${(_settings.get("authToken") ?? "Unavailable").substring(0, 11)}... <Tap to Copy>",
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  void _clipboard(String i) {
    Clipboard.setData(ClipboardData(text: i));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Copied $i")));
  }
}
