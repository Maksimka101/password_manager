import 'package:flutter/material.dart';
import 'PasswordGenerator.dart';
import 'Database.dart';

class PasswordList extends StatefulWidget {

  final String _key;

  PasswordList(this._key);

  @override
  State<StatefulWidget> createState() => PasswordListState(_key);
}

class PasswordListState extends State<PasswordList> {

  final String _keyForPasswords;
  Database _db;
  final BoxDecoration _boxDecoration = BoxDecoration(
      image: DecorationImage(
          image: AssetImage("images/mterial-background.jpg"),
          fit: BoxFit.cover));
  List<int> _passwordsList = [];

  PasswordListState(this._keyForPasswords);

  @override
  void initState() {
    super.initState();
    _db = Database(_keyForPasswords);
    _db.init().then((_){
      _passwordsList = _db.getPasswordIds();
      setState(() {});
    });
    }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Ваши пароли."),),
    body: Container(
        decoration: _boxDecoration,
        child: ListView.builder(
          itemCount: _passwordsList.length,
          itemBuilder: (context, id) {
            final password = _db.getPassword(_passwordsList[id]);
            return Dismissible(
              background: Container(
                color: Colors.blueGrey,
                child: Text("Удалить!", textAlign: TextAlign.end, style: TextStyle(fontSize: 45.0, color: Colors.black54),),
              ),
              direction: DismissDirection.endToStart,
              key: Key(_passwordsList[id].toString()),
              onDismissed: (direction) {
                setState(() {
                  _db.delPassword(_passwordsList[id]);
                });
                Scaffold.of(context).showSnackBar(SnackBar(
                  duration: Duration(seconds: 2),
                  content: Row(
                    children: <Widget>[
                      Text("Вернуть удаленный пароль?"),
                      FlatButton(
                        child: Text("Да!"),
                        onPressed: () => setState( () {
                          _db.addPassword(password["title"], password["login"], password["password"]);
                        }),
                      )
                    ],
                  ),
                ));
              },
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(password["title"], style: TextStyle(fontSize: 25.0, color: Colors.white),),
                    subtitle: Text("Логин: ${password["login"]}   "
                        "Пароль: ${password["password"]}", style: TextStyle(fontSize: 20.0, color: Colors.white70),),
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
          if (data[0] != null && data[1] != null && data[2] != null) _passwordsList.add(_db.addPassword(data[0], data[1], data[2]));
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