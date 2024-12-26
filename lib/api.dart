import 'dart:convert';
import 'package:awqatalsalah/response.dart';
import 'package:http/http.dart' as http;

class api {
  Future<AdhanResponse> getTimings({required String date, required String lat, required String lon}) async {
    String link = "https://api.aladhan.com/v1/timings/$date?latitude=$lat&longitude=$lon";
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
    }
    catch(e) {
      print("You may not have internet connection");
      throw Exception("No internet connection");
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final result = AdhanResponse.fromJson(jsonData);
      print('Response data: ${response.body}');
      return result;
    }
    else {
      print('Failed to load data. Status code: ${response.statusCode} Info: ${response.body}');
      throw Exception('Failed to load prayer times');
    }
  }
}