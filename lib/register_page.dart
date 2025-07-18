import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/email_verification_page.dart'; // EmailVerificationPage buradan import ediliyor
import '../complaint_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String username = '';
  String phone = '';
  String password = '';

  Future<void> register() async {
    final url = Uri.parse("http://10.0.2.2:3000/api/register");

    final requestBody = json.encode({
      "tam_adi": name,
      "eposta": email,
      "kullanici_adi": username,
      "telefon": phone,
      "sifre": password,
    });
    print('Gönderilen JSON: $requestBody');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    print('Sunucudan gelen cevap: ${response.body}');

    final res = json.decode(response.body);

    if (res["status"] == "success") {
      // Kayıt başarılı ise mail gönderme isteği yap
      final mailResponse = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (mailResponse.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt başarılı. Doğrulama kodu gönderildi."),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(
              email: email,
              onCodeSubmitted: (code) {
                Navigator.pushReplacementNamed(context, '/anasayfa');
              },
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doğrulama kodu gönderilemedi.")),
        );
      }
    } else {
      final errorMessage =
          res["message"] ?? "Sunucudan bir hata yanıtı alınamadı.";
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $errorMessage")));
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(color: Colors.grey),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
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
          children: [Image.asset('assets/mezitbellogo.png', height: 57)],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "KAYIT OL",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration("Ad Soyad"),
                onSaved: (value) => name = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration("Kullanıcı Adı"),
                onSaved: (value) => username = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration("Telefon"),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phone = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration("E-posta"),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => email = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                cursorColor: Colors.black,
                decoration: inputDecoration("Şifre"),
                obscureText: true,
                onSaved: (value) => password = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      register();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("KAYIT OL"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
