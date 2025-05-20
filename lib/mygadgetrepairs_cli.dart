// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:http/http.dart' as http;

enum Resources {
  userMember('/users/{ID}', GET: true),
  userCollection('/users', GET: true),
  timeClockMember('/timeclock/{ID}', GET: true, PUT: false, DELETE: true),
  timeClockCollection('/timeClock', GET: true),
  taxRateCollection('/taxRates', GET: true, POST: true),
  paymentMethodCollection('/paymentMethods', GET: true),
  info('/info', GET: true),
  rmmAlert('webhook/rmmAlert', GET: false, POST: true),
  inboundCall('webhook/inboundCall', GET: false, POST: true);

  final String baseURL = 'https://api.mygadgetrepairs.com/v1';
  final String endpoints;
  const Resources(
    this.endpoints, {
    bool GET = false,
    bool POST = false,
    bool PUT = false,
    // ignore: unused_element_parameter
    bool PATCH = false,
    bool DELETE = false,
  });

  String endpoint({String ID = ''}) =>
      '$baseURL/${endpoints.replaceFirst('{ID}', ID)}';
}

void doRequest(Resources requestResource) {}

// Model for successful GET response
class UserResource {
  final String id;
  final String name;
  final String email;

  UserResource({required this.id, required this.name, required this.email});

  factory UserResource.fromJson(Map<String, dynamic> json) {
    return UserResource(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  @override
  String toString() {
    return 'UserResource(id: $id, name: $name, email: $email)';
  }
}

class MgrClient {
  final String apiKey;
  final String accept;
  final String contentType;
  final Map<String, String> header;

  MgrClient({
    required this.apiKey,
    this.contentType = 'application/json',
    this.accept = 'application/json',
  }) : header = {
         'Authorization': apiKey,
         'Accept': accept,
         'Content-Type': contentType,
       };

  request() {}
  inboundCall(Resources requestResource) async {
    final uri = Uri.parse(requestResource.endpoint()); // Example endpoint
    try {
      final response = await http.post(uri, headers: header);
      final dynamic parsedBody = await _handleResponse(response);

      if (parsedBody is Map<String, dynamic>) {
        return UserResource.fromJson(parsedBody);
        // ignore: curly_braces_in_flow_control_structures
      } else {
        throw Exception(response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error: ${e.message}");
    }
  }

  _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    void error() =>
        throw Exception(
          'Error code: ${response.statusCode} Response: ${response.body} Error: ${body['error']}',
        );
    return switch (response.statusCode) {
      200 => body,
      400 => error(),
      500 => error(),
      _ => error(),
    };
  }
}
