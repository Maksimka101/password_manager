import 'LoginScreen.dart';
import 'package:flutter/material.dart';

main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    routes: {
      "/": (BuildContext context) => Login(),
    },
    theme: ThemeData(
      cardColor: Colors.white12,
      primaryColor: Colors.blueGrey,
      backgroundColor: Colors.blueGrey,
      fontFamily: "Oswald",
      buttonColor: Colors.blueGrey,
      dialogBackgroundColor: Colors.blueGrey,
    ),
  )
);
