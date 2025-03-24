import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';

class LoginForm extends StatefulWidget {
  final SettingsProvider settings;
  const LoginForm({super.key, required this.settings});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late final AuthService _auth = AuthService(settings: widget.settings);

  String? _username;
  String? _password;
  String? _loginState;
  bool _ongoingRequest = false;

  /// Contact the Auth Server and obtain a ntuSession
  void _login() async {
    if (!_formKey.currentState!.validate() || _ongoingRequest) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _ongoingRequest = true;
    });

    String? ntuSession;

    try {
      ntuSession = await _auth.loginToNtu(pass: _password, user: _username);
    } on ClientException {
      setState(() {
        _ongoingRequest = false;
        _loginState = "Login unsuccessful, network error.";
      });
      return;
    } on HandshakeException {
      setState(() {
        _ongoingRequest = false;
        _loginState = "Login unsuccessful, certificate error.";
      });
      return;
    }

    if (ntuSession == null) {
      setState(() {
        _ongoingRequest = false;
        _loginState = "Login unsuccessful, wrong password";
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop({
          "user": _username ?? "",
          "pass": _password ?? "",
          "ntuSession": ntuSession,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        title: const Text("Login with your NTU Account"),
        icon: const Icon(Icons.login_outlined),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your NTU Student ID';
                  }

                  if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
                    return 'Student ID must start with a letter';
                  }

                  if (value.length < 3 || value.length > 16) {
                    return 'ID Must be 3 to 16 characters';
                  }

                  if (RegExp(r"[@\'\;\,\!\/]").hasMatch(value)) {
                    return 'Invalid characters found';
                  }

                  return null;
                },
                onSaved: (value) {
                  _username = value;
                },
                decoration: const InputDecoration(hintText: "Student ID"),
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your Password';
                  }
                  if (value.length < 5 || value.length > 24) {
                    return "Password must be 5 to 24 Characters";
                  }
                  if (RegExp(r"[\'\\]").hasMatch(value)) {
                    return 'Invalid characters found';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value;
                },
                decoration: const InputDecoration(hintText: "Password"),
                obscureText: true,
              ),
              if (_loginState != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Error: $_loginState",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions:
            !_ongoingRequest
                ? <Widget>[
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context, null);
                      });
                    },
                    child: const Text('Back'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ]
                : [CircularProgressIndicator.adaptive()],
      ),
    );
  }
}
