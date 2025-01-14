import 'dart:convert';

import 'package:awqatalsalah/Services/response.dart';
import 'package:http/http.dart' as http;

class Api {
  Future<Result<AdhanResponse>> getTimings({
    required String date,
    required String lat,
    required String lon,
    int method = 4,
  }) async {
    String link =
        "https://api.aladhan.com/v1/timings/$date?latitude=$lat&longitude=$lon&method=$method";
    print("Link: $link");
    var url = Uri.parse(link);

    late final http.Response response;
    try {
      response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print("You may not have internet connection");
      return Result.error("No internet connection");
    }

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['data'] == null || jsonData['data']['timings'] == null) {
          return Result.error("Invalid data received from the server");
        }
        final result = AdhanResponse.fromJson(jsonData);
        print('Response data: ${response.body}');
        return Result.success(result);
      } catch (e) {
        print('Error parsing response: $e');
        return Result.error("Failed to parse prayer times");
      }
    } else {
      print(
          'Failed to load data. Status code: ${response.statusCode} Info: ${response.body}');
      return Result.error('Failed to load prayer times: ${response.body}');
    }
  }
}

class Result<T> {
  final T? data;
  final String? error;

  Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);

  factory Result.error(String error) => Result._(error: error);

  bool get isSuccess => data != null;
}
