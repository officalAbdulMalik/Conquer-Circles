/// Gamified Google Map style.
///
/// Turns the stock Google Maps look into a muted, game-board-like canvas
/// while keeping wayfinding intact: street, neighborhood, city and park
/// names stay visible (subtly styled) so players always know where they
/// are. Only true clutter is hidden — business POIs, transit and icons —
/// so territory polygons, the player avatar and battle effects carry the
/// visual weight.
///
/// The string is a compile-time constant, so it costs nothing at runtime and
/// is handed to the platform map exactly once via [GoogleMap.style].
library;

const String kGameMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#eaf0e3"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a97a3"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#ffffff"}, {"weight": 2}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#c3ccd4"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5b6b7a"}]
  },
  {
    "featureType": "administrative.neighborhood",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#7d8a97"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.medical",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.school",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.sports_complex",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.government",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#cfe6c2"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6d9c62"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [{"color": "#e6ecdf"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [{"color": "#dfe8d5"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#dfe3e8"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#f6e3b8"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#e8d3a2"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a97a3"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9aa5b0"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#a8cbe8"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#7fa6c7"}]
  }
]
''';
