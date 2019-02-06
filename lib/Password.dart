import 'Coder.dart';

class Password {

  String title;
  String login;
  String password;
  int id;
  Password(this.title, this.login, this.password, this.id);

  void decryptAllFields(String decryptKey) {
    title = Coder().decrypt(title, decryptKey);
    login = Coder().decrypt(login, decryptKey);
    password = Coder().decrypt(password, decryptKey);
  }

  void encryptAllFields(String encryptKey) {
    title = Coder().encrypt(title, encryptKey);
    login = Coder().encrypt(login, encryptKey);
    password = Coder().encrypt(password, encryptKey);
  }

}
