import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/mahalle_model.dart';

class MahalleDropdown extends StatefulWidget {
  final Function(Mahalle, Yol) onSelectionChanged;

  const MahalleDropdown({super.key, required this.onSelectionChanged});

  @override
  State<MahalleDropdown> createState() => _MahalleDropdownState();
}

class _MahalleDropdownState extends State<MahalleDropdown> {
  List<Mahalle> mahalleler = [];
  Mahalle? seciliMahalle;
  Yol? seciliYol;

  @override
  void initState() {
    super.initState();
    loadMahalleler();
  }

  Future<void> loadMahalleler() async {
    final jsonStr = await rootBundle.loadString('assets/csbm.json');
    final jsonList = json.decode(jsonStr) as List;

    setState(() {
      mahalleler = jsonList.map((e) => Mahalle.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Mahalle>(
          value: seciliMahalle,
          hint: const Text('Mahalle Seçin'),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Mahalle',
          ),
          items: mahalleler.map((mahalle) {
            return DropdownMenuItem(value: mahalle, child: Text(mahalle.r));
          }).toList(),
          onChanged: (value) {
            setState(() {
              seciliMahalle = value;
              seciliYol = null;
            });
          },
          validator: (value) => value == null ? 'Mahalle seçiniz' : null,
        ),
        const SizedBox(height: 16),
        if (seciliMahalle != null)
          DropdownButtonFormField<Yol>(
            value: seciliYol,
            hint: const Text('Sokak Seçin'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Sokak',
            ),
            items: seciliMahalle!.m.map((yol) {
              return DropdownMenuItem(
                value: yol,
                child: Text('${yol.name} (${yol.type})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                seciliYol = value;
              });
              if (value != null && seciliMahalle != null) {
                widget.onSelectionChanged(seciliMahalle!, value);
              }
            },
            validator: (value) => value == null ? 'Sokak seçiniz' : null,
          ),
      ],
    );
  }
}
