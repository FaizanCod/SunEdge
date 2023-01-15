import 'package:eshop/Provider/SettingProvider.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String userName = '',
      cartCount = '',
      curBal = '',
      mobile = '',
      profilePicture = '',
      emailAdd = '',
      password = '';
  String? userId = '';

  String? _curPincode = '';

  String get curUserName => userName;

  String get curPincode => _curPincode ?? '';

  String get curCartCount => cartCount;

  String get curBalance => curBal;

  String get mob => mobile;

  String get profilePic => profilePicture;

  String? get usId => userId;

  String get email => emailAdd;

  String get pass => password;

  void setPincode(String pin) {
    _curPincode = pin;
    notifyListeners();
  }

  void setCartCount(String count) {
    cartCount = count;
    notifyListeners();
  }

  void setBalance(String bal) {
    curBal = bal;
    notifyListeners();
  }

  void setName(String count) {

    userName = count;
    notifyListeners();
  }

  void setMobile(String count) {
    mobile = count;
    notifyListeners();
  }

  void setProfilePic(String count) {
    profilePicture = count;
    notifyListeners();
  }

  void setEmail(String email) {
    emailAdd = email;
    notifyListeners();
  }

  void setUserId(String? count) {
    userId = count;
  }

  void setPassword(String pass) {
    password = pass;
    notifyListeners();
  }
}
