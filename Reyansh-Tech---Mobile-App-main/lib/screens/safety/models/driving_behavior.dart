enum BehaviorRating { excellent, good, needsImprovement }

class DrivingBehavior {
  final String title;
  final String ratingLabel;
  final int score;
  final BehaviorRating rating;

  const DrivingBehavior({
    required this.title,
    required this.ratingLabel,
    required this.score,
    required this.rating,
  });

  factory DrivingBehavior.fromJson(Map<String, dynamic> json) => DrivingBehavior(
        title: json['title'] as String,
        ratingLabel: json['rating_label'] as String,
        score: json['score'] as int,
        rating: BehaviorRating.values.firstWhere(
          (e) => e.name == json['rating'],
          orElse: () => BehaviorRating.good,
        ),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'rating_label': ratingLabel,
        'score': score,
        'rating': rating.name,
      };
}