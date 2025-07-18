import 'package:flutter/material.dart';
import '../utils/api_service.dart';

class TalepGuncellePage extends StatefulWidget {
  final String talepId;
  final String mevcutIcerik;

  const TalepGuncellePage({
    required this.talepId,
    required this.mevcutIcerik,
    Key? key,
  }) : super(key: key);

  @override
  _TalepGuncellePageState createState() => _TalepGuncellePageState();
}

class _TalepGuncellePageState extends State<TalepGuncellePage> {
  late TextEditingController _icerikController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _icerikController = TextEditingController(text: widget.mevcutIcerik);
  }

  @override
  void dispose() {
    _icerikController.dispose();
    super.dispose();
  }

  Future<void> _guncelleTalep() async {
    setState(() => _isLoading = true);

    bool sonuc = await _apiService.guncelleTalep(
      widget.talepId,
      _icerikController.text.trim(),
      'Ceren', // Burayı dinamik yapabilirsiniz
    );

    setState(() => _isLoading = false);

    if (sonuc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talep başarıyla güncellendi!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncelleme sırasında hata oluştu!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talep Güncelle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _icerikController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Talep İçeriği',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TalepGuncellePage(
                            talepId: '123', // Güncellenecek talebin ID'si
                            mevcutIcerik:
                                'Mevcut talep...', // Güncellenen talebin mevcut içeriği
                          ),
                        ),
                      ).then((guncellendi) {
                        if (guncellendi == true) {
                          // Talep başarıyla güncellendi, burada listeyi yenileyebilirsin
                        }
                      });
                    },
                    child: const Text('Talebi Güncelle'),
                  ),
          ],
        ),
      ),
    );
  }
}
