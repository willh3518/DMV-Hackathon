import 'package:accessibility_frontend/domain/chat/chat_models.dart';

enum AccessibilityStatus { strength, concern, unknown }

enum EvidenceSourceKind { declared, observed }

enum ConfidenceLevel { high, medium, low }

/// Contract-supplied context about the completeness of a place's evidence.
///
/// The frontend renders these notices but must not derive them by counting or
/// comparing attribute evidence.
enum EvidenceCoverageNotice { partial, unknownHeavy }

final class PersonalizedMatch {
  const PersonalizedMatch({required this.score})
    : assert(score >= 0 && score <= 100);

  final int score;
}

final class EvidenceSummary {
  const EvidenceSummary({
    this.confidence,
    this.mentionCount,
    this.recencyLabel,
  });

  final ConfidenceLevel? confidence;
  final int? mentionCount;
  final String? recencyLabel;
}

final class PlacePracticalContext {
  const PlacePracticalContext({
    this.priceLabel,
    this.cuisineLabel,
    this.distanceLabel,
    this.hoursLabel,
  });

  final String? priceLabel;
  final String? cuisineLabel;
  final String? distanceLabel;
  final String? hoursLabel;
}

final class RecommendationAttributeSummary {
  const RecommendationAttributeSummary({
    required this.label,
    required this.status,
  });

  final String label;
  final AccessibilityStatus status;
}

final class RecommendationSummary {
  const RecommendationSummary({
    required this.id,
    required this.placeName,
    required this.placeTypeLabel,
    required this.personalizedMatch,
    required this.matchExplanation,
    required this.attributeSummaries,
    this.practicalContext,
    this.evidenceSummary,
  });

  final String id;
  final String placeName;
  final String placeTypeLabel;
  final PersonalizedMatch personalizedMatch;
  final String matchExplanation;
  final List<RecommendationAttributeSummary> attributeSummaries;
  final PlacePracticalContext? practicalContext;
  final EvidenceSummary? evidenceSummary;
}

final class RecommendationResultsPayload implements DiscoveryResultsPayload {
  const RecommendationResultsPayload({
    required this.recommendations,
    required this.announcementLabel,
  });

  final List<RecommendationSummary> recommendations;

  @override
  int get resultCount => recommendations.length;

  @override
  final String announcementLabel;
}

final class EvidenceItem {
  const EvidenceItem({
    required this.sourceKind,
    required this.summary,
    this.confidence,
    this.recencyLabel,
  });

  final EvidenceSourceKind sourceKind;
  final String summary;
  final ConfidenceLevel? confidence;
  final String? recencyLabel;
}

final class AttributeAssessment {
  const AttributeAssessment({
    required this.label,
    required this.status,
    required this.explanation,
    this.confidence,
    this.mentionCount,
    this.recencyLabel,
    this.declaredEvidence = const <EvidenceItem>[],
    this.observedEvidence = const <EvidenceItem>[],
  });

  final String label;
  final AccessibilityStatus status;
  final String explanation;
  final ConfidenceLevel? confidence;
  final int? mentionCount;
  final String? recencyLabel;
  final List<EvidenceItem> declaredEvidence;
  final List<EvidenceItem> observedEvidence;
}

enum PlaceActionType { directions, website, call, reservation }

final class PlaceExternalAction {
  const PlaceExternalAction({
    required this.type,
    required this.label,
    required this.target,
    this.fallbackCopyValue,
  });

  final PlaceActionType type;
  final String label;
  final String target;
  final String? fallbackCopyValue;
}

final class PlaceDetail {
  const PlaceDetail({
    required this.recommendationId,
    required this.placeName,
    required this.placeTypeLabel,
    required this.personalizedMatch,
    required this.matchExplanation,
    required this.attributes,
    this.practicalContext,
    this.evidenceCoverageNotices = const <EvidenceCoverageNotice>{},
    this.externalActions = const <PlaceExternalAction>[],
  });

  final String recommendationId;
  final String placeName;
  final String placeTypeLabel;
  final PersonalizedMatch personalizedMatch;
  final String matchExplanation;
  final List<AttributeAssessment> attributes;
  final PlacePracticalContext? practicalContext;
  final Set<EvidenceCoverageNotice> evidenceCoverageNotices;
  final List<PlaceExternalAction> externalActions;
}

sealed class PlaceDetailResult {
  const PlaceDetailResult();
}

final class PlaceDetailSuccess extends PlaceDetailResult {
  const PlaceDetailSuccess({required this.detail});

  final PlaceDetail detail;
}

enum PlaceDetailFailureReason {
  networkUnavailable('We could not load these details. Check your connection.'),
  serviceUnavailable('Place details are temporarily unavailable. Try again.'),
  unknown('We could not load these details. Try again.');

  const PlaceDetailFailureReason(this.userMessage);

  final String userMessage;
}

final class PlaceDetailFailure extends PlaceDetailResult {
  const PlaceDetailFailure({required this.reason});

  final PlaceDetailFailureReason reason;
}

sealed class ExternalActionLaunchResult {
  const ExternalActionLaunchResult();
}

final class ExternalActionLaunchSuccess extends ExternalActionLaunchResult {
  const ExternalActionLaunchSuccess();
}

final class ExternalActionLaunchFailure extends ExternalActionLaunchResult {
  const ExternalActionLaunchFailure({
    required this.userMessage,
    this.canRetry = true,
    this.fallbackCopyValue,
  });

  final String userMessage;
  final bool canRetry;
  final String? fallbackCopyValue;
}
