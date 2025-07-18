import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talepsikayet/utils/shared.dart';
import 'dart:convert';
import 'login_page.dart';

class Complaint {
  final int id;
  final String baslik;
  final String konu;
  final String aciklama;
  bool tamamlandi;
  final String departman;

  Complaint({
    required this.id,
    required this.baslik,
    required this.konu,
    required this.aciklama,
    required this.tamamlandi,
    required this.departman,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['ID'] ?? 0,
      baslik: json['basvuru_tipi'] ?? '', 
      aciklama: json['icerik'] ?? '',
      konu: (json['konu'] ?? '').toString(),
      tamamlandi: json['basvuru_durumu'] == 'tamamlandi', // <-- burası
      departman: json['departman'] ?? '',
    );
  }

}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: EmployeesPage(),
    ),
  );
}

class EmployeesPage extends StatefulWidget {
  @override
  _EmployeesPageState createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Complaint> complaints = [];
  bool isLoading = true;
  String filter = 'Tümü';
  List<String> departments = [
    'Fen İşleri',
    'İmar',
    'İnsan Kaynakları',
    'Bilgi İşlem',
  ];
  String selectedDepartment = 'Departman Seç';
  String _searchQuery = '';

  @override
void initState() {
  super.initState();
  _loadUserAndFetch();
}

Future<void> _loadUserAndFetch() async {
  final userId = await SessionManager.getUserId();
  await fetchComplaints(userId);
}

  Future<void> fetchComplaints(int? userId) async {
  setState(() => isLoading = true);
  if (userId == null) {
    debugPrint('Kullanıcı ID yok, veriler alınamıyor.');
    setState(() => isLoading = false);
    return;
  }

  final url = Uri.parse('http://10.0.2.2:3000/api/veriler?kullanici_id=$userId');

  try {
    final response = await http.get(url);
    debugPrint('API STATUS: ${response.statusCode}');
    debugPrint('API RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<dynamic> data = decoded is List
          ? decoded
          : (decoded['data'] ?? []);
      setState(() {
        complaints = data.map((json) => Complaint.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Veri alınamadı');
    }
  } catch (e) {
    debugPrint('Hata: $e');
    setState(() => isLoading = false);
  }
}


  Future<void> markAsCompleted(int id) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/veriler/$id');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"basvuru_durumu": "tamamlandi"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          complaints.firstWhere((c) => c.id == id).tamamlandi = true;
        });
      } else {
        throw Exception('Güncelleme başarısız');
      }
    } catch (e) {
      debugPrint('Güncelleme hatası: $e');
    }
  }

  List<Complaint> get filteredComplaints {
    List<Complaint> filtered = complaints;

    if (selectedDepartment != 'Departman Seç') {
      filtered = filtered
          .where((c) => c.departman == selectedDepartment)
          .toList();
    }
    if (filter == 'Tamamlanan') {
      filtered = filtered.where((c) => c.tamamlandi).toList();
    } else if (filter == 'Bekleyen') {
      filtered = filtered.where((c) => !c.tamamlandi).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) =>
                c.baslik.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.aciklama.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    print('Filtrelenen Şikayet Sayısı: ${filtered.length}');
    return filtered;
  }

void _showComplaintDetails(Complaint complaint) { //yenı ekledım
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${complaint.konu}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
              Text("Açıklama: ${complaint.aciklama}"),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Kapat'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  } // yenı ekledım
  Widget buildFilterButton(String label) {
    bool isSelected = filter == label;
    return Expanded(
      child: Container(
        margin: EdgeInsets.zero,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              filter = label;
            });
          },
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black, width: 1),
            foregroundColor: Colors.black,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget buildSearchField() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Ara...',
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Future<void> _logout() async {
    await clearUserSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Geri',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Image.asset('assets/mezitbellogo.png', height: 60),
            const SizedBox(width: 10),
            Expanded(child: Container()),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TALEP / ŞİKAYETLER',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                Expanded(child: buildSearchField()),
              ],
            ),
            Row(
              children: [
                buildFilterButton("Tümü"),
                buildFilterButton("Bekleyen"),
                buildFilterButton("Tamamlanan"),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComplaints.isEmpty
                  ? const Center(child: Text("Görüntülenecek talep yok"))
                  : ListView.builder(
                      itemCount: filteredComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = filteredComplaints[index];
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            title: Text(complaint.baslik),
                            subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Konu: ${complaint.konu}"),
                              Text("Açıklama: ${complaint.aciklama}"),
                            ],
                          ),
                            onTap: () => _showComplaintDetails(complaint), // yenı ekledım
                            trailing: complaint.tamamlandi
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : ElevatedButton(
                                    child: const Text("Tamamlandı"),
                                    onPressed: () =>
                                        markAsCompleted(complaint.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logout,
        label: const Text('Çıkış Yap', style: TextStyle(color: Colors.black)),
        icon: const Icon(Icons.logout, color: Colors.black),
        backgroundColor: Colors.white,
      ),
    );
  }
}