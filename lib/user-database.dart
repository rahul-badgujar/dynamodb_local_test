import 'dart:convert';
import 'package:http/http.dart' as http;

/// This is a demo database which stores uid and email of user
///
/// Note: please create table on ur local dynamo db before calling this api. (see end of this file for help)
class UserDatabase {
  UserDatabase._();
  static final instance = UserDatabase._();

  static final baseUrl = 'http://localhost:8000';

  /// header parameters which are common in all http requests
  final commonHeaderParams = {
    'Content-Type': 'application/x-amz-json-1.0',
    'Accept-Encoding': 'identity',
    'Authorization':
        'AWS4-HMAC-SHA256 Credential=<Credential>, SignedHeaders=<Headers>, Signature=<Signature>',
  };

  /// Returns 'json data' for value associated with key
  ///
  /// If key is not present, empty json is returned
  Future<Map> getValue(String key) async {
    final bodyJson = {
      'TableName': 'users',
      'Key': {
        'uid': {'N': key}
      }
    };
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.GetItem',
    };
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseBody = response.body;
      final responseBodyJson = jsonDecode(responseBody);
      return responseBodyJson;
    }
    throw Exception(
      'Failed to getValue($key), StatusCode: ${response.statusCode}',
    );
  }

  /// Adds [value] data for [key]
  ///
  /// If key not exists already, new data row is created
  ///
  /// If key already exists, then data value is updated with new details provided with [value]
  Future<void> putValue(String key, String value) async {
    final bodyJson = {
      'TableName': 'users',
      'Item': {
        'uid': {'N': key},
        'email': {'S': value}
      }
    };
    final headers = <String, String>{
      'X-Amz-Target': 'DynamoDB_20120810.PutItem',
    };
    headers.addAll(commonHeaderParams);

    final response = await http.post(
      Uri.parse('$baseUrl'),
      body: jsonEncode(bodyJson),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to putValue($key, $value), StatusCode: ${response.statusCode}',
      );
    }
  }
}

/*
! paste the following code in editor of web shell and execute to create user table

var params={
    TableName: 'users',
    KeySchema: [       
        { AttributeName: "uid", KeyType: "HASH"},  
    ],
    AttributeDefinitions: [       
        { AttributeName: "uid", AttributeType: "N" },
    ],
    ProvisionedThroughput: {       
        ReadCapacityUnits: 10, 
        WriteCapacityUnits: 10
    }
};

dynamodb.createTable(params, function(err, data){
    if(err) {
        console.log('Error', err);
    } else {
        console.log('Success: ', data);
    }
});


*/