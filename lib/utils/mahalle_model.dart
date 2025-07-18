class Yol {
  final String name;
  final String type;

  Yol({required this.name, required this.type});

  factory Yol.fromJson(Map<String, dynamic> json) {
    return Yol(name: json['name'], type: json['type']);
  }
}

class Mahalle {
  final String r;
  final List<Yol> m;

  Mahalle({required this.r, required this.m});

  factory Mahalle.fromJson(Map<String, dynamic> json) {
    var yollar = json['m'] as List;
    return Mahalle(
      r: json['r'],
      m: yollar.map((e) => Yol.fromJson(e)).toList(),
    );
  }
}
