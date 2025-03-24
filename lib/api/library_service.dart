import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntu_library_companion/api/base_api.dart';
import 'package:ntu_library_companion/model/account.dart';
import 'package:ntu_library_companion/model/booking.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/model/room.dart';
import 'package:ntu_library_companion/model/student.dart';
import 'package:ntu_library_companion/util.dart';

class LibraryService {
  Future<dynamic> get({
    required Endpoint endpoint,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool json = false,
    bool log = false,
  }) async {
    final resp = await request(
      method: Method.get,
      uri: endpoint.uri(params: params),
      headers: headers,
    );
    if (log) {
      printStreamedResp(resp);
    }
    if (resp.statusCode != 200) {
      if (json) return {"error": resp.statusCode};
      return null;
    }
    final String body = await resp.stream.bytesToString();

    if (json) return jsonDecode(body);
    return body;
  }

  // get avail rooms
  // https://sms.lib.ntu.edu.tw/rest/council/user/resourceAndBookings/available?bookingStartDate=2025/03/27 16:30:00&bookingEndDate=2025/03/27 17:30:00&cateId=cateId

  Future<Account?> getMember({
    required String studentId,
    required String authToken,
  }) async {
    final resp = await request(
      method: Method.get,
      uri: Uri.parse(
        "https://sms.lib.ntu.edu.tw/rest/council/user/memberAccounts/param/$studentId",
      ),
      headers: {"authToken": authToken},
    );

    if (resp.statusCode != 200) {
      return null;
    }

    final List<dynamic> userResults = jsonDecode(
      await resp.stream.bytesToString(),
    );

    if (userResults.isEmpty) {
      return null;
    }

    return Account.fromJson(userResults.first);
  }

  Future<Account?> getMyAccount(String authToken) async {
    final bookingReq = await get(
      endpoint: Endpoint.myAccount,
      params: {'timeStamp': "${DateTime.now().millisecondsSinceEpoch}"},
      headers: {"authToken": authToken},
    );

    if (bookingReq.statusCode != 200) {
      return null;
    }

    final jsonData = jsonDecode(await bookingReq.stream.bytesToString());
    return Account.fromJson(jsonData);
  }

  Future<List<Booking>> getBookings(
    String authToken, {
    bool includePast = false,
  }) async {
    Map<String, dynamic>? params;
    if (!includePast) {
      final now = DateTime.now();
      params = {
        'queryString': '{"status":"Y,E,U,L,I"}',
        'pagerString': '{"pageSize":-1,"sortColumnName":"bookingStartDate"}',
        'bookingStartDate': DateFormat("yyyy-MM-dd").format(now),
        'timeStamp': "${now.millisecondsSinceEpoch}",
      };
    }
    final jsonResp = await get(
      endpoint: Endpoint.reservationsPager,
      json: true,
      params: params,
      headers: {"authToken": authToken},
    );
    return (jsonResp["resultList"] as List)
        .map((json) => Booking.fromJson(bookingsJson: json))
        .toList();
  }

  Future<Map<String, Category>> getCategories(String authToken) async {
    final Map<String, Category> cates = {};

    final resp = await get(
      endpoint: Endpoint.categoryPager,
      headers: {"authToken": authToken},
      params: {
        'queryString': '{"status":"Y"}',
        'pagerString': '{"pageSize":-1}',
      },
      json: true,
    );

    if (resp["error"] != null) {
      return cates;
    }

    for (var cate in resp["resultList"] as List<dynamic>) {
      try {
        Map<String, dynamic> avail = await get(
          endpoint: Endpoint.catAvail,
          params: {"cateId": cate["cateId"]},
          headers: {"authToken": authToken},
          json: true,
        );
        Map<String, dynamic> count = await get(
          endpoint: Endpoint.catTotal,
          params: {"miscQueryString": '{"cateId":"${cate["cateId"]}"}'},
          headers: {"authToken": authToken},
          json: true,
        );
        cates[cate["cateId"]] = Category.fromJson(cate, avail, count);
      } catch (e) {
        print(e);
      }
    }
    return cates;
  }

  Future<Booking?> postBooking(
    Account host,
    Room room,
    TimeOfDay bookingStart,
    TimeOfDay bookingEnd,
    DateTime date,
    List<Student> participants,
    String authToken,
  ) async {
    String dateFmt = DateFormat("y/MM/dd").format(date);
    final bookingReq = await request(
      method: Method.post,
      uri: Endpoint.myBookings.uri(),
      json: {
        "hostId": host.uuid,
        "hostName": host.name,
        "bookingStartDate": "$dateFmt ${formatTime(bookingStart)}:00",
        "bookingEndDate": "$dateFmt ${formatTime(bookingEnd)}:00",
        "mainResourceId	": room.rid,
        "bookingParticipantIdList": participants.map((p) => p.uuid).toList(),
        "userCount": "${participants.length + 1}",
      },
      headers: {"authToken": authToken},
    );

    if (bookingReq.statusCode != 200) {
      return null;
    }
    return Booking.fromJson(
      postBookingJson: jsonDecode(await bookingReq.stream.bytesToString()),
    );
    // {"hostId":"uuid","hostName":"Name","bookingStartDate":"2025/03/25 16:30:00","bookingEndDate":"2025/03/25 17:00:00","mainResourceId":"rid","bookingParticipantIdList":["uuid_1","uuid_2"],"userCount":3}
  }

  Future<Booking?> getBooking(String bid, String authToken) async {
    final bookingsWithPathVar = Uri.parse(
      "${Endpoint.myBookings.uri().toString()}/$bid",
    );
    final bookingReq = await request(
      method: Method.get,
      uri: bookingsWithPathVar,
      headers: {"authToken": authToken},
    );

    if (bookingReq.statusCode != 200) {
      return null;
    }

    final jsonData = jsonDecode(await bookingReq.stream.bytesToString());
    return Booking.fromJson(bookingJson: jsonData);
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
}
