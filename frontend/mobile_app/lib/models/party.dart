enum PartyType { landlord, client, municipality }

class Party {
  const Party({
    required this.id,
    required this.name,
    required this.username,
    required this.type,
  });

  final String id;
  final String name;
  final String username;
  final PartyType type;

  bool get isLandlord => type == PartyType.landlord;
  bool get isClient => type == PartyType.client;
  bool get isMunicipality => type == PartyType.municipality;

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'].toString(),
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      type: switch (json['party_type']) {
        'landlord' => PartyType.landlord,
        'client' => PartyType.client,
        'municipality' => PartyType.municipality,
        _ => PartyType.client,
      },
    );
  }
}
