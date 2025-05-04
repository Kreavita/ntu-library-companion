import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/auth_service.dart';
import 'package:ntu_library_companion/api/base_api.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/api_result.dart';
import 'package:ntu_library_companion/model/auth_result.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/booking_stats.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/conference_room.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryService {
  static AuthService? _auth;
  static setAuth(AuthService auth) => _auth = auth;

  Future<ApiResult> get({
    required Endpoint endpoint,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool log = false,
  }) async {
    final resp = await request(
      method: Method.get,
      uri: endpoint.uri(params: params),
      headers: headers,
    );
    return ApiResult(
      body:
          (log)
              ? await printStreamedResp(resp)
              : await resp.stream.bytesToString(),
      statusCode: resp.statusCode,
    );
  }

  Future<ApiResult> _authenticated(
    Future<ApiResult> Function(String authToken) request, {
    void Function(AuthResult)? onResult,
  }) async {
    if (_auth == null) throw StateError("Error: AuthService not initialized!");

    String? authToken = _auth?.settings.get("authToken");
    DateTime now = DateTime.now();
    DateTime tokenBirth = DateTime.parse(_auth?.settings.get("authToken_date"));

    if (authToken != null && now.isBefore(tokenBirth.add(Duration(hours: 2)))) {
      // worth a try
      ApiResult res = await request(authToken);
      if (res.statusCode == 200) {
        return res;
      }
    }

    authToken = await _auth?.getToken(onResult: onResult);
    if (authToken == null) {
      return ApiResult(body: "Unauthorized", statusCode: 401);
    }

    return await request(authToken);
  }

  Future<ApiResult> _cachedRequest(
    String cacheKey,
    Future<ApiResult> Function() request, {
    ignoreCache = false,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime lastValidCache = DateTime.parse(
      prefs.getString("api_${cacheKey}_date") ?? "19700101",
    );

    int statusCode = 200;

    if (lastValidCache.isBefore(DateTime.now().add(Duration(days: -7))) ||
        ignoreCache) {
      final result = await request();
      if (result.statusCode == 200) {
        prefs.setString("api_${cacheKey}_date", DateTime.now().toString());
        prefs.setString("api_$cacheKey", result.body);
      }
      return result;
    } else if (lastValidCache.isBefore(
      DateTime.now().add(Duration(days: -1)),
    )) {
      request().then((result) {
        if (result.statusCode != 200) return;

        prefs.setString("api_${cacheKey}_date", DateTime.now().toString());
        prefs.setString("api_$cacheKey", result.body);
      });
    }

    return ApiResult(
      body: prefs.getString("api_$cacheKey")!,
      statusCode: statusCode,
    );
  }

  /// Get Available Rooms for Booking
  /// https://sms.lib.ntu.edu.tw/rest/council/user/resourceAndBookings/available?bookingStartDate=2025/03/27 16:30:00&bookingEndDate=2025/03/27 17:30:00&cateId=cateId
  Future<ApiResult> getAvailRooms(
    Category cate,
    DateTime date,
    TimeOfDay start,
    TimeOfDay end,
  ) async {
    String fmtDate = DateFormat("y/MM/dd").format(date);
    return _authenticated(
      (authToken) => get(
        endpoint: Endpoint.availRooms,
        headers: {"authToken": authToken},
        params: {
          "bookingStartDate": "$fmtDate ${formatTime(start)}:00",
          "bookingEndDate": "$fmtDate ${formatTime(end)}:00",
          "cateId": cate.catId,
        },
      ),
    );
  }

  Future<Account?> getMember({required String studentId}) async {
    final resp = await _authenticated((authToken) async {
      final resp = await request(
        method: Method.get,
        uri: Uri.parse(
          "https://sms.lib.ntu.edu.tw/rest/council/user/memberAccounts/param/$studentId",
        ),
        headers: {"authToken": authToken},
      );
      return ApiResult(
        body: await resp.stream.bytesToString(),
        statusCode: resp.statusCode,
      );
    });

    if (resp.statusCode != 200) return null;

    final List<dynamic> userResults = resp.asJson<List>(fallback: []);
    if (userResults.isEmpty) return null;

    return Account.fromJson(accountData: userResults.first!);
  }

  Future<Account?> getMyProfile() async {
    final ApiResult res = await _authenticated(
      (authToken) => get(
        endpoint: Endpoint.myProfile,
        params: {'timeStamp': "${DateTime.now().millisecondsSinceEpoch}"},
        headers: {"authToken": authToken},
      ),
    );

    if (res.statusCode != 200) return null;

    final json = res.asJson<Map<String, dynamic>?>(fallback: null);
    if (json == null) return null;

    // (uuid, account, email, name, status, titleId, titleName, validEndDate)
    return Account.fromJson(profileData: json);
  }

  /// https://sms.lib.ntu.edu.tw/rest/council/user/bookings/pager?queryString={"status":"Y,E,U,L,I"}&pagerString={"pageSize":-1,"sortColumnName":"bookingStartDate"}&bookingStartDate=2025-03-22&timeStamp=1742662402564
  Future<List<Booking>> getBookings({
    bool includePast = false,
    bool ignoreCache = true,
  }) async {
    final now = DateTime.now();
    Map<String, dynamic> params = {
      'queryString': '{"status":"Y,E,U,L,I"}',
      'pagerString':
          '{"pageSize":-1,"sortColumnName":"-bookingStartDate,-createDate"}',
      'bookingStartDate': DateFormat("yyyy-MM-dd").format(now),
      'timeStamp': "${now.millisecondsSinceEpoch}",
    };
    if (includePast) {
      params['queryString'] = '{"status":"Z,O,F,T,Y,L,U,C,I,E"}';
      params['bookingStartDate'] = "1970-01-01";
    }
    final ApiResult res = await _cachedRequest(
      "mybookings_${includePast ? 'all' : 'now'}",
      () => _authenticated(
        (authToken) => get(
          endpoint: Endpoint.reservationsPager,
          params: params,
          headers: {"authToken": authToken},
        ),
      ),
      ignoreCache: ignoreCache,
    );

    if (res.statusCode != 200) return [];

    final jsonObj = res.asJson<Map>(fallback: {"resultList": []});

    return (jsonObj["resultList"] as List)
        .map((json) => Booking.fromJson(bookingsJson: json))
        .toList();
  }

  Future<Map<String, Category>> getCategories({
    void Function(AuthResult)? onResult,
  }) async {
    final Map<String, Category> cates = {};

    final ApiResult res = await _cachedRequest(
      "categories",
      () async => await _authenticated(
        (authToken) => get(
          endpoint: Endpoint.categoryPager,
          headers: {"authToken": authToken},
          params: {
            'queryString': '{"status":"Y"}',
            'pagerString': '{"pageSize":-1}',
          },
        ),
        onResult: onResult,
      ),
    );

    if (res.statusCode != 200) {
      return cates;
    }

    final jsonObj = res.asJson<Map<String, dynamic>>(
      fallback: {"resultList": []},
    );

    for (final cate in jsonObj["resultList"] as List) {
      cates[cate["cateId"]] = Category.fromJson(cate);
    }
    return cates;
  }

  /// Post a room reservation to the library services
  Future<ApiResult> postBooking(
    Account host,
    Room room,
    TimeOfDay bookingStart,
    TimeOfDay bookingEnd,
    DateTime date,
    List<Student> participants,
  ) async {
    String dateFmt = DateFormat("y/MM/dd").format(date);
    return _authenticated((authToken) async {
      final resp = await request(
        method: Method.post,
        uri: Endpoint.myBookings.uri(),
        json: {
          "hostId": host.uuid,
          "hostName": host.name,
          "bookingStartDate": "$dateFmt ${formatTime(bookingStart)}:00",
          "bookingEndDate": "$dateFmt ${formatTime(bookingEnd)}:00",
          "mainResourceId": room.rid,
          "bookingParticipantIdList": participants.map((p) => p.uuid).toList(),
          "userCount": "${participants.length + 1}",
        },
        headers: {"authToken": authToken},
      );
      return ApiResult(
        body: await resp.stream.bytesToString(),
        statusCode: resp.statusCode,
      );
    });
    // {"hostId":"uuid","hostName":"Name","bookingStartDate":"2025/03/25 16:30:00","bookingEndDate":"2025/03/25 17:00:00","mainResourceId":"rid","bookingParticipantIdList":["uuid_1","uuid_2"],"userCount":3}
  }

  /// Get a booked room by its booking id (bid). Returns null if the request fails
  Future<Booking?> getBooking(String bid) async {
    final bookingsWithPathVar = Uri.parse(
      "${Endpoint.myBookings.uri().toString()}/$bid",
    );
    final bookingReq = await _authenticated((authToken) async {
      final resp = await request(
        method: Method.get,
        uri: bookingsWithPathVar,
        headers: {"authToken": authToken},
      );
      return ApiResult(
        body: await resp.stream.bytesToString(),
        statusCode: resp.statusCode,
      );
    });

    if (bookingReq.statusCode != 200) {
      return null;
    }

    return Booking.fromJson(
      bookingJson: bookingReq.asJson<Map<String, dynamic>?>(fallback: null),
    );
  }

  Future<bool> cancelBooking(String bid) async {
    /// PUT rest/council/user/bookings/{{bid}}/status/cancel
    final uri = Uri.parse(
      "${Endpoint.myBookings.uri().toString()}/$bid/status/cancel",
    );

    final bookingReq = await _authenticated((authToken) async {
      final resp = await request(
        method: Method.put,
        uri: uri,
        headers: {"authToken": authToken},
      );
      return ApiResult(body: "", statusCode: resp.statusCode);
    });

    return bookingReq.statusCode == 200;
  }

  Future<bool> returnBooking(String bid) async {
    ///PUT rest/council/user/bookings/{{bid}}/status/useFinish
    final uri = Uri.parse(
      "${Endpoint.myBookings.uri().toString()}/$bid/status/useFinish",
    );
    final bookingReq = await _authenticated((authToken) async {
      final resp = await request(
        method: Method.put,
        uri: uri,
        headers: {"authToken": authToken},
      );
      return ApiResult(body: "", statusCode: resp.statusCode);
    });

    return bookingReq.statusCode == 200;
  }

  Future<List<BookingStats>> getBookingStats(
    Student user, {
    ignoreCache = true,
  }) async {
    final ApiResult res = await _cachedRequest(
      "bookingStats_${user.uuid}",
      () => _authenticated(
        (authToken) => get(
          endpoint: Endpoint.myBookingStats,
          params: {"userId": user.uuid},
          headers: {"authToken": authToken},
        ),
      ),
      ignoreCache: ignoreCache,
    );

    if (res.statusCode != 200) return [];
    final jsonData = res.asJson<List>(fallback: []);
    return jsonData.map((x) => BookingStats.fromJson(x)).toList();
  }

  /// Log out from the SMS Library System
  Future<bool> logout(String authToken) async {
    final logoutRequest = await request(
      method: Method.delete,
      uri: Endpoint.auth.uri(),
      headers: {'authToken': authToken, 'Content-Type': 'application/json'},
    );
    return logoutRequest.statusCode == 200;
  }

  /// Get Conference Rooms
  /// https://sms.lib.ntu.edu.tw/rest/council/common/conferenceRooms/pager?queryString={"status":"Y","searchableFlag":"Y"}&miscQueryString={"branchId":"4028098173bcaac10173bcc07a670002"}
  Future<List<ConferenceRoom>> getConferenceRooms(Category cate) async {
    final ApiResult res = await _cachedRequest(
      "confRooms",
      () => _authenticated(
        (authToken) => get(
          endpoint: Endpoint.conferenceRoomsPager,
          params: {
            'queryString': '{"status":"Y","searchableFlag":"Y"}',
            'pagerString': '{"pageSize":-1}',
            'miscQueryString': '{"branchId": "${cate.branch.bid}"}',
          },
          headers: {"authToken": authToken},
        ),
      ),
    );

    if (res.statusCode != 200) return [];

    final jsonObj = res.asJson<Map>(fallback: {"resultList": []});

    return (jsonObj["resultList"] as List)
        .map((json) => ConferenceRoom.fromJson(json))
        .toList();
  }

  Future<List<Booking>> getRoomOccupancy(
    ConferenceRoom room,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final ApiResult res = await _authenticated(
      (authToken) => get(
        endpoint: Endpoint.bookingsPager,
        params: {
          'queryString': '{"mainResourceId":"${room.rid}"}',
          'pagerString': '{"pageSize":-1}',
          'miscQueryString':
              '{"bookingStartDate":"${DateFormat("yyyy-MM-dd").format(startDate)}T00:00:00.000Z","bookingEndDate":"${DateFormat("yyyy-MM-dd").format(endDate)}T00:00:00.000Z"}',
        },
        headers: {"authToken": authToken},
      ),
    );

    if (res.statusCode != 200) return [];

    final jsonObj = res.asJson<Map>(fallback: {"resultList": []});

    return (jsonObj["resultList"] as List)
        .map((json) => Booking.fromJson(bookingsJson: json))
        .toList();
  }

  // TODO: generalize for all Categories
  Future<Map<ConferenceRoom, List<Booking>>> getConfRoomBookings(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<String, Category> cates = await getCategories();
    final Category? discRoomMain = cates["0cf0f3a271ba92820171ba92f43f0000"];

    if (discRoomMain == null) return {};

    final List<ConferenceRoom> confRooms = await getConferenceRooms(
      discRoomMain,
    );

    final Map<ConferenceRoom, List<Booking>> confRoomBookings = {};
    // get bookings for all rooms
    for (final room in confRooms) {
      confRoomBookings[room] = await getRoomOccupancy(room, startDate, endDate);
    }

    return confRoomBookings;
  }
}
