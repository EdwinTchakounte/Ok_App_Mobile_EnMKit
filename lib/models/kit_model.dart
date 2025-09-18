import 'dart:convert';
import 'relay_model.dart';

class KitModel {
  String? kitNumber;
  double? initialConsumption;
  int? pulseCount;

  KitModel({
    this.kitNumber,
    this.initialConsumption = 0.0,
    this.pulseCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'kitNumber': kitNumber,
      'initialConsumption': initialConsumption,
      'pulseCount': pulseCount,
    };
  }

  factory KitModel.fromMap(Map<String, dynamic> map, {List<RelayModel> relays = const []}) {
    return KitModel(
      kitNumber: map['kitNumber'],
      initialConsumption: (map['initialConsumption'] as num?)?.toDouble() ?? 0.0,
      pulseCount: map['pulseCount'],
    );
  }

  /// Méthode copyWith pour modifier uniquement certains champs
  KitModel copyWith({
    String? kitNumber,
    double? initialConsumption,
    int? pulseCount,
  }) {
    return KitModel(
      kitNumber: kitNumber ?? this.kitNumber,
      initialConsumption: initialConsumption ?? this.initialConsumption,
      pulseCount: pulseCount ?? this.pulseCount,
    );
  }
}
