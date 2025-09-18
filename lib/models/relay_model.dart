class RelayModel {
  int? id;
  String? name;
  bool isActive;
  int amperage;

  RelayModel({
    this.id,
    this.name,
    this.isActive = false,
    required this.amperage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive ? 1 : 0,
      'amperage': amperage,
    };
  }

  factory RelayModel.fromMap(Map<String, dynamic> map) {
    return RelayModel(
      id: map['id'],
      name: map['name'],
      isActive: map['isActive'] == 1,
      amperage: map['amperage'],
    );
  }
}
