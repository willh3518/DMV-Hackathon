import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/contracts/place_detail_gateway.dart';
import 'package:accessibility_frontend/design_system/app_motion.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/place_detail_route.dart';
import 'package:accessibility_frontend/features/recommendations/presentation/recommendation_card.dart';
import 'package:flutter/material.dart';

class RecommendationResultsSection extends StatefulWidget {
  const RecommendationResultsSection({
    required this.recommendations,
    required this.placeDetailGateway,
    required this.externalActionLauncher,
    super.key,
  });

  final List<RecommendationSummary> recommendations;
  final PlaceDetailGateway placeDetailGateway;
  final ExternalActionLauncher externalActionLauncher;

  @override
  State<RecommendationResultsSection> createState() =>
      _RecommendationResultsSectionState();
}

class _RecommendationResultsSectionState
    extends State<RecommendationResultsSection> {
  final Map<String, FocusNode> _detailsFocusNodes = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _syncFocusNodes();
  }

  @override
  void didUpdateWidget(RecommendationResultsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendations != widget.recommendations) {
      _syncFocusNodes();
    }
  }

  @override
  void dispose() {
    for (final FocusNode focusNode in _detailsFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes() {
    final Set<String> nextIds = widget.recommendations
        .map((RecommendationSummary recommendation) => recommendation.id)
        .toSet();
    final List<String> removedIds = _detailsFocusNodes.keys
        .where((String id) => !nextIds.contains(id))
        .toList(growable: false);
    for (final String id in removedIds) {
      _detailsFocusNodes.remove(id)?.dispose();
    }
    for (final RecommendationSummary recommendation in widget.recommendations) {
      _detailsFocusNodes.putIfAbsent(
        recommendation.id,
        () => FocusNode(debugLabel: 'Details ${recommendation.placeName}'),
      );
    }
  }

  Future<void> _openDetails(RecommendationSummary recommendation) async {
    final FocusNode originFocusNode = _detailsFocusNodes[recommendation.id]!;
    final bool reduceMotion = AppMotion.prefersReducedMotion(context);
    final Duration transitionDuration = AppMotion.resolveDuration(context);

    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: 'place_detail_${recommendation.id}'),
        transitionDuration: transitionDuration,
        reverseTransitionDuration: transitionDuration,
        pageBuilder:
            (
              BuildContext routeContext,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return PlaceDetailRoute(
                recommendation: recommendation,
                placeDetailGateway: widget.placeDetailGateway,
                externalActionLauncher: widget.externalActionLauncher,
                onClose: () => Navigator.of(routeContext).pop<void>(),
              );
            },
        transitionsBuilder:
            (
              BuildContext routeContext,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curved = CurvedAnimation(
                parent: animation,
                curve: AppMotion.standardCurve,
                reverseCurve: AppMotion.standardCurve,
              );
              final Offset beginOffset = reduceMotion
                  ? Offset.zero
                  : const Offset(0, 0.03);
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
      ),
    );

    if (!mounted) {
      return;
    }
    _restoreDetailsFocus(originFocusNode);
  }

  void _restoreDetailsFocus(FocusNode focusNode) {
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) {
      return Text(
        'Recommendations will appear here after a supported discovery result is supplied.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Recommended for this request',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        for (int index = 0; index < widget.recommendations.length; index += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == widget.recommendations.length - 1 ? 0 : 14,
            ),
            child: RecommendationCard(
              recommendation: widget.recommendations[index],
              detailsFocusNode:
                  _detailsFocusNodes[widget.recommendations[index].id]!,
              onOpenDetails: () => _openDetails(widget.recommendations[index]),
            ),
          ),
      ],
    );
  }
}
