// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// Only for testing
void main(List<String> args) {
  final client = MgrClient(apiKey: 'your_api_key');
  var result = client.request(resource: Resources.inboundCall);

  log('Result: $result');
}

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

  final bool GET;
  final bool POST;
  final bool PUT;
  final bool PATCH;
  final bool DELETE;
  const Resources(
    this.endpoints, {
    this.GET = false,
    this.POST = false,
    this.PUT = false,
    this.DELETE = false,
    // ignore: unused_element_parameter
    this.PATCH = false,
  });

  String endpoint({String ID = ''}) =>
      '$baseURL/${endpoints.replaceFirst('{ID}', ID)}';
}

// Model for successful GET response
class UserResource {
  final String id;
  final String name;
  final String email;
  final Map<String, dynamic> rawData;

  UserResource({
    required this.id,
    required this.name,
    required this.email,
    required this.rawData,
  });

  factory UserResource.fromJson(Map<String, dynamic> json) {
    return UserResource(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      rawData: json,
    );
  }

  @override
  String toString() {
    return 'UserResource(id: $id, name: $name, email: $email)';
  }
}

class MgrClient {
  String apiKey;
  final String accept;
  final String contentType;
  late Map<String, String> header;

  MgrClient({
    required this.apiKey,
    this.contentType = 'application/json',
    this.accept = 'application/json',
  }) {
    setHeader({
      'Authorization': apiKey,
      'Accept': accept,
      'Content-Type': contentType,
    });
  }
  set setApiKey(String apiKey) => this.apiKey = apiKey;
  void setHeader(Map<String, String> header) => this.header = header;

  request({required Resources resource}) {
    return switch (resource) {
      Resources.inboundCall => _post(resource: resource),
      _ => throw Exception('Resource not implemented'),
    };
  }

  _post({required Resources resource}) async {
    final uri = Uri.parse(resource.endpoint()); // Example endpoint
    try {
      final response = await http.post(uri, headers: header);
      final dynamic parsedBody = await _handleResponse(response);

      if (parsedBody is Map<String, dynamic>) {
        return UserResource.fromJson(parsedBody);
        // ignore: curly_braces_in_flow_control_structures
      } else if (parsedBody is List) {
        return parsedBody
            .map((item) => UserResource.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Unexpected response format for GET. Status: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error: ${e.message}");
    }
  }

  _get({required String endpoint}) async {
    final uri = Uri.parse(endpoint);
    try {
      final response = await http.get(uri, headers: header);
      final dynamic parsedBody = await _handleResponse(response);
      // For GET, it's typically a resource object or a list of them.
      // This example assumes a single UserResource.
      if (parsedBody is Map<String, dynamic>) {
        return UserResource.fromJson(parsedBody);
      } else if (parsedBody is List) {
        return parsedBody
            .map((item) => UserResource.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Unexpected response format for GET. Status: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception("Network error: ${e.message}");
    }
  }

  static _handleResponse(http.Response response) {
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
