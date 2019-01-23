class Coder {

  String encrypt(String text, String key) {

    final List<int> _keyList = key.codeUnits;

    double _processedKey = 0;
    for (int i in _keyList) _processedKey += i/2;

    final List<int> _tmpList = text.codeUnits;
    final List<double> _processedText = List();
    for (int i in _tmpList) _processedText.add(i.toDouble() * _processedKey);

    return _processedText.join(";");
  }

  String decrypt(String text, String key) {

    final List<int> _keyList = key.codeUnits;

    double _processedKey = 0;
    for (int i in _keyList) _processedKey += i / 2;

    final _tmpText = text.split(";");
    final _processedText = List<int>();
    for (String i in _tmpText) _processedText.add(double.parse(i) ~/ _processedKey);

    return String.fromCharCodes(_processedText);
  }
}