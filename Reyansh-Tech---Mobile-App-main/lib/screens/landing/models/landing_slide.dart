class LandingSlide {
  final String imagePath;
  final String title;
  final String subtitle;

  const LandingSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}

/// Add or edit slides here
const List<LandingSlide> landingSlides = [
  LandingSlide(
    imagePath: 'assets/images/car.png',
    title: 'Automatic Accident Detection',
    subtitle:
        'AI-powered sensors detect crashes instantly and alert emergency services automatically.',
  ),
  LandingSlide(
    imagePath: 'assets/images/car.png',
    title: 'Real-Time GPS Tracking',
    subtitle:
        'Track your vehicle live and share your location with responders in seconds.',
  ),
  LandingSlide(
    imagePath: 'assets/images/car.png',
    title: 'Instant Emergency Alerts',
    subtitle:
        'Notify family, hospitals and police simultaneously with a single tap.',
  ),
];
