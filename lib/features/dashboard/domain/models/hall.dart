class Hall {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final double packageRate;
  final double cleaningCharge;
  final List<String> photoPaths;
  final List<String> facilities;
  final bool isActive;

  Hall({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.packageRate,
    required this.cleaningCharge,
    required this.photoPaths,
    required this.facilities,
    required this.isActive,
  });

  // Global cache to help resolve legacy IDs against fetched Firestore data
  static final List<Hall> _cache = [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'packageRate': packageRate,
      'cleaningCharge': cleaningCharge,
      'photoPaths': photoPaths,
      'facilities': facilities,
      'isActive': isActive,
    };
  }

  factory Hall.fromMap(Map<String, dynamic> map, String id) {
    final hall = Hall(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      capacity: map['capacity'] ?? 0,
      packageRate: (map['packageRate'] as num?)?.toDouble() ?? 0.0,
      cleaningCharge: (map['cleaningCharge'] as num?)?.toDouble() ?? 0.0,
      photoPaths: List<String>.from(map['photoPaths'] ?? []),
      facilities: List<String>.from(map['facilities'] ?? []),
      isActive: map['isActive'] ?? true,
    );

    // Update global cache whenever a hall is loaded from Firestore
    final index = _cache.indexWhere((h) => h.id == id);
    if (index != -1) {
      _cache[index] = hall;
    } else {
      _cache.add(hall);
    }

    return hall;
  }

  /// Resolves a hall ID or name against the current hall data.
  /// Supports legacy IDs '1' and '2'.
  static Hall? lookup(String idOrName) {
    if (idOrName.isEmpty) return null;

    // 1. Exact match by ID in cache
    for (var h in _cache) {
      if (h.id == idOrName) return h;
    }

    // 2. Exact match by Name in cache
    for (var h in _cache) {
      if (h.name == idOrName) return h;
    }

    // 3. Legacy ID mapping
    // ID '1' -> Puranika Sadana (Small Hall)
    if (idOrName == '1' || idOrName.toLowerCase().contains('sadana')) {
       // Try to find the best match in cache first
       for (var h in _cache) {
         if (h.name == 'Puranika Sadana' || (!h.name.toLowerCase().contains('sabha') && h.name.toLowerCase().contains('sadana'))) {
           return h;
         }
       }
       
       // If not in cache yet, return a sensible default object for this ID
       if (idOrName == '1') {
         return Hall(
           id: '1',
           name: 'Puranika Sadana',
           location: 'Sri Kshetra Kollur',
           capacity: 100,
           packageRate: 20000,
           cleaningCharge: 1500,
           photoPaths: const [],
           facilities: const [],
           isActive: true,
         );
       }
    }

    // ID '2' -> Puranika Sabha Sadana (Big Hall)
    if (idOrName == '2' || idOrName.toLowerCase().contains('sabha')) {
       for (var h in _cache) {
         if (h.name == 'Puranika Sabha Sadana' || h.name.toLowerCase().contains('sabha')) {
           return h;
         }
       }
       
       if (idOrName == '2') {
         return Hall(
           id: '2',
           name: 'Puranika Sabha Sadana',
           location: 'Sri Kshetra Kollur',
           capacity: 350,
           packageRate: 32000,
           cleaningCharge: 2500,
           photoPaths: const [],
           facilities: const [],
           isActive: true,
         );
       }
    }

    return null;
  }

  Hall copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    double? packageRate,
    double? cleaningCharge,
    List<String>? photoPaths,
    List<String>? facilities,
    bool? isActive,
  }) {
    return Hall(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      packageRate: packageRate ?? this.packageRate,
      cleaningCharge: cleaningCharge ?? this.cleaningCharge,
      photoPaths: photoPaths ?? this.photoPaths,
      facilities: facilities ?? this.facilities,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hall && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
