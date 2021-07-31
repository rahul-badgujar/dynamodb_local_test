import 'dart:convert';
import 'package:dynamodb_http_test/utils/response-parsing/response-parsing.dart';
import 'package:http/http.dart' as http;

/// This is a demo database which stores uid and email of user
///
/// Note: please create table on ur local dynamo db before calling this api. (see end of this file for help)
class Api {
  Api._();
  static final instance = Api._();

  static final baseUrl = 'http://dynamodb.alpine.red:8000';

  /// header parameters which are common in all http requests
  static final commonHeaderParams = {
    'Content-Type': 'application/x-amz-json-1.0',
    'Accept-Encoding': 'identity',
    'Authorization':
        'AWS4-HMAC-SHA256 Credential=<Credential>, SignedHeaders=<Headers>, Signature=<Signature>',
  };

  /// Returns data of user having [uid]
  Future<Map?> getUserDataWithUid({required int uid}) async {
    final bodyJson = {
      'TableName': 'users',
      'Key': {
        'uid': {'N': uid.toString()}
      },
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.GetItem',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final item = responseBodyJson['Item'];
      return item == null ? null : parseItemResponse(item);
    }
    throw Exception(
      'Failed to get user data [uid: $uid], StatusCode: ${response.statusCode}',
    );
  }

  Future<Map?> getUserDataWithEmail({required String email}) async {
    final bodyJson = {
      'TableName': 'users',
      'ExpressionAttributeValues': {
        ':email': {'S': email},
      },
      'FilterExpression': 'email = :email',
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.Scan',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final items = (responseBodyJson['Items'] ?? []) as List;
      return items.isEmpty ? null : parseItemResponse(items.first);
    }
    throw Exception(
      'Failed to get user data [email: $email], StatusCode: ${response.statusCode}',
    );
  }

  /// Updates [data] for user having [uid]
  Future<void> addUserData(
      {required int uid,
      required String email,
      required String password,
      required Map data}) async {
    final bodyJson = {
      'TableName': 'users',
      'Item': <dynamic, dynamic>{
        'uid': {'N': uid.toString()},
        'email': {'S': email},
        'password': {'S': password},
        'security-token': {'BOOL': 'false'},
        'json': {'M': data},
      },
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.PutItem',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update user data [uid: $uid], StatusCode: ${response.statusCode}',
      );
    }
  }

  Future<bool> validateCredentials(
      {required String email, required String password}) async {
    final bodyJson = {
      'TableName': 'users',
      'ExpressionAttributeValues': {
        ':email': {'S': email},
        ':password': {'S': password},
      },
      'FilterExpression': 'email = :email and password = :password',
    };
    // define headers for http request
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.Scan',
    };
    // add default header values
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      final items = (responseBodyJson['Items'] ?? []) as List;
      return items.isNotEmpty;
    }
    throw Exception(
      'Failed to get user data [email: $email], StatusCode: ${response.statusCode}',
    );
  }
}
