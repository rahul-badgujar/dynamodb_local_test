/// Parse data from dynamodb response data map
Map parseItemResponse(Map item) {
  final m = item.map((key, value) {
    return MapEntry(key, (value as Map).entries.first.value);
  });
  return m;
}
