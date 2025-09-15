import 'package:enmkit/models/relay_model.dart';

class KitModel{
  String? kitNumber;
  List<String>? allowedNumbers;
  double? initialConsumption;
  int? pulseCount;
  List<RelayModel> relays;
  KitModel({ this.kitNumber,  this.allowedNumbers, this.initialConsumption = 0.0, this.pulseCount , required this.relays});


}