import 'dart:convert';
import 'relay_model.dart';

class KitModel {
  String? kitNumber;
  List<String>? allowedNumbers;
  double? initialConsumption;
  int? pulseCount;

  KitModel({
    this.kitNumber,
    this.allowedNumbers,
    this.initialConsumption = 0.0,
    this.pulseCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'kitNumber': kitNumber,
      'allowedNumbers': jsonEncode(allowedNumbers ?? []), // stocké en JSON
      'initialConsumption': initialConsumption,
      'pulseCount': pulseCount,
    };
  }

  factory KitModel.fromMap(Map<String, dynamic> map, {List<RelayModel> relays = const []}) {
    return KitModel(
      kitNumber: map['kitNumber'],
      allowedNumbers: (jsonDecode(map['allowedNumbers'] ?? '[]') as List).map((e) => e.toString()).toList(),
      initialConsumption: (map['initialConsumption'] as num?)?.toDouble() ?? 0.0,
      pulseCount: map['pulseCount'],
    );
  }
}
