import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'Password.dart';
import 'package:connectivity/connectivity.dart';
import 'Coder.dart';

class Database {

  final _passwords = Map<int, Password>();
  bool _useServer;
  final _db = Firestore.instance;
  final _keyForPasswords;
  bool _synchronized = true;
  String _userMail;

  Database(this._keyForPasswords);


  // Load passwords, and settings for next job

  void init() {

    Future.wait([_syncSettings()]).then((_) {
      if (!_synchronized) {
        Connectivity().checkConnectivity().then((result) {
          if (result != ConnectivityResult.none) {
            _loadPasswordsFromAll();
            _synchronized = true;
            _syncSettings(onlySave: true);
          }
        });
      } else {
        if (_useServer) {
          _loadPasswordsFromServer();
          _savePasswordsToFile();
        } else {
          _loadPasswordsFromFile();
        }
      }
    });

  }

  // Load settings and save them to file
  // Can only save them
  Future<void> _syncSettings({bool onlySave = false}) => Future.wait([getApplicationDocumentsDirectory()]).then((path) {
      var unknownData = "";
      final file = File("${path.first.path}/settings.txt");

      // Load
      final data = file.readAsStringSync().split("\n");
      for (String i in data) {
        String variable = i.split(":")[0];
        String data = i.split(":")[1];
        if (variable == "_useServer" && !onlySave) _useServer = data == "true";
        else if (variable == "_userGmailEncrypted" && !onlySave) _userMail = Coder().decrypt(data, _keyForPasswords);
        else if (variable == "_synchronized" && !onlySave) _synchronized = data == "true";
        else {
          unknownData += "$variable:$data\n";
        }
      }

      // Save
      file.writeAsStringSync("${unknownData}_useServer:$_useServer"
          "\n_userGmailEncrypted:${Coder().encrypt(_userMail, _keyForPasswords)}"
          "\n_synchronized:$_synchronized");
    });

  // Load ALL passwords from server
  void _loadPasswordsFromServer() async {
    _db.collection(_userMail).document("passwords").snapshots().listen((data) {
      if (data.data != null) {
        for (final id in data.data.keys) {
          final tmpData = data.data[id];
          final password = Password(tmpData["title"], tmpData["login"], tmpData["password"], int.parse(id));
          password.decryptAllFields(_keyForPasswords);
          _passwords[int.parse(id)] = password;
        }
      }
    });
  }


  // Load ALL passwords from file
  void _loadPasswordsFromFile() => getApplicationDocumentsDirectory().then((path){
    final File file = File("${path.path}/passwords.txt");
    final List<String> data = file.readAsStringSync().split("Divider\n");
    final List<List<String>> tmpData = List();
    data.forEach((elem) {
      tmpData.add(elem.split("\n"));
    });

    // Расшифровываю данные
    for ( int i = 1; i < tmpData.length-1; i++) {
      tmpData[i].removeLast();
      final password = Password(tmpData[i][0], tmpData[i][1], tmpData[i][2], int.parse(tmpData[i][3]));
      password.decryptAllFields(_keyForPasswords);
      _passwords[password.id] = password;
    }
  });

  // Load ALL passwords from server and file
  void _loadPasswordsFromAll() async {
    _loadPasswordsFromServer();
    getApplicationDocumentsDirectory().then((path){
      final File file = File("${path.path}/passwords.txt");
      final List<String> data = file.readAsStringSync().split("Divider\n");
      final List<List<String>> tmpData = List();
      data.forEach((elem) {
        tmpData.add(elem.split("\n"));
      });

      // Расшифровываю данные
      for ( int i = 1; i < tmpData.length-1; i++) {
        if (!_passwords.containsKey(int.parse(tmpData[i][3]))) {
          tmpData[i].removeLast();
          final password = Password(tmpData[i][0], tmpData[i][1], tmpData[i][2],
              int.parse(tmpData[i][3]));
          password.decryptAllFields(_keyForPasswords);
          _passwords[password.id] = password;
        }
      }
    });
  }

  // Save ALL passwords to file
  void _savePasswordsToFile() async => getApplicationDocumentsDirectory().then((path){
    final File file = File("${path.path}/passwords.txt");
    String data = "Divider\n";
    for (Password password in _passwords.values) {
      final i = password;
      i.encryptAllFields(_keyForPasswords);
      data += "${i.title}\n${i.login}\n${i.password}\n${i.id.toString()}\nDivider\n";
    }
    file.writeAsStringSync(data);
  });

  // Update ALL passwords from server
  void _savePasswordsToServer() async {
    final passwordsMap = Map<String, Map<String, String>>();
    for (Password i in _passwords.values) {
      final password = i;
      password.encryptAllFields(_keyForPasswords);
      passwordsMap[password.id.toString()] = {
        "login": password.login,
        "password": password.password,
        "title": password.title
      };
    }

    _db.collection(_userMail).document("passwords").updateData(passwordsMap);
  }

  // Update ONE password from server
  void _updatePasswordToServer(int id) async {
    final password = _passwords[id];
    password.encryptAllFields(_keyForPasswords);
    _db.collection(_userMail).document("passwords").updateData({"${id.toString()}":
    {
      "title": password.title,
      "login": password.login,
      "password": password.password,
    }
    });
  }

  // Del ONE password from server
  void _delPasswordFromServer(int id) async {
    _db.collection(_userMail).document("passwords").updateData({
      "${id.toString()}": FieldValue.delete(),
    });
  }

  // Save ALL passwords
  // Detect disabled network and
  // save passwords to server later when it in possible
  void savePasswords() async {
    _savePasswordsToFile();
    final connectResult = await (Connectivity().checkConnectivity());
    if (_useServer) {
      if (connectResult != ConnectivityResult.none) {
        _synchronized = true;
        _savePasswordsToServer();
      } else {
        _synchronized = false;
        _syncSettings(onlySave: true);
      }
    }
  }

  // Del ONE password from all
  void delPassword(int id) async {
    _passwords.remove(id);
    _savePasswordsToFile();
    _delPasswordFromServer(id);
  }

  // Add ONE password to all
  // return his id
  int addPassword(String title, String login, String password) {
    final _password = Password(title, login, password, _passwords.keys.last+1);
    _passwords[_password.id] = _password;
    _savePasswordsToFile();
    _updatePasswordToServer(_password.id);
    return _password.id;
  }

  // Return ONE password by id
  Map<String, String> getPassword(int id) {
    return {
      "title": _passwords[id].title,
      "login": _passwords[id].login,
      "password": _passwords[id].password
    };
  }

  // Return ALL passwords id
  List<int> getPasswordIds() {
    return _passwords.keys.toList();
  }

}