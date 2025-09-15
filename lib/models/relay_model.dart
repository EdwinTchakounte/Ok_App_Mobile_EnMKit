class RelayModel{
  String id;
  String ?name;
  bool isActive;
  int amperage;
  RelayModel({required this.id, this.name, this.isActive = false,required this.amperage});
}