import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl =
      'http://10.0.2.2:3000/api/service'; // Backend URL'nizi yazın

  Future<bool> guncelleTalep(
    String talepId,
    String yeniIcerik,
    String guncelleyen,
  ) async {
    final url = Uri.parse('$baseUrl/talep/$talepId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'icerik': yeniIcerik, 'guncelleyen': guncelleyen}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Hata: ${response.body}');
      return false;
    }
  }
}
