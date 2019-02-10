import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'Password.dart';
import 'package:connectivity/connectivity.dart';

class Database {

  final _passwords = Map<int, Password>();
  bool _useServer;
  final _db = Firestore.instance;
  final _keyForPasswords;
  bool _synchronized;

  Database(this._keyForPasswords);

  void init() {

    _loadSettings();
    if (!_synchronized) {
      Connectivity().checkConnectivity().then((result) {
        if (result != ConnectivityResult.none) {
          // TODO
        }
      });
    }


  }

  void _loadSettings() {

  }

  void _saveSettings() {

  }

  // Got it!
  void _savePasswordsToFile() async => getApplicationDocumentsDirectory().then((path){
    final File file = File("${path.path}/passwords.txt");
    String data = "Divider\n";
    for (Password password in _passwords.values) {
      final i = password;
      i.encryptAllFields(_keyForPasswords);
      data += "${i.title}\n${i.login}\n${i.password}\nDivider\n";
    }
    file.writeAsStringSync(data);
  });

  void _savePasswordsToServer() async {

  }

  void _updatePasswordToServer(int id) async {

  }

  void _delPasswordToServer(int id) async {

  }

  void savePasswords() async {
    _savePasswordsToFile();
    final connectResult = await (Connectivity().checkConnectivity());
    if (_useServer) {
      if (connectResult != ConnectivityResult.none) {
        _synchronized = true;
        _savePasswordsToServer();
      } else {
        _synchronized = false;
        _saveSettings();
      }
    }
  }

  // Got it!
  void delPassword(int id) async {
    _passwords.remove(id);
    _savePasswordsToFile();
    _delPasswordToServer(id);
  }

  // Got it!
  int addPassword(String title, String login, String password) {
    final _password = Password(title, login, password, _passwords.keys.last+1);
    _passwords[_password.id] = _password;
    _savePasswordsToFile();
    _updatePasswordToServer(_password.id);
    return _password.id;
  }

  // Got it!
  Map<String, String> getPassword(int id) {
    return {
      "title": _passwords[id].title,
      "login": _passwords[id].login,
      "password": _passwords[id].password
    };
  }

  // Got it!
  List<int> getPasswordIds() {
    return _passwords.keys;
  }

}