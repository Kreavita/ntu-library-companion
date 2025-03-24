import 'dart:convert';

import 'package:http/http.dart' as http;

final httpClient = http.Client();

enum Method { get, post, put, update, delete }

extension MethodEx on Method {
  String get name {
    return toString().split('.').last.toUpperCase();
  }
}

enum Endpoint {
  // NTU auth (implemented)
  auth("/rest/ntu/auth/user/authentication", 0),

  // Basic

  // takes 800ms, use with ?timestamp
  myProfile("/rest/member/user/accounts/myProfile", 0),
  myBookings("/rest/council/user/bookings", 0),

  // Council - User

  // takes 800ms, use with ?timestamp
  myAccount("/rest/council/user/memberAccounts/myAccount", 0),
  violationsPager("/rest/council/user/bookingViolationDetails/pager", 0),
  suspensionsPager("/rest/council/user/suspensionRecords/pager", 0),
  //Cates
  categoryPager("/rest/council/user/resourceCates/pager", 0),
  branchesPager("/rest/admin/common/branchs/pager", 0),
  // https://sms.lib.ntu.edu.tw/rest/council/user/bookings/pager?queryString={"status":"Y,E,U,L,I"}&pagerString={"pageSize":-1,"sortColumnName":"bookingStartDate"}&bookingStartDate=2025-03-22&timeStamp=1742662402564
  reservationsPager("/rest/council/user/bookings/pager", 0),
  // Room details
  availRooms("rest/council/user/resourceAndBookings/available", 0),

  catAvail(
    "/rest/council/common/resourceAndBookings/currentAvailable/count",
    0,
  ),
  catTotal("/rest/council/common/resourceAndBookings/count", 0),

  sso("login.jsp", 1),

  ntuP1("/p/s/login2/p1.php", 2),
  ntuP6("/p/s/login2/p6.php", 2);

  static final List<String> _authorities = [
    "sms.lib.ntu.edu.tw",
    "sso.lib.ntu.edu.tw",
    "web2.cc.ntu.edu.tw",
  ];

  final String _path;
  final int _autIdx;

  const Endpoint(this._path, this._autIdx);

  Uri uri({Map<String, dynamic>? params}) =>
      Uri.https(_authorities[_autIdx], _path, params);
}

Future<http.StreamedResponse> request({
  required Method method,
  required Uri uri,
  Map<String, String>? formData,
  Map<String, dynamic>? json,
  Map<String, String>? headers,
}) async {
  final req = http.Request(method.name, uri);
  req.headers.addAll(headers ?? {});
  req.followRedirects = false;

  if (formData != null) {
    req.bodyFields = formData;
  } else if (json != null) {
    req.body = jsonEncode(json);
    req.headers["Content-Type"] = "application/json";
  }

  return await httpClient.send(req);
}

Future<String> printStreamedResp(http.StreamedResponse resp) async {
  final String body = await resp.stream.bytesToString();
  final dbgStr =
      ("\nResponse for: '${resp.request?.url}'\n"
          "---------\n"
          "Code: ${resp.statusCode}\n"
          "Req-Headers: ${resp.request?.headers}\n"
          "Resp-Headers: ${resp.headers}\n"
          "Body: $body"
          "---------\n");

  print(dbgStr);
  return body;
}
