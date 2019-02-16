import 'dart:async';
import 'Password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {

  StreamController<Map<int, String>> streamController = StreamController.broadcast();
  Map<int, Password> _passwordsMap = {};
  bool _synchronized = false;
  bool _useServer;
  String _userMail;
  final String _userPassword;
  final _db = Firestore.instance;

  Database(this._userPassword);



}