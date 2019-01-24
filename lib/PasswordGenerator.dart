import 'dart:math';

class PasswordGenerator {

  final String alphabet = "qwertyuiopasdfghjklzxcvbnm";
  final String numbers = "1234567890";

  String generatePassword() {
    String password = "";

    while (!checkPassword(password)) {
      for (int i = 0; i < Random().nextInt(16); i++) {
        if (Random().nextBool()) {
          password += Random().nextBool()
              ? alphabet[Random().nextInt(alphabet.length)] : alphabet[Random()
              .nextInt(alphabet.length)].toUpperCase();
        } else {
          password += Random().nextInt(10).toString();
        }
      }
    }

    return password;
  }


  bool checkPassword(String password) {
    // Пароль не может содержать "Divider\n" or "\n"
    // проверить, если пароль содержит иные символы кроме английских

    if (password.length < 8 ) return false;

    if (password.contains("\n") || password.contains(";")) return false;

    int _numScore = 0;
    int _upperCharScore = 0;
    int _loverCharScore = 0;
    for (int i = 0; i < password.length; i++) {
      for (int j = i + 3; j <= password.length; j++) {
        if (numbers.contains(password.substring(i, j)) ||
            "0987654321".contains(password.substring(i, j)) ||
            "qwerty".contains(password.substring(i, j))) return false;
      }
      if (alphabet.contains(password[i]) ||
          alphabet.toUpperCase().contains(password[i]) ||
          numbers.contains(password[i]));
      else return false;

      if (alphabet.toUpperCase().contains(password[i])) _upperCharScore++;
      if (alphabet.contains(password[i])) _loverCharScore++;
      if (numbers.contains(password[i])) _numScore++;
    }

    if (_upperCharScore < 2 || _numScore < 2 || _loverCharScore < 2) return false;

    return true;
  }
}
