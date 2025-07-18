import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String? username;
  String? newPassword;
  String? confirmPassword;

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey), // normal etiket rengi
      floatingLabelStyle: TextStyle(
        color: Colors.grey,
      ), // focus olunca da aynı renk
      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [Image.asset('assets/mezitbellogo.png', height: 55)],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ŞİFREMİ UNUTTUM",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration('Kullanıcı Adı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kullanıcı adınızı giriniz';
                  }
                  username = value;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                cursorColor: Colors.black,
                obscureText: true,
                decoration: inputDecoration('Yeni Şifre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi giriniz';
                  }
                  newPassword = value;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                cursorColor: Colors.black,
                obscureText: true,
                decoration: inputDecoration('Yeni Şifre (Tekrar)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifreyi tekrar giriniz';
                  }
                  if (value != newPassword) {
                    return 'Şifreler eşleşmiyor';
                  }
                  confirmPassword = value;
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('ŞİFREYİ DEĞİŞTİR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/api/sifre-sifirla'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "kullanici_adi": username,
            "yeni_sifre": newPassword,
          }),
        );

        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _showSuccessDialog("Şifre değiştirme işlemi başarılı.");
        } else {
          _showErrorDialog(data['message'] ?? 'Bir hata oluştu.');
        }
      } catch (e) {
        _showErrorDialog("Sunucuya bağlanılamadı: $e");
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Başarılı"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialogu kapat
              Navigator.pop(context); // login sayfasına dön
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }
}
