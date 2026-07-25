import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';

abstract final class SyntheticRecommendationFixtures {
  static const RecommendationSummary restaurant = RecommendationSummary(
    id: 'restaurant-1',
    placeName: 'Bluebird Kitchen',
    placeTypeLabel: 'Italian restaurant',
    personalizedMatch: PersonalizedMatch(score: 88),
    matchExplanation:
        'Strong step-free access and quieter seating align with this profile.',
    practicalContext: PlacePracticalContext(
      priceLabel: r'$$',
      cuisineLabel: 'Italian',
      distanceLabel: '0.7 mi',
      hoursLabel: 'Open until 9 PM',
    ),
    evidenceSummary: EvidenceSummary(
      confidence: ConfidenceLevel.high,
      mentionCount: 6,
      recencyLabel: 'Latest mention 2 months ago',
    ),
    attributeSummaries: <RecommendationAttributeSummary>[
      RecommendationAttributeSummary(
        label: 'Step-free entrance',
        status: AccessibilityStatus.strength,
      ),
      RecommendationAttributeSummary(
        label: 'Restroom maneuverability',
        status: AccessibilityStatus.unknown,
      ),
      RecommendationAttributeSummary(
        label: 'Evening noise',
        status: AccessibilityStatus.concern,
      ),
    ],
  );

  static const RecommendationSummary activity = RecommendationSummary(
    id: 'activity-1',
    placeName: 'Riverside Art Studio',
    placeTypeLabel: 'Arts and crafts activity',
    personalizedMatch: PersonalizedMatch(score: 81),
    matchExplanation:
        'Wide work areas and staff assistance align with this profile.',
    practicalContext: PlacePracticalContext(
      priceLabel: r'$',
      distanceLabel: '1.1 mi',
      hoursLabel: 'Open until 6 PM',
    ),
    evidenceSummary: EvidenceSummary(
      confidence: ConfidenceLevel.medium,
      mentionCount: 3,
      recencyLabel: 'Latest mention 5 months ago',
    ),
    attributeSummaries: <RecommendationAttributeSummary>[
      RecommendationAttributeSummary(
        label: 'Interior pathways',
        status: AccessibilityStatus.strength,
      ),
      RecommendationAttributeSummary(
        label: 'Lighting',
        status: AccessibilityStatus.unknown,
      ),
    ],
  );

  static const PlaceDetail restaurantDetail = PlaceDetail(
    recommendationId: 'restaurant-1',
    placeName: 'Bluebird Kitchen',
    placeTypeLabel: 'Italian restaurant',
    personalizedMatch: PersonalizedMatch(score: 88),
    matchExplanation:
        'Strong step-free access and quieter seating align with this profile.',
    practicalContext: PlacePracticalContext(
      priceLabel: r'$$',
      cuisineLabel: 'Italian',
      distanceLabel: '0.7 mi',
      hoursLabel: 'Open until 9 PM',
    ),
    attributes: <AttributeAssessment>[
      AttributeAssessment(
        label: 'Step-free entrance',
        status: AccessibilityStatus.strength,
        explanation: 'Declared and observed evidence agree.',
        confidence: ConfidenceLevel.high,
        mentionCount: 4,
        recencyLabel: 'Latest mention 2 months ago',
        declaredEvidence: <EvidenceItem>[
          EvidenceItem(
            sourceKind: EvidenceSourceKind.declared,
            summary: 'The business lists a wheelchair-accessible entrance.',
          ),
        ],
        observedEvidence: <EvidenceItem>[
          EvidenceItem(
            sourceKind: EvidenceSourceKind.observed,
            summary: 'Customers describe a level entrance at the front.',
            confidence: ConfidenceLevel.high,
            recencyLabel: '2 months ago',
          ),
        ],
      ),
      AttributeAssessment(
        label: 'Evening noise',
        status: AccessibilityStatus.concern,
        explanation: 'Recent customer observations mention louder evenings.',
        confidence: ConfidenceLevel.medium,
        mentionCount: 2,
        recencyLabel: 'Latest mention 3 months ago',
        observedEvidence: <EvidenceItem>[
          EvidenceItem(
            sourceKind: EvidenceSourceKind.observed,
            summary: 'The dining room was described as louder after 7 PM.',
            confidence: ConfidenceLevel.medium,
            recencyLabel: '3 months ago',
          ),
        ],
      ),
      AttributeAssessment(
        label: 'Restroom maneuverability',
        status: AccessibilityStatus.unknown,
        explanation: 'No reliable evidence was supplied.',
      ),
    ],
    externalActions: <PlaceExternalAction>[
      PlaceExternalAction(
        type: PlaceActionType.directions,
        label: 'Directions',
        target: 'synthetic://directions/restaurant-1',
        fallbackCopyValue: '100 Example Street',
      ),
      PlaceExternalAction(
        type: PlaceActionType.call,
        label: 'Call',
        target: 'synthetic://call/restaurant-1',
        fallbackCopyValue: '555-0100',
      ),
    ],
  );

  static const PlaceDetail activityDetail = PlaceDetail(
    recommendationId: 'activity-1',
    placeName: 'Riverside Art Studio',
    placeTypeLabel: 'Arts and crafts activity',
    personalizedMatch: PersonalizedMatch(score: 81),
    matchExplanation:
        'Wide work areas and staff assistance align with this profile.',
    practicalContext: PlacePracticalContext(
      priceLabel: r'$',
      distanceLabel: '1.1 mi',
      hoursLabel: 'Open until 6 PM',
    ),
    attributes: <AttributeAssessment>[
      AttributeAssessment(
        label: 'Interior pathways',
        status: AccessibilityStatus.strength,
        explanation:
            'Customers consistently describe room between work tables.',
        confidence: ConfidenceLevel.medium,
        mentionCount: 3,
        recencyLabel: 'Latest mention 5 months ago',
        observedEvidence: <EvidenceItem>[
          EvidenceItem(
            sourceKind: EvidenceSourceKind.observed,
            summary: 'Customers describe wide paths between work areas.',
            confidence: ConfidenceLevel.medium,
            recencyLabel: '5 months ago',
          ),
        ],
      ),
      AttributeAssessment(
        label: 'Lighting',
        status: AccessibilityStatus.unknown,
        explanation: 'No reliable lighting evidence was supplied.',
      ),
    ],
    evidenceCoverageNotices: <EvidenceCoverageNotice>{
      EvidenceCoverageNotice.unknownHeavy,
    },
    externalActions: <PlaceExternalAction>[
      PlaceExternalAction(
        type: PlaceActionType.directions,
        label: 'Directions',
        target: 'synthetic://directions/activity-1',
        fallbackCopyValue: '200 Example Avenue',
      ),
    ],
  );
}
