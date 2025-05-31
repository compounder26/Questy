
class Background {
  final int id;
  final String name;
  final String assetPath;

  Background({
    required this.id,
    required this.name,
    required this.assetPath,
  });

  // Pre-defined list of available backgrounds
  static List<Background> get availableBackgrounds => [
    Background(
      id: 1,
      name: 'Background 1',
      assetPath: 'assets/images/Background/pemandangan1.png',
    ),
    Background(
      id: 2,
      name: 'Background 2',
      assetPath: 'assets/images/Background/pemandangan 2.png',
    ),
    Background(
      id: 3,
      name: 'Background 3',
      assetPath: 'assets/images/Background/pemandagan 3.png',
    ),
    Background(
      id: 4,
      name: 'Background 4',
      assetPath: 'assets/images/Background/pemandangan 4.png',
    ),
    Background(
      id: 5,
      name: 'Background 5',
      assetPath: 'assets/images/Background/pemandagan 5.png',
    ),
  ];
} 