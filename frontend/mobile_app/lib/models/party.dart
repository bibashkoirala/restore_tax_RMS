enum PartyType { landlord, client, municipality }

class Party {
  const Party({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final PartyType type;
}
