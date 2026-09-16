class SafePlace {
  const SafePlace({
    required this.name,
    required this.kind,
    required this.summary,
    required this.details,
    required this.address,
    required this.photoUrl,
    this.lat,
    this.lng,
  });

  final String name;
  final String kind;
  final String summary;
  final String details;
  final String address;
  final String photoUrl;
  final double? lat;
  final double? lng;
}

const _libraryPhoto = 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=70';
const _parkPhoto = 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=70';
const _cafePhoto = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=900&q=70';
const _centrePhoto = 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=900&q=70';

List<SafePlace> safePlacesFor(String city) {
  final place = city.trim().isEmpty ? 'your city' : city.trim();
  final local = {
    'amsterdam': [
      SafePlace(
        name: 'OBA Oosterdok',
        kind: 'Library',
        summary: 'Large public library with study halls and a cafe.',
        details: 'A well-known public meeting place with staff on site, good lighting and many visitors during the day.',
        address: 'Oosterdokskade 143, 1011 DL Amsterdam',
        photoUrl: _libraryPhoto,
      ),
      SafePlace(
        name: 'Vondelpark',
        kind: 'Park',
        summary: 'Busy public park, best in daylight.',
        details: 'Meet near a cafe or playground entrance. Stay in visible paths and agree a clear landmark.',
        address: 'Vondelpark, 1071 AA Amsterdam',
        photoUrl: _parkPhoto,
      ),
      SafePlace(
        name: 'Pakhuis de Zwijger',
        kind: 'Community venue',
        summary: 'Public cultural venue with a cafe.',
        details: 'Open events and a public cafe make this a practical indoor meeting point.',
        address: 'Piet Heinkade 179, 1019 HC Amsterdam',
        photoUrl: _centrePhoto,
      ),
    ],
    'rotterdam': [
      SafePlace(
        name: 'Central Library Rotterdam',
        kind: 'Library',
        summary: 'Public library next to the market hall.',
        details: 'A busy indoor space with staff, seating and a cafe. Suitable for a first meeting.',
        address: 'Hoogstraat 110, 3011 PV Rotterdam',
        photoUrl: _libraryPhoto,
      ),
      SafePlace(
        name: 'Museumpark',
        kind: 'Park',
        summary: 'Open park between museums.',
        details: 'Meet at a museum entrance in daylight. The area is public and usually well visited.',
        address: 'Museumpark, 3015 CB Rotterdam',
        photoUrl: _parkPhoto,
      ),
    ],
    'utrecht': [
      SafePlace(
        name: 'Neude Library',
        kind: 'Library',
        summary: 'City library in a former post office.',
        details: 'A landmark indoor meeting point with a cafe and regular visitors.',
        address: 'Neude 11, 3512 AD Utrecht',
        photoUrl: _libraryPhoto,
      ),
      SafePlace(
        name: 'Wilhelminapark',
        kind: 'Park',
        summary: 'Public park close to the city centre.',
        details: 'Choose a bench near the pond or a cafe edge during the day.',
        address: 'Wilhelminapark, 3581 Utrecht',
        photoUrl: _parkPhoto,
      ),
    ],
  };

  return local[place.toLowerCase()] ??
      [
        SafePlace(
          name: 'Public library',
          kind: 'Library',
          summary: 'Staffed indoor place in $place.',
          details: 'Ask at the desk for the cafe or reading room. Libraries are visible, public and suitable for a first skill meeting.',
          address: 'Central public library, $place',
          photoUrl: _libraryPhoto,
        ),
        SafePlace(
          name: 'Community centre',
          kind: 'Neighbourhood house',
          summary: 'Local house or buurthuis in $place.',
          details: 'A neighbourhood house is usually staffed and used by residents. Confirm opening hours before you travel.',
          address: 'Community centre, $place',
          photoUrl: _centrePhoto,
        ),
        SafePlace(
          name: 'Public park cafe',
          kind: 'Cafe',
          summary: 'A cafe at the edge of a public park.',
          details: 'Meet in daylight, stay near other visitors, and tell someone where you are going.',
          address: 'Park cafe, $place',
          photoUrl: _cafePhoto,
        ),
      ];
}
