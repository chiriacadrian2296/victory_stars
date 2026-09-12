import 'life_area.dart';

/// One written answer to one reflection question in a [LifeArea] — the
/// area's own "prepared questions" mechanism, sitting alongside its free-form
/// vision (see `AreaVisionRepository`) but scoped to a single fixed prompt
/// rather than one open canvas per area.
///
/// [questionId] is the prompt's index into [LifeAreaX.reflectionQuestions]
/// rather than its text, so an answer stays attached to the right question
/// even if its wording is later reworded, and survives a language switch
/// (the questions are looked up fresh per [AppStrings], the id never
/// changes). An area/question pair with no answer simply has no
/// [ReflectionAnswer] at all — see [ReflectionAnswerRepository.setAnswer].
class ReflectionAnswer {
  const ReflectionAnswer({
    required this.area,
    required this.questionId,
    required this.answerText,
    required this.intensity,
    required this.answeredDate,
  }) : assert(
         intensity >= 1 && intensity <= 5,
         'intensity must be 1-5, was $intensity',
       );

  final LifeArea area;
  final String questionId;
  final String answerText;

  /// How difficult it was to find this answer, 1 (easy) to 5 (a lot) — the
  /// same 1-5 scale a star's own effort is rated on, so answering a hard
  /// question is rewarded the same way lighting a hard star is.
  final int intensity;

  /// When this answer was last written or edited.
  final DateTime answeredDate;

  factory ReflectionAnswer.fromJson(Map<String, dynamic> json) {
    return ReflectionAnswer(
      area: LifeArea.values.byName(json['area'] as String),
      questionId: json['questionId'] as String,
      answerText: json['answerText'] as String,
      intensity: json['intensity'] as int,
      answeredDate: DateTime.parse(json['answeredDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area.name,
      'questionId': questionId,
      'answerText': answerText,
      'intensity': intensity,
      'answeredDate': answeredDate.toIso8601String(),
    };
  }
}
