class DynamicRow {
  final String month;
  final DynamicValue values; // Key = column name, value = data

  DynamicRow({required this.month, required this.values});
}

class DynamicValue {
  final Map<String, dynamic>? singleMap;
  final List<Map<String, dynamic>>? listOfMaps;

  DynamicValue.single(this.singleMap) : listOfMaps = null;
  DynamicValue.list(this.listOfMaps) : singleMap = null;

  bool get isSingle => singleMap != null;
  bool get isList => listOfMaps != null;

  Iterable<String> get keys {
    if (isSingle) {
      return singleMap!.keys;
    } else if (isList && listOfMaps!.isNotEmpty) {
      return listOfMaps!.first.keys;
    } else {
      throw Exception("Cannot access 'keys' on an empty list of maps or null data.");
    }
  }

  dynamic operator [](String key) {
    if (isSingle) {
      return singleMap != null ? singleMap![key] : null;
    } else if (isList) {
      if (listOfMaps != null && listOfMaps!.isNotEmpty) {
        return listOfMaps!.first[key];
      } else {
        return null;
      }
    } else {
      throw Exception("DynamicValue does not contain valid data for access.");
    }
  }

  dynamic getValueFromList(int index, String key) {
    if (isList && listOfMaps != null && index >= 0 && index < listOfMaps!.length) {
      return listOfMaps![index][key];
    } else {
      throw Exception("Invalid index or data structure.");
    }
  }
}
