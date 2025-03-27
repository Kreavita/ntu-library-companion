import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:ntu_library_companion/api/base_api.dart';
import 'package:ntu_library_companion/model/auth_result.dart';
import 'package:ntu_library_companion/model/settings_provider.dart';

class AuthService {
  static bool authFailed = false;
  static Completer<String?>? _tokenCompleter;
  static DateTime _lastAuthSuccess = DateTime(1970);

  final SettingsProvider settings;

  AuthService({required this.settings});

  /// Wrapper for `_getToken` to prevent concurrent login requests and
  /// simplify setting the authFailed flag
  Future<String?> getToken({void Function(AuthResult res)? onResult}) async {
    if (_tokenCompleter != null) {
      // Wait for the ongoing authentication to complete
      return await _tokenCompleter!.future;
    }

    _tokenCompleter = Completer<String?>();
    final String? token;

    try {
      token = await _getToken(onResult: onResult);
      _tokenCompleter!.complete(token);
    } catch (e) {
      rethrow;
    } finally {
      _tokenCompleter = null;
    }

    authFailed = (token == null);
    return token;
  }

  Future<String?> _getToken({void Function(AuthResult res)? onResult}) async {
    if (settings.get("credentials") == null) {
      return null;
    }
    try {
      print("trying authToken...");
      String? authToken = await _getTokenHelper();
      if (authToken != null) {
        return authToken;
      }

      print("trying session...");
      authToken = await _getTokenHelper(invalidToken: true);
      if (authToken != null) {
        return authToken;
      }

      print("trying user/pass...");
      return await _getTokenHelper(
        invalidSess: true,
        invalidToken: true,
        onResult: onResult,
      );
    } on http.ClientException catch (e) {
      print("Got ClientException: $e");

      if (onResult != null) {
        onResult(
          AuthResult(
            type: AuthResType.networkError,
            message:
                "Failed to communicate with library services, is your Internet Connection working?",
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _getTokenHelper({
    bool invalidToken = false,
    bool invalidSess = false,
    void Function(AuthResult res)? onResult,
  }) async {
    final creds = settings.get("credentials");

    if (invalidSess) {
      // get Session from NTU Login
      creds["ntuSession"] =
          await loginToNtu(user: creds["user"], pass: creds["pass"]) ?? "";
    }

    if (creds["ntuSession"] == "") {
      // Failed to get Session
      if (onResult != null) {
        onResult(
          AuthResult(
            type: AuthResType.ntuAuthFail,
            message: "Failed to login at NTU! Did you change your password?",
          ),
        );
      }
      return null;
    }

    String? authToken = settings.get("authToken");

    if (invalidToken) {
      authToken = await _authAtSmsWithNtuSession(creds["ntuSession"]);
      settings.set("authToken", authToken ?? "");

      if (authToken == null || authToken == "") {
        // Failed to get AuthToken, should regenerate Session
        creds["ntuSession"] = "";
        settings.set("credentials", creds);

        if (onResult != null) {
          onResult(
            AuthResult(
              type: AuthResType.libraryAuthFail,
              message: "Could not login to Library with your NTU session!",
            ),
          );
        }
        return null;
      }
    }

    if (authToken == null || authToken == "") {
      if (onResult != null) {
        onResult(AuthResult(type: AuthResType.invalidToken));
      }
      return null;
    }

    if (DateTime.now().difference(_lastAuthSuccess).inMinutes < 30) {
      print("found fresh token, skipping verification");
      return authToken;
    }

    // Test Token
    final resp = await request(
      method: Method.get,
      uri: Endpoint.myAccount.uri(
        params: {"timestamp": "${DateTime.now().millisecondsSinceEpoch}"},
      ),
      headers: {"authToken": authToken},
    );

    if (resp.statusCode != 200) {
      settings.set("authToken", "");
      if (onResult != null) {
        onResult(
          AuthResult(
            type: AuthResType.libraryAuthFail,
            message: "Library Services Error! Could not verify login",
          ),
        );
      }
      return null;
    }

    _lastAuthSuccess = DateTime.now();

    return authToken;
  }

  /// Use a session key `sess` from the SSO-1.3 System of NTU to authenticate
  /// with the SMS System and return the `authToken`
  Future<String?> _authAtSmsWithNtuSession(String sess) async {
    // Create jSession and create server state
    final jSessionId = (await _makeJSessionId())!;
    await request(
      method: Method.get,
      uri: Endpoint.sso.uri(params: {"sess": sess}),
      headers: {"Cookie": "JSESSIONID=$jSessionId"},
    );

    //final loginJspResp = , _printResponse(loginJspResp);

    // final req1 = http.Request("GET", loginUri);
    // req1.followRedirects = false;
    // req1.headers["Cookie"] = "JSESSIONID=$_jSessionId";
    // final sessResp = await _client.send(req1);
    final authUri = Endpoint.auth.uri(params: {"sess": sess});

    final authResp = await request(
      method: Method.get,
      uri: authUri,
      headers: {"Cookie": "JSESSIONID=$jSessionId"},
    );

    //_printResponse(authResp);

    if (authResp.statusCode != 302) {
      return null;
    }

    return RegExp(
      r'authToken=([^&]+)',
    ).firstMatch(authResp.headers["location"] ?? "")?[1];
  }

  Future<String?> loginToNtu({user, pass}) async {
    final phpSessId = await _makePhpSession();

    final resp = await request(
      method: Method.post,
      uri: Endpoint.ntuP1.uri(),
      headers: {
        'Cookie': "PHPSESSID=$phpSessId",
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      formData: {"user": user, "pass": pass, "Submit": "登入"},
    );

    if (resp.statusCode == 200) {
      return null; // actually just means wrong password
    }

    return RegExp(
      r"sess=([a-zA-Z0-9]+)",
    ).firstMatch(resp.headers["location"] ?? "")?[1];
  }

  Future<String?> _makePhpSession() async {
    final p6Resp = await request(
      method: Method.get,
      uri: Endpoint.ntuP6.uri(
        params: {"url": "https://my.ntu.edu.tw/portal/portal.aspx"},
      ),
    );

    var phpSessId =
        RegExp(
          r"PHPSESSID=([^;]+)",
        ).firstMatch(p6Resp.headers["set-cookie"]!)![1];

    await request(
      method: Method.get,
      uri: Endpoint.ntuP1.uri(),
      headers: {"Cookie": "PHPSESSID=$phpSessId"},
    );

    return phpSessId;
  }

  Future<String?> _makeJSessionId() async {
    final response = await http.get(
      Endpoint.sso.uri(
        params: {
          "forward": "1",
          "linkFrom":
              "http://sms.lib.ntu.edu.tw/rest/ntu/auth/user/authentication",
        },
      ),
    );
    return RegExp(
      r"JSESSIONID=([^;]+)",
    ).firstMatch(response.headers["set-cookie"] ?? "")?[1];
  }
}
