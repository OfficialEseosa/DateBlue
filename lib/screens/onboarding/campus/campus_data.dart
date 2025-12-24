/// Data model and constants for campus options
class CampusInfo {
  final String name;
  final String location;
  final String imageAsset;

  const CampusInfo({
    required this.name,
    required this.location,
    required this.imageAsset,
  });
}

/// List of all available campuses with their information
const List<CampusInfo> campusList = [
  CampusInfo(
    name: 'Atlanta Campus',
    location: 'Downtown Atlanta',
    imageAsset: 'assets/images/campus/atlanta.jpg',
  ),
  CampusInfo(
    name: 'Alpharetta Campus',
    location: 'Alpharetta',
    imageAsset: 'assets/images/campus/alpharetta.jpg',
  ),
  CampusInfo(
    name: 'Clarkston Campus',
    location: 'Clarkston',
    imageAsset: 'assets/images/campus/clarkston.png',
  ),
  CampusInfo(
    name: 'Decatur Campus',
    location: 'Decatur',
    imageAsset: 'assets/images/campus/decatur.png',
  ),
  CampusInfo(
    name: 'Dunwoody Campus',
    location: 'Dunwoody',
    imageAsset: 'assets/images/campus/dunwoody.png',
  ),
  CampusInfo(
    name: 'Newton Campus',
    location: 'Newton',
    imageAsset: 'assets/images/campus/newton.png',
  ),
];
