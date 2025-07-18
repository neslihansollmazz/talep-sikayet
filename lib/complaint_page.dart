import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/mahalle_dropdown.dart';
import '../utils/mahalle_model.dart';

class ComplaintPage extends StatefulWidget {
  final String token;
  final Map<String, String>? existingComplaint;

  const ComplaintPage({super.key, required this.token, this.existingComplaint});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Talep';

  // Yeni çoklu resim listeleri
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<Uint8List> _webImages = [];

  final List<String> _types = ['Talep', 'Şikayet'];
  Mahalle? _selectedMahalle;
  Yol? _selectedYol;

  @override
  void initState() {
    super.initState();
    if (widget.existingComplaint != null) {
      _selectedType = widget.existingComplaint!['tip'] ?? 'Talep';
      _subjectController.text = widget.existingComplaint!['konu'] ?? '';
      _descriptionController.text = widget.existingComplaint!['icerik'] ?? '';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  OutlineInputBorder get _blackBorder =>
      const OutlineInputBorder(borderSide: BorderSide(color: Colors.black));

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      if (kIsWeb) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          _webImages.add(bytes);
        }
      } else {
        _selectedImages.addAll(pickedFiles);
      }
      setState(() {});
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMahalle == null || _selectedYol == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eksik Bilgi'),
          content: const Text('Lütfen mahalle ve sokak seçiniz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userString = await prefs.getString('user');
    Map<String, dynamic>? userMap;

    if (userString != null) {
      try {
        final firstDecode = jsonDecode(userString);
        userMap = jsonDecode(firstDecode) as Map<String, dynamic>;
      } catch (e) {
        print('JSON decode hatası: $e');
      }
    }

    final uri = Uri.parse('http://10.0.2.2:3000/api/veri-ekle');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${widget.token}'
      ..fields['basvuru_tipi'] = _selectedType
      ..fields['icerik'] = _descriptionController.text
      ..fields['isim'] = userMap?['isim'] ?? 'Test'
      ..fields['soyisim'] = userMap?['soyisim'] ?? 'Kullanici'
      ..fields['kullanici_id'] = (userMap?['kullanici_id'] ?? 1).toString()
      ..fields['konu'] = _subjectController.text
      ..fields['mahalle'] = _selectedMahalle!.r
      ..fields['sokak'] = _selectedYol!.name
      ..fields['sokak_tipi'] = _selectedYol!.type;

    // Çoklu resimleri ekle
    if (kIsWeb) {
      for (int i = 0; i < _webImages.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'dosyalar',
            _webImages[i],
            filename: 'web_image_$i.jpg',
          ),
        );
      }
    } else {
      for (var image in _selectedImages) {
        final file = File(image.path);
        final imageStream = http.ByteStream(file.openRead());
        final imageLength = await file.length();
        final multipartFile = http.MultipartFile(
          'dosyalar',
          imageStream,
          imageLength,
          filename: image.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, {
          'basvuru_tipi': _selectedType,
          'icerik': _descriptionController.text,
          'konu': _subjectController.text,
          'mahalle': _selectedMahalle!.r,
          'sokak': _selectedYol!.name,
        });
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Sunucu hatası: ${response.statusCode}\n$respStr');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hata'),
          content: Text('Gönderim başarısız oldu: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'TALEP / ŞİKAYET GÖNDER',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              DropdownButtonFormField<String>(
                value: _selectedType,
                items: _types
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: InputDecoration(
                  labelText: 'Tür Seçiniz',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
              ),

              const SizedBox(height: 15),

              MahalleDropdown(
                onSelectionChanged: (mahalle, yol) {
                  setState(() {
                    _selectedMahalle = mahalle;
                    _selectedYol = yol;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Konu İçeriği',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Konu içeriğini giriniz'
                    : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: _blackBorder,
                  enabledBorder: _blackBorder,
                  focusedBorder: _blackBorder,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Açıklama giriniz' : null,
              ),

              const SizedBox(height: 15),

              // Resim grid önizleme
              if (kIsWeb && _webImages.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _webImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) => Stack(
                      children: [
                        Positioned.fill(
                          child: Image.memory(
                            _webImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!kIsWeb && _selectedImages.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) => Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.photo),
                        label: const Text('Resim Ekle'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Gönder'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
