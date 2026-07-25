import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/design_system/components/status_indicator.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaceDetailRoute extends StatefulWidget {
  const PlaceDetailRoute({
    required this.recommendation,
    required this.placeDetailGateway,
    required this.externalActionLauncher,
    required this.onClose,
    super.key,
  });

  static const Key backButtonKey = Key('place_detail_back_button');
  static const Key headingFocusKey = Key('place_detail_heading_focus');
  static const Key loadingStateKey = Key('place_detail_loading_state');
  static const Key errorStateKey = Key('place_detail_error_state');
  static const Key retryLoadButtonKey = Key('place_detail_retry_load_button');
  static const Key partialNoticeKey = Key('place_detail_partial_notice');
  static const Key unknownHeavyNoticeKey = Key('place_detail_unknown_notice');
  static const Key missingActionsNoticeKey = Key(
    'place_detail_missing_actions_notice',
  );
  static const Key actionFailureKey = Key('place_detail_action_failure');

  static Key actionButtonKey(PlaceActionType type) =>
      ValueKey<String>('place_detail_action_${type.name}');

  final RecommendationSummary recommendation;
  final PlaceDetailGateway placeDetailGateway;
  final ExternalActionLauncher externalActionLauncher;
  final VoidCallback onClose;

  @override
  State<PlaceDetailRoute> createState() => _PlaceDetailRouteState();
}

class _PlaceDetailRouteState extends State<PlaceDetailRoute>
    with WidgetsBindingObserver {
  late final FocusNode _headingFocusNode;
  bool _isLoading = true;
  PlaceDetail? _detail;
  PlaceDetailFailureReason? _failureReason;
  _ActionFailureState? _actionFailure;
  PlaceExternalAction? _launchingAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headingFocusNode = FocusNode(
      debugLabel: 'Place detail heading',
      skipTraversal: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _headingFocusNode.requestFocus();
      }
    });
    _resolveDetail();
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headingFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _failureReason = null;
      _actionFailure = null;
    });
    await _resolveDetail();
  }

  Future<void> _resolveDetail() async {
    late final PlaceDetailResult result;
    try {
      result = await widget.placeDetailGateway.loadPlaceDetail(
        recommendationId: widget.recommendation.id,
      );
    } on Object {
      result = const PlaceDetailFailure(
        reason: PlaceDetailFailureReason.unknown,
      );
    }

    if (!mounted) {
      return;
    }
    switch (result) {
      case PlaceDetailSuccess success:
        if (success.detail.recommendationId != widget.recommendation.id) {
          _showGenericLoadFailure();
          return;
        }
        setState(() {
          _isLoading = false;
          _detail = success.detail;
          _failureReason = null;
        });
      case PlaceDetailFailure failure:
        setState(() {
          _isLoading = false;
          _detail = null;
          _failureReason = failure.reason;
        });
    }
  }

  void _showGenericLoadFailure() {
    setState(() {
      _isLoading = false;
      _detail = null;
      _failureReason = PlaceDetailFailureReason.unknown;
    });
  }

  Future<void> _launchAction(PlaceExternalAction action) async {
    if (_launchingAction != null) {
      return;
    }
    setState(() => _launchingAction = action);

    late final ExternalActionLaunchResult result;
    try {
      result = await widget.externalActionLauncher.launch(action);
    } on Object {
      result = ExternalActionLaunchFailure(
        userMessage:
            'We could not open ${action.label.toLowerCase()}. Try again.',
        fallbackCopyValue: action.fallbackCopyValue,
      );
    }

    if (!mounted) {
      return;
    }
    switch (result) {
      case ExternalActionLaunchSuccess():
        setState(() {
          _launchingAction = null;
          _actionFailure = null;
        });
      case ExternalActionLaunchFailure failure:
        setState(() {
          _launchingAction = null;
          _actionFailure = _ActionFailureState(
            action: action,
            failure: failure,
          );
        });
    }
  }

  Future<void> _copyFallbackValue(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard.')));
  }

  @override
  Widget build(BuildContext context) {
    final PlaceDetail? detail = _detail;
    final RecommendationSummary summary = widget.recommendation;
    final String placeName = detail?.placeName ?? summary.placeName;
    final String placeTypeLabel =
        detail?.placeTypeLabel ?? summary.placeTypeLabel;
    final int score =
        detail?.personalizedMatch.score ?? summary.personalizedMatch.score;
    final String matchExplanation =
        detail?.matchExplanation ?? summary.matchExplanation;
    final PlacePracticalContext? practicalContext =
        detail?.practicalContext ?? summary.practicalContext;
    final bool showPartialNotice =
        detail != null &&
        detail.evidenceCoverageNotices.contains(EvidenceCoverageNotice.partial);
    final bool showUnknownHeavyNotice =
        detail != null &&
        detail.evidenceCoverageNotices.contains(
          EvidenceCoverageNotice.unknownHeavy,
        );
    final bool showMissingActionsNotice =
        detail != null && detail.externalActions.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: PlaceDetailRoute.backButtonKey,
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to results'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        placeTypeLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Focus(
                        key: PlaceDetailRoute.headingFocusKey,
                        focusNode: _headingFocusNode,
                        skipTraversal: true,
                        child: Semantics(
                          header: true,
                          child: Text(
                            placeName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailScoreSummary(
                        score: score,
                        explanation: matchExplanation,
                      ),
                      if (practicalContext != null) ...<Widget>[
                        const SizedBox(height: 16),
                        _PracticalContextSection(context: practicalContext),
                      ],
                      if (_isLoading) ...<Widget>[
                        const SizedBox(height: 18),
                        const _LoadingState(),
                      ] else if (_failureReason != null) ...<Widget>[
                        const SizedBox(height: 18),
                        _ErrorState(
                          reason: _failureReason!,
                          onRetry: () {
                            setState(() => _isLoading = false);
                            _loadDetail();
                          },
                        ),
                      ] else if (detail != null) ...<Widget>[
                        if (showPartialNotice) ...<Widget>[
                          const SizedBox(height: 18),
                          const _NoticeSurface(
                            key: PlaceDetailRoute.partialNoticeKey,
                            title: 'Some evidence is still partial',
                            body:
                                'Several attributes have evidence, but some confidence, count, or recency details were not supplied.',
                          ),
                        ],
                        if (showUnknownHeavyNotice) ...<Widget>[
                          const SizedBox(height: 18),
                          const _NoticeSurface(
                            key: PlaceDetailRoute.unknownHeavyNoticeKey,
                            title: 'Several attributes remain unknown',
                            body:
                                'Unknown means the current contract did not supply enough evidence yet. It does not mean inaccessible.',
                          ),
                        ],
                        const SizedBox(height: 18),
                        ..._buildAttributeSections(context, detail.attributes),
                        const SizedBox(height: 18),
                        if (_actionFailure != null)
                          _ActionFailureSurface(
                            state: _actionFailure!,
                            onRetry: _actionFailure!.failure.canRetry
                                ? () => _launchAction(_actionFailure!.action)
                                : null,
                            onCopy:
                                _actionFailure!.failure.fallbackCopyValue ==
                                    null
                                ? null
                                : () => _copyFallbackValue(
                                    _actionFailure!.failure.fallbackCopyValue!,
                                  ),
                          ),
                        if (_actionFailure != null) const SizedBox(height: 18),
                        if (showMissingActionsNotice)
                          const _NoticeSurface(
                            key: PlaceDetailRoute.missingActionsNoticeKey,
                            title: 'No external actions were supplied',
                            body:
                                'Directions, website, call, and reservation actions are not available for this place yet.',
                          )
                        else
                          _ExternalActionsSection(
                            actions: detail.externalActions,
                            launchingAction: _launchingAction,
                            onLaunchAction: _launchAction,
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttributeSections(
    BuildContext context,
    List<AttributeAssessment> attributes,
  ) {
    final List<Widget> widgets = <Widget>[];
    for (int index = 0; index < attributes.length; index += 1) {
      if (index > 0) {
        widgets.add(const SizedBox(height: 14));
      }
      widgets.add(_AttributeSection(attribute: attributes[index]));
    }
    return widgets;
  }
}

AppStatusKind _statusKindFor(AccessibilityStatus status) {
  return switch (status) {
    AccessibilityStatus.strength => AppStatusKind.strength,
    AccessibilityStatus.concern => AppStatusKind.concern,
    AccessibilityStatus.unknown => AppStatusKind.unknown,
  };
}

String _confidenceLabel(ConfidenceLevel confidence) {
  return switch (confidence) {
    ConfidenceLevel.high => 'High confidence',
    ConfidenceLevel.medium => 'Medium confidence',
    ConfidenceLevel.low => 'Low confidence',
  };
}

class _DetailScoreSummary extends StatelessWidget {
  const _DetailScoreSummary({required this.score, required this.explanation});

  final int score;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: 'Personalized match $score percent for this request',
            child: ExcludeSemantics(
              child: Text(
                '$score% personalized match',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(explanation, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _PracticalContextSection extends StatelessWidget {
  const _PracticalContextSection({required this.context});

  final PlacePracticalContext context;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String?>[
      this.context.priceLabel,
      this.context.cuisineLabel,
      this.context.distanceLabel,
      this.context.hoursLabel,
    ].whereType<String>().toList(growable: false);

    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Practical context',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map(
                  (String label) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Semantics(
        key: PlaceDetailRoute.loadingStateKey,
        liveRegion: true,
        label:
            'Loading place details. The personalized result and evidence explanation will update when available.',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'Loading place details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'The supplied evidence explanation is loading now.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.reason, required this.onRetry});

  final PlaceDetailFailureReason reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Semantics(
        key: PlaceDetailRoute.errorStateKey,
        liveRegion: true,
        button: true,
        label:
            'Place detail load failed. ${reason.userMessage} Retry is available.',
        onTap: onRetry,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'We could not load these details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                reason.userMessage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: PlaceDetailRoute.retryLoadButtonKey,
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeSurface extends StatelessWidget {
  const _NoticeSurface({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _AttributeSection extends StatelessWidget {
  const _AttributeSection({required this.attribute});

  final AttributeAssessment attribute;

  @override
  Widget build(BuildContext context) {
    final List<String> metadata = <String>[
      if (attribute.confidence != null) _confidenceLabel(attribute.confidence!),
      if (attribute.mentionCount != null) '${attribute.mentionCount} mentions',
      if (attribute.recencyLabel != null) attribute.recencyLabel!,
    ];

    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: AppStatusIndicator(
              kind: _statusKindFor(attribute.status),
              label: attribute.label,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            attribute.explanation,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (metadata.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              metadata.join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 14),
          if (attribute.declaredEvidence.isNotEmpty)
            _EvidenceGroup(
              heading: 'Business-declared evidence',
              items: attribute.declaredEvidence,
            ),
          if (attribute.declaredEvidence.isNotEmpty &&
              attribute.observedEvidence.isNotEmpty)
            const SizedBox(height: 14),
          if (attribute.observedEvidence.isNotEmpty)
            _EvidenceGroup(
              heading: 'Customer-observed evidence',
              items: attribute.observedEvidence,
            ),
          if (attribute.declaredEvidence.isEmpty &&
              attribute.observedEvidence.isEmpty)
            Text(
              'No declared or observed evidence was supplied yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _EvidenceGroup extends StatelessWidget {
  const _EvidenceGroup({required this.heading, required this.items});

  final String heading;
  final List<EvidenceItem> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            heading,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (int index = 0; index < items.length; index += 1) ...<Widget>[
            if (index > 0) const SizedBox(height: 10),
            Text(
              _formatEvidenceItem(items[index]),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatEvidenceItem(EvidenceItem item) {
  final List<String> parts = <String>[
    item.summary,
    if (item.confidence != null) _confidenceLabel(item.confidence!),
    if (item.recencyLabel != null) item.recencyLabel!,
  ];
  return parts.join(' • ');
}

class _ExternalActionsSection extends StatelessWidget {
  const _ExternalActionsSection({
    required this.actions,
    required this.launchingAction,
    required this.onLaunchAction,
  });

  final List<PlaceExternalAction> actions;
  final PlaceExternalAction? launchingAction;
  final ValueChanged<PlaceExternalAction> onLaunchAction;

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Practical actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions
                .map((PlaceExternalAction action) {
                  return FilledButton.tonalIcon(
                    key: PlaceDetailRoute.actionButtonKey(action.type),
                    onPressed: launchingAction == null
                        ? () => onLaunchAction(action)
                        : null,
                    icon: Icon(_iconForAction(action.type)),
                    label: Text(action.label),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

IconData _iconForAction(PlaceActionType actionType) {
  return switch (actionType) {
    PlaceActionType.directions => Icons.directions_rounded,
    PlaceActionType.website => Icons.public_rounded,
    PlaceActionType.call => Icons.call_rounded,
    PlaceActionType.reservation => Icons.event_available_rounded,
  };
}

class _ActionFailureSurface extends StatelessWidget {
  const _ActionFailureSurface({
    required this.state,
    required this.onRetry,
    required this.onCopy,
  });

  final _ActionFailureState state;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final String? copyLabel = state.failure.fallbackCopyValue == null
        ? null
        : switch (state.action.type) {
            PlaceActionType.directions => 'Copy address',
            PlaceActionType.website => 'Copy link',
            PlaceActionType.call => 'Copy number',
            PlaceActionType.reservation => 'Copy link',
          };

    return SectionSurface(
      key: PlaceDetailRoute.actionFailureKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Could not open ${state.action.label}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            state.failure.userMessage,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (onRetry != null)
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              if (onCopy != null && copyLabel != null)
                TextButton(onPressed: onCopy, child: Text(copyLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ActionFailureState {
  const _ActionFailureState({required this.action, required this.failure});

  final PlaceExternalAction action;
  final ExternalActionLaunchFailure failure;
}
