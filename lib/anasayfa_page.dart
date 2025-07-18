import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'package:talepsikayet/utils/shared.dart';
import 'complaint_page.dart';
import 'login_page.dart';

class AnasayfaPage extends StatefulWidget {
  final String token;

  const AnasayfaPage({super.key, required this.token});

  @override
  State<AnasayfaPage> createState() => _AnasayfaPageState();
}

class _AnasayfaPageState extends State<AnasayfaPage> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  int? userId;  // Kullanıcı ID burada tutulacak

  @override
  void initState() {
    super.initState();
    _veriyiYukle();
    _loadUserAndFetch();  // Kullanıcıyı yükle ve şikayetleri getir
  }

  Future<void> _loadUserAndFetch() async {
    final id = await SessionManager.getUserId();
    if (id != null) {
      setState(() {
        userId = id;  // State değişkenine ata
      });
      fetchComplaints(id);  // Kullanıcı ID ile şikayetleri getir
    } else {
      print("Kullanıcı ID bulunamadı");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _veriyiYukle() async {
    final jsonStr = await rootBundle.loadString('assets/csbm.json');
    final jsonList = json.decode(jsonStr) as List;
    // Gerekirse jsonList ile işlemler yapılabilir
  }

  Future<void> fetchComplaints(int id) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veriler?kullanici_id=$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List veriler = json.decode(response.body);
        setState(() {
          complaints = List<Map<String, dynamic>>.from(veriler);
          isLoading = false;
        });
      } else {
        throw Exception('Veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print("Hata: $e");
      setState(() => isLoading = false);
    }
  }

  void _navigateToCreatePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintPage(token: widget.token),
      ),
    );

    if (result != null && userId != null) {
      fetchComplaints(userId!);  // userId parametresini gönder
    }
  }

  void _navigateToEditPage(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintPage(
          token: widget.token,
          existingComplaint: {
            'ID': item['ID'].toString(),
            'tip': item['tur'] ?? 'Talep',
            'konu': item['konu'] ?? '',
            'aciklama': item['icerik'] ?? '',
          },
        ),
      ),
    );

    if (result != null && userId != null) {
      fetchComplaints(userId!);
    }
  }

  Future<void> _confirmAndDelete(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silmek istiyor musunuz?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComplaint(id);
    }
  }

  Future<void> _deleteComplaint(int id) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veri-sil/$id');  // Dikkat: URL'de boşluk vardı, kaldırdım.

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          complaints.removeWhere((item) => item['ID'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarıyla silindi')),
        );
      } else {
        throw Exception('Silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      print("Silme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme işlemi sırasında bir hata oluştu')),
      );
    }
  }

  Future<void> _logout() async {
    await clearUserSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talep / Şikayetlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : complaints.isEmpty
                    ? const Center(child: Text('Henüz talep/şikayet oluşturulmadı'))
                    : ListView.builder(
                        itemCount: complaints.length,
                        itemBuilder: (context, index) {
                          final item = complaints[index];
                          return ListTile(
                            title: Text(item['konu'] ?? 'Konu yok'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['icerik'] ?? 'içerik yok'),
                                const SizedBox(height: 8),
                                if (item['dosya_url'] != null &&
                                    item['dosya_url'].toString().isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['dosya_url'],
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Text('Resim yüklenemedi'),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _navigateToEditPage(item),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Düzenle'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    final rawId = item['ID'];
                                    if (rawId != null) {
                                      final id = rawId is int
                                          ? rawId
                                          : int.tryParse(rawId.toString());
                                      if (id != null) {
                                        _confirmAndDelete(id);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Geçersiz ID'),
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Silinecek kayıt bulunamadı',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreatePage,
            label: const Text('Oluştur', style: TextStyle(color: Colors.red)),
            icon: const Icon(Icons.add, color: Colors.red),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}