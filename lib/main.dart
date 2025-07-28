import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'anasayfa_page.dart';
import 'employess_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final rol = prefs.getString('rol');

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: (token != null && rol != null) ? '/home' : '/login',
    routes: {
      '/login': (context) => const LoginPage(),
      '/home': (context) => (rol == 'admin')
          ? EmployeesPage()
          : AnasayfaPage(token: token ?? ''),
    },
  ));
}
