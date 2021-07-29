import 'package:dynamodb_http_test/dynamodb_http_test.dart'
    as dynamodb_http_test;

/// This is a sample test application to test dynamo db with http calls.
/// This calls dynamo db api on localhost:8000.
/// For sample, this app fascilates key-value features like getValue(), putValue() for now.
/// For example purpose, the key in this app is uid and value here is email.
/// Note that key can be anything and value can also be anything (including complex modelled data, more than one fields)
///
void main(List<String> arguments) {
  dynamodb_http_test.run();
}
