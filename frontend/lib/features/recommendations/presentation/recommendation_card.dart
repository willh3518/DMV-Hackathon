import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/design_system/components/status_indicator.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    required this.recommendation,
    required this.detailsFocusNode,
    required this.onOpenDetails,
    super.key,
  });

  static Key detailsButtonKey(String recommendationId) =>
      ValueKey<String>('recommendation_details_$recommendationId');

  final RecommendationSummary recommendation;
  final FocusNode detailsFocusNode;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final List<String> contextChips = <String?>[
      recommendation.practicalContext?.priceLabel,
      recommendation.practicalContext?.cuisineLabel,
      recommendation.practicalContext?.distanceLabel,
      recommendation.practicalContext?.hoursLabel,
    ].whereType<String>().toList(growable: false);
    final String? evidenceSummary = _buildEvidenceSummary(
      recommendation.evidenceSummary,
    );

    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            recommendation.placeTypeLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.placeName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: _PersonalizedMatchBadge(
              score: recommendation.personalizedMatch.score,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            recommendation.matchExplanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (contextChips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contextChips
                  .map((String label) => _InfoChip(label: label))
                  .toList(growable: false),
            ),
          ],
          if (evidenceSummary != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              evidenceSummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (recommendation.attributeSummaries.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: recommendation.attributeSummaries
                  .map(
                    (RecommendationAttributeSummary summary) =>
                        AppStatusIndicator(
                          kind: _statusKindFor(summary.status),
                          label: summary.label,
                        ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: detailsButtonKey(recommendation.id),
              focusNode: detailsFocusNode,
              onPressed: onOpenDetails,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Details'),
            ),
          ),
        ],
      ),
    );
  }
}

AppStatusKind _statusKindFor(AccessibilityStatus status) {
  return switch (status) {
    AccessibilityStatus.strength => AppStatusKind.strength,
    AccessibilityStatus.concern => AppStatusKind.concern,
    AccessibilityStatus.unknown => AppStatusKind.unknown,
  };
}

String? _buildEvidenceSummary(EvidenceSummary? evidenceSummary) {
  if (evidenceSummary == null) {
    return null;
  }

  final List<String> parts = <String>[
    if (evidenceSummary.confidence != null)
      'Confidence ${_confidenceLabel(evidenceSummary.confidence!)}',
    if (evidenceSummary.mentionCount != null)
      '${evidenceSummary.mentionCount} mentions',
    if (evidenceSummary.recencyLabel != null) evidenceSummary.recencyLabel!,
  ];

  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' • ');
}

String _confidenceLabel(ConfidenceLevel confidence) {
  return switch (confidence) {
    ConfidenceLevel.high => 'high',
    ConfidenceLevel.medium => 'medium',
    ConfidenceLevel.low => 'low',
  };
}

class _PersonalizedMatchBadge extends StatelessWidget {
  const _PersonalizedMatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Personalized match $score percent for this request',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  '$score%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Personalized match',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
