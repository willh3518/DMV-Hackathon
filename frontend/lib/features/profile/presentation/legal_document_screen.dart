import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/design_system/components/section_surface.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:flutter/material.dart';

/// Terms or Privacy content supplied through the Profile contract.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    required this.gateway,
    required this.kind,
    required this.onBack,
    super.key,
  });

  static const Key headingKey = Key('legal_document_heading');
  static const Key loadingKey = Key('legal_document_loading');
  static const Key statusKey = Key('legal_document_status');
  static const Key placeholderKey = Key('legal_document_placeholder');
  static const Key bodyKey = Key('legal_document_body');
  static const Key retryButtonKey = Key('legal_document_retry');
  static const Key backButtonKey = Key('legal_document_back');
  static const Key scrollViewKey = Key('legal_document_scroll_view');

  final ProfileGateway gateway;
  final LegalDocumentKind kind;
  final VoidCallback onBack;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final FocusNode _headingFocusNode = FocusNode(
    debugLabel: 'Legal document heading',
  );
  final FocusNode _statusFocusNode = FocusNode(
    debugLabel: 'Legal document status',
  );

  bool _loading = true;
  LegalContentResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _headingFocusNode.requestFocus();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _headingFocusNode.dispose();
    _statusFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    LegalContentResult result;
    try {
      result = await widget.gateway.loadLegalDocument(widget.kind);
    } catch (_) {
      result = const LegalContentFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _result = result;
    });
    if (result is LegalContentFailure || result is LegalContentUnavailable) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _statusFocusNode.canRequestFocus) {
          _statusFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fallbackTitle = switch (widget.kind) {
      LegalDocumentKind.terms => 'Terms',
      LegalDocumentKind.privacy => 'Privacy',
    };
    final String title = switch (_result) {
      LegalContentLoaded loaded => loaded.document.title,
      _ => fallbackTitle,
    };

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.canvasTop, AppColors.canvasBottom],
        ),
      ),
      child: SafeArea(
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                key: LegalDocumentScreen.scrollViewKey,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: LegalDocumentScreen.backButtonKey,
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Focus(
                      key: LegalDocumentScreen.headingKey,
                      focusNode: _headingFocusNode,
                      skipTraversal: true,
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_loading)
                      _buildLoading(context)
                    else
                      _buildResult(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Semantics(
      key: LegalDocumentScreen.loadingKey,
      liveRegion: true,
      label: 'Loading legal content.',
      child: ExcludeSemantics(
        child: SectionSurface(
          child: Row(
            children: <Widget>[
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Loading content…',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final LegalContentResult? result = _result;
    return switch (result) {
      LegalContentLoaded loaded => _buildLoaded(context, loaded.document),
      LegalContentUnavailable() => _buildUnavailable(context),
      LegalContentFailure failure => _buildFailure(context, failure.reason),
      null => const SizedBox.shrink(),
    };
  }

  Widget _buildLoaded(BuildContext context, LegalDocument document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (document.isPlaceholder) ...<Widget>[
          Semantics(
            key: LegalDocumentScreen.placeholderKey,
            container: true,
            label:
                'Placeholder legal content. This is not production legal '
                'content. Approved content has not been supplied.',
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.surfaceBlueStrong),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Placeholder only — this is not production legal content. '
                    'Approved content has not been supplied.',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionSurface(
          child: SelectableText(
            document.body,
            key: LegalDocumentScreen.bodyKey,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    return _buildStatus(
      context,
      title: 'Content is unavailable',
      message:
          'Approved content has not been supplied in this frontend build. '
          'You can retry without losing your place.',
    );
  }

  Widget _buildFailure(
    BuildContext context,
    ProfileOperationFailureReason reason,
  ) {
    return _buildStatus(
      context,
      title: 'Content did not load',
      message: reason.userMessage,
    );
  }

  Widget _buildStatus(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return Focus(
      focusNode: _statusFocusNode,
      skipTraversal: true,
      child: Semantics(
        key: LegalDocumentScreen.statusKey,
        container: true,
        liveRegion: true,
        label: '$title. $message Retry.',
        onTap: _load,
        child: ExcludeSemantics(
          child: SectionSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 18),
                FilledButton(
                  key: LegalDocumentScreen.retryButtonKey,
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
