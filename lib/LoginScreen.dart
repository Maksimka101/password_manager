import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'Coder.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'PasswordGenerator.dart';
import 'PasswordsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Password.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginState();
}



class LoginState extends State<Login> {
  // при входе в первый раз я узнаю имя пользователя и шифрую его по паролем
  // пользователя, а при последующих входах я проверяю пароль на правильность,
  // расшифровывая зашифрованное имя пользователя введенным паролем и сравниваю
  // его с правильным именем пользователя.

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = "User";
  String _userMail;
  String _userMailEncrypted;
  String _greetingText = "Привет!";
  final _formKey = GlobalKey<FormState>();
  String _userPassword;

  Future<FirebaseUser> _handleSignIn() async{
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    FirebaseUser user = await _auth.signInWithGoogle(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken
    );
    return user;
  }

  String _makeGreetingText(){
    int hour = DateTime.now().hour;
    if (hour < 4) return "Доброй ночи, $_userName.";
    else if (hour < 12) return "Доброе утро, $_userName!";
    else if (hour < 15) return "Добрый день, $_userName!";
    else return "Добрый вечер, $_userName!";
  }

  void _readSettings() async {
    getApplicationDocumentsDirectory().then((path){
      final file = File("${path.path}/settings.txt");
      final data = file.readAsStringSync().split("\n");
      for (String i in data) {
        String variable = i.split(":")[0];
        String value = i.split(":")[1];
        if (variable == "_userGmailEncrypted") _userMailEncrypted = value;
        else if (variable == "_userName") _userName = value;
      }
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => PasswordList("MaksimkA101")));
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _auth.currentUser().then((FirebaseUser user) {
      if (user != null){
        _readSettings();
        // TODO disable fast start
        _userName = user.displayName;
        _userMail = user.email;
        _greetingText = _makeGreetingText();
        setState(() {});
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    if (_userName != "User" && _userMailEncrypted != null) {
      return Scaffold(
        appBar: AppBar(title: Text("Аунтефикация"),),
        body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/mterial-background.jpg"),
                  fit: BoxFit.cover)
          ),
          child: Center(
              child: Column(
                children: <Widget>[
                  SizedBox(height: 90.0,),
                  Text(_greetingText, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20.0, color: Colors.white),),
                  SizedBox(height: 20.0,),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "Введите ваш пароль здесь.",
                            hintStyle: TextStyle(fontSize: 23.0, ),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 23.0, color: Colors.white),
                          validator: (String value) {
                            if (value.isEmpty) return "Введите пароль";
                            if (_userMail != Coder().decrypt(_userMailEncrypted, value))
                              return "Не верный пароль";
                            else _userPassword = value;
                          }
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0,)
                ],
              )
          ),
        ),
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.check),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PasswordList(_userPassword)));
              }
            }
        ),
      );
    } else {
      return Authorise();
    }
  }
}

class Authorise extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AuthoriseState();
}

class AuthoriseState extends State<Authorise> {

  int _authoriseStep = 0;
  final double _horizontalPadding = 10.0;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName;
  String _userMail;
  final _formKey = GlobalKey<FormState>();
  String _userPassword;
  bool _useServer = false;


  Future<FirebaseUser> _handleSignIn() async{
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    FirebaseUser user = await _auth.signInWithGoogle(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken
    );
    return user;
  }

  void _saveSettings() async {
    getApplicationDocumentsDirectory().then((path) {
      final file = File("${path.path}/settings.txt");
      file.writeAsStringSync("_useServer:$_useServer\n"
          "_userGmailEncrypted:${Coder().encrypt(_userMail, _userPassword)}\n"
          "_userName:$_userName");
    });
  }

  void _savePassword() async {
    getApplicationDocumentsDirectory().then((path) {
      final file = File("${path.path}/passwords.txt");
      final password = Password("Пароль от паролей", _userName, _userPassword, 0);
      password.encryptAllFields(_userPassword);
      file.writeAsStringSync("Divider\n${password.title}\n"
          "${password.login}\n"
          "${password.password}\n"
          "${password.id.toString()}\n"
          "Divider\n");
    });
    if (_useServer) {
      final db = Firestore.instance;
      final userDb = db.collection(_userMail).document("passwords");
      userDb.snapshots().listen((data) {
        if (data.data == null) userDb.setData({
          "0": {
            "title": Coder().encrypt("Пароль от паролей", _userPassword),
            "login": Coder().encrypt(_userName, _userPassword),
            "password": Coder().encrypt(_userName, _userPassword)
          }
        });
        else userDb.updateData({
          "0": {
            "title": Coder().encrypt("Пароль от паролей", _userPassword),
            "login": Coder().encrypt(_userName, _userPassword),
            "password": Coder().encrypt(_userName, _userPassword)
          }
        });
      });
    }

  }


  // FIRST AUTH STEP
  _buildFirstAuthScreen() {
    return Scaffold(
      appBar: AppBar(title: Text("Добро пожаловать!"),),
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/mterial-background.jpg"),
                  fit: BoxFit.cover
              )
          ),
          child: Center(
              child: Container(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Card(
                        child: Column(
                            children: <Widget>[
                              SizedBox(height: 20.0,),
                              Container(
                                child: Text("Добро пожаловать в менеджер паролей.\n",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 23.0, color: Colors.white),),
                                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                              ),
                              Container(
                                child: Text("Здесь вы сможете хранить свои пароли, "
                                    "не пререживая об их безопасности.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 20.0, color: Colors.white), ),
                                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                              ),
                              SizedBox(height: 20.0,),
                            ]
                        ),
                      ),
                    ]
                ),
              )
          )
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () => setState(() {
          if (_authoriseStep < 2) _authoriseStep +=1;
        }),
        child: Icon(Icons.navigate_next),
      ),
    );
  }


  // SECOND AUTH STEP
  _buildSecondAuthScreen() {
    return Scaffold(
      appBar: AppBar(title: Text("Предисловие"),),
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/mterial-background.jpg"),
                  fit: BoxFit.cover
              )
          ),
          child: Center(
              child: Container(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Card(
                        child: Column(
                            children: <Widget>[
                              SizedBox(height: 20.0,),
                              Container(
                                child: Text("Приложение надежно шифрует ваши пароли, "
                                    "а так же позволяет безопасно хранить их на сервере, "
                                    "для доступа к ним с любого устройства.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 23.0, color: Colors.white),),
                                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                              ),
                              SizedBox(height: 20.0,),
                            ]
                        ),
                      ),
                    ]
                ),
              )
          )
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: () => setState(() {
          if (_authoriseStep < 2) _authoriseStep +=1;
        }),
        child: Icon(Icons.navigate_next),
      ),
    );
  }


  // THIRD AUTH STEP
  _buildSettingsAuthScreen() {
    Widget _secondMove = _userName != null ? Column(
      children: <Widget>[
        SizedBox(height: 20.0,),
        Text("Здравствуйте, $_userName!\n"
            "Теперь придумайте надежный пароль или воспользуйтесь сгенерированным.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "надежный пароль должен содержать минимум 8 символов, 2 цифры "
                "и 2 большие и маленькие буквы",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,),
        ),

        SizedBox(height: 10.0,),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 25.0),
              // TODO
              initialValue: 'MaksimkA101',
              //initialValue: PasswordGenerator().generatePassword(),
              validator: (String value) {
                if (value.isEmpty) return "Вы не ввели пароль";
                if (value.toLowerCase().split(" ").join("").contains(
                    "нагоршкесиделкороль")) return "Да ты шутник";
                if (PasswordGenerator().checkPassword(value))
                  setState(() => _userPassword = value);
                else
                  return "Пароль слишком легкий.";
              },
            ),
          ),
        ),
        SizedBox(height: 20.0,),

        Container(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: RaisedButton(
              onPressed: () => setState(() => _formKey.currentState.validate()),
              child: Text(
                "Подтвердить пароль.", style: TextStyle(color: Colors.white),),
            )
        ),
        SizedBox(height: 20.0,)

      ],
    ) : Container();

    // Спрашиваю, хранить ли мне пароли на сервере
    Widget _thirdMove;
    if (_userPassword != null) {
      _thirdMove = CheckboxListTile(
        activeColor: Colors.blueGrey,
        title: Text("Хранить данные на сервере.",
          style: TextStyle(fontSize: 20.0, color: Colors.white),),
        value: _useServer,
        onChanged: (bool value) {
          setState(() => _useServer = value);
          _saveSettings();
        },
      );

      _saveSettings();
      _savePassword();
    } else _thirdMove = Container();


    return Scaffold(
      appBar: AppBar(title: Text("Регистрация и настройка"),),
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/mterial-background.jpg"),
                  fit: BoxFit.cover
              )
          ),
          child: Center(
              child: Container(
                child: ListView(
                    children: <Widget>[
                      SizedBox(height: 30.0,),

                      Container(
                        child: Text("Перед началом совершите несколько действий, "
                            "обязательных для работы приложения:", textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20.0),),
                        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
                      ),

                      SizedBox(height: 20.0,),

                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 50.0),
                          child: RaisedButton(
                            onPressed: () =>
                                _handleSignIn().then((FirebaseUser user) {
                                  setState(() {
                                    _userName = user.displayName;
                                    _userMail = user.email;
                                    print(_userName);
                                  });
                                }),
                            child: Text("Войдите через Google",
                              style: TextStyle(color: Colors.white),),
                          )
                      ),

                      _secondMove,

                      _thirdMove,
                    ]
                ),
              )
          )
      ),
      floatingActionButton: _userPassword != null ? FloatingActionButton(
        child: Icon(Icons.check),
        backgroundColor: Colors.blueGrey,
        onPressed: () {
          _savePassword();
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => PasswordList(_userPassword)));
        },
      ) : null,
    );
  }


  @override
  Widget build(BuildContext context) {

    // Проверяю какой экран делать ( приветствие, введение или настройка )
    // Ниже идет экран приветствия и введения
    switch (_authoriseStep) {
      case 0:
        return _buildFirstAuthScreen();
        break;
      case 1:
        return _buildSecondAuthScreen();
        break;
      default:
        return _buildSettingsAuthScreen();
        break;
    }
  }
}
