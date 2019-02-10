import 'dart:io';
import 'package:flutter/material.dart';
import 'PasswordGenerator.dart';
import 'package:path_provider/path_provider.dart';
import 'Password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Database.dart';

class PasswordList extends StatefulWidget {

  final String _key;
  final bool _server;
  final String _userMail;

  PasswordList(this._key, this._server, this._userMail);

  @override
  State<StatefulWidget> createState() => PasswordListState(_key, _server, _userMail);
}

class PasswordListState extends State<PasswordList> {

  final String _keyForPasswords;
  final BoxDecoration _boxDecoration = BoxDecoration(
      image: DecorationImage(
          image: AssetImage("images/mterial-background.jpg"),
          fit: BoxFit.cover));
  bool _useServer;
  final _db = Firestore.instance;
  final String _userMail;
  List<Password> _passwordsList = List();


  PasswordListState(this._keyForPasswords, this._useServer, this._userMail);

  void _savePasswordsToFile() async => getApplicationDocumentsDirectory().then((path){
    final File file = File("${path.path}/passwords.txt");
    String data = "Divider\n";
    for (Password password in _passwordsList) {
      final i = password;
      i.encryptAllFields(_keyForPasswords);
      data += "${i.title}\n${i.login}\n${i.password}\nDivider\n";
    }
    file.writeAsStringSync(data);
  });

  void _savePasswordsToServer() async {
    print("Save data to server");

    final passwordsMap = Map<String, Map<String, String>>();
    for (Password i in _passwordsList) {
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

  void _loadPasswordsFromServer() async {
    print("Load data from server");
    _db.collection(_userMail).document("passwords").snapshots().listen((data) {
      if (data.data != null) {
        for (String id  in data.data.keys) {
          if (_passwordsList.isNotEmpty) {
            for (Password password in _passwordsList) {
              if (password.id.toString() != id) {
                final passwordData = data.data[id];
                final processedPassword = Password(passwordData["title"], passwordData["login"],
                    passwordData["password"], int.parse(id));
                processedPassword.decryptAllFields(_keyForPasswords);
                _passwordsList.add(processedPassword);
              }
            }
          } else {
            final passwordData = data.data[id];
            final processedPassword = Password(passwordData["title"], passwordData["login"],
                passwordData["password"], int.parse(id));
            processedPassword.decryptAllFields(_keyForPasswords);
            _passwordsList.add(processedPassword);
          }
          print(_passwordsList);
          setState(() {});
        }
      }
    });
  }

  void _loadPasswords() async => getApplicationDocumentsDirectory().then((path){
    final File file = File("${path.path}/passwords.txt");
    final List<String> data = file.readAsStringSync().split("Divider\n");
    final List<List<String>> tmpData = List();
    data.forEach((elem) {
      tmpData.add(elem.split("\n"));
    });

    // Расшифровываю данные
    for ( int i = 1; i < tmpData.length-1; i++) {
      tmpData[i].removeLast();
      final password = Password(tmpData[i][0], tmpData[i][1], tmpData[i][2], i-1);
      password.decryptAllFields(_keyForPasswords);
      _passwordsList.add(password);
    }
    print(_useServer);
    if (_useServer) _loadPasswordsFromServer();
    setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  void _addPassword(Password data){
    _passwordsList.add(data);
    _savePasswordsToFile();
    if (_useServer) {
      _savePasswordsToServer();
    }
  }

  void _removePassword(int id){
    _passwordsList.removeAt(id);
    _savePasswordsToFile();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Ваши пароли."),),
    body: Container(
        decoration: _boxDecoration,
        child: ListView.builder(
          itemCount: _passwordsList.length,
          itemBuilder: (context, id) {
            final data = _passwordsList[id];
            return Dismissible(
              background: Container(
                color: Colors.blueGrey,
                child: Text("Удалить!", textAlign: TextAlign.end, style: TextStyle(fontSize: 45.0, color: Colors.black54),),
              ),
              direction: DismissDirection.endToStart,
              key: Key(_passwordsList[id].id.toString()),
              onDismissed: (direction) {
                setState(() {
                  _removePassword(id);
                });
                Scaffold.of(context).showSnackBar(SnackBar(
                  duration: Duration(seconds: 2),
                  content: Row(
                    children: <Widget>[
                      Text("Вернуть удаленный пароль?"),
                      FlatButton(
                        child: Text("Да!"),
                        onPressed: () => setState( () {
                          _addPassword(Password(data.title, data.login, data.password,
                              _passwordsList.isNotEmpty ? _passwordsList.last.id+1 : 0));
                          for (Password i in _passwordsList) print(i.id);
                        }),
                      )
                    ],
                  ),
                ));
              },
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(_passwordsList[id].title, style: TextStyle(fontSize: 25.0, color: Colors.white),),
                    subtitle: Text("Логин: ${_passwordsList[id].login}   "
                        "Пароль: ${_passwordsList[id].password}", style: TextStyle(fontSize: 20.0, color: Colors.white70),),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
                  ),
                  Divider(
                    height: 7.0,
                    indent: 16.0,
                    color: Colors.black,
                  )
                ],
              ),
            );
          },
        )
    ),
    floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
        onPressed: () async {
          // получаю массив из двух значений: заголовок пароля и пароль
          List<String> data = await Navigator.push(context, PageRouteBuilder(
            pageBuilder: (context, _, __) => PasswordRequestWindow(),
            opaque: false,
          ));
          if (data[0] != null && data[1] != null) _addPassword(Password(data[0], data[1], data[2],
              _passwordsList.isNotEmpty ? _passwordsList.last.id+1 : 0));
          setState((){});
        }
    ),
  );
}


class PasswordRequestWindow extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PasswordRequestWindowState();
}

class PasswordRequestWindowState extends State<PasswordRequestWindow> {

  final _formKey = GlobalKey<FormState>();
  final _textStyle = TextStyle(color: Colors.white, fontSize: 20.0);
  final _controller = TextEditingController();
  bool _checkPassword = true;
  final List<String> _passwordData = [null, null, null];
  final _buttonColor = Colors.blueGrey;
  final BoxDecoration _boxDecoration = BoxDecoration(
      image: DecorationImage(
          image: AssetImage("images/mterial-background.jpg"),
          fit: BoxFit.cover));

  @override
  Widget build(BuildContext context) => AlertDialog(

    title: Text("Добавление пароля", style: _textStyle),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              style: _textStyle,
              decoration: InputDecoration(
                errorStyle: TextStyle(color: Colors.black),
                hintText: "Заголовок пароля",
                hintStyle: TextStyle(fontSize: 20.0, color: Colors.white),
              ),
              validator: (value) {
                if (value.isEmpty) return "Вы не ввели заголовок пароля";
                if (value.length > 40) return "Заголовок пароля может содержать не более 40 символов";
                if (value.contains("Divider")) return 'Заголовок не может содержать Divider';
                if (value.contains("\n")) return "Заголовок не может содержать /n";
                else _passwordData[0] = value;
                },
            ),

            TextFormField(
              decoration: InputDecoration(
                errorStyle: TextStyle(color: Colors.black),
                hintText: "Логин",
                hintStyle: TextStyle(fontSize: 20.0, color: Colors.white),
              ),
              style: _textStyle,
              validator: (String value) {
                if (value.length > 40) return "Слишком длинный логин";
                else if (value.isEmpty) return "Вы не ввели логин";
                else _passwordData[1] = value;
                },
            ),

            TextFormField(
              controller: _controller,
              style: _textStyle,
              decoration: InputDecoration(
                errorStyle: TextStyle(color: Colors.black),
                hintText: "Пароль",
                hintStyle: TextStyle(fontSize: 20.0, color: Colors.white),
              ),
              validator: (value) {
                if (value.isEmpty) return "Вы не ввели пароль";
                if (value.length > 16) return "Пароль может содержать не более 16 символов";
                if (_checkPassword && !PasswordGenerator().checkPassword(value))
                  return "Не надежный пароль";
                else _passwordData[2] = value;
                },
            ),

            CheckboxListTile(
              title: Text("Проверять пароль на надежность", style: TextStyle(color: Colors.white),),
              value: _checkPassword,
              onChanged: (bool value) => setState(() => _checkPassword = value),
            ),

            RaisedButton(
              color: _buttonColor,
              child: Text("Случайный пароль", style: TextStyle(color: Colors.white),),
              onPressed: () => setState( () => _controller.text = PasswordGenerator().generatePassword()),
            )
          ],
        ),
      ),
    ),
    actions: <Widget>[
      RaisedButton(
          child: Text("Отмена", style: TextStyle(color: Colors.white),),
          color: _buttonColor,
          onPressed: () {
            Navigator.pop(context, _passwordData);
          }
      ),
      RaisedButton(
        color: _buttonColor,
        child: Text("Создать", style: TextStyle(color: Colors.white),),
        onPressed: () {
          _formKey.currentState.validate();
          print(_checkPassword);
          if (_passwordData[0] != null && _passwordData[1] != null && _passwordData[2] != null)
            Navigator.pop(context, _passwordData);
        },
      ),
    ],
  );
}