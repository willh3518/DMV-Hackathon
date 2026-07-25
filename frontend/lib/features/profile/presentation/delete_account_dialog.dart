import 'package:accessibility_frontend/contracts/profile_gateway.dart';
import 'package:accessibility_frontend/domain/profile/profile_models.dart';
import 'package:flutter/material.dart';

enum _DeletionStage {
  confirmation,
  busy,
  submitted,
  pending,
  failure,
  confirmed,
}

/// Explicit account-deletion confirmation and contract-status flow.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    required this.gateway,
    required this.onDeletionConfirmed,
    super.key,
  });

  static const Key headingKey = Key('delete_account_heading');
  static const Key statusKey = Key('delete_account_status');
  static const Key cancelButtonKey = Key('delete_account_cancel');
  static const Key primaryButtonKey = Key('delete_account_primary');

  final ProfileGateway gateway;
  final VoidCallback onDeletionConfirmed;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final FocusNode _headingFocusNode = FocusNode(
    debugLabel: 'Delete account heading',
  );
  final FocusNode _statusFocusNode = FocusNode(
    debugLabel: 'Delete account status',
  );

  _DeletionStage _stage = _DeletionStage.confirmation;
  ProfileOperationFailureReason? _failureReason;
  bool _retryStatusCheck = false;
  bool _checkingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _headingFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _headingFocusNode.dispose();
    _statusFocusNode.dispose();
    super.dispose();
  }

  bool get _busy => _stage == _DeletionStage.busy;

  Future<void> _requestDeletion() async {
    if (_busy) {
      return;
    }
    setState(() {
      _stage = _DeletionStage.busy;
      _checkingStatus = false;
      _failureReason = null;
    });

    AccountDeletionResult result;
    try {
      result = await widget.gateway.requestAccountDeletion();
    } catch (_) {
      result = const AccountDeletionFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    _applyResult(result, retryStatusCheck: false);
  }

  Future<void> _checkStatus() async {
    if (_busy) {
      return;
    }
    setState(() {
      _stage = _DeletionStage.busy;
      _checkingStatus = true;
      _failureReason = null;
    });

    AccountDeletionResult result;
    try {
      result = await widget.gateway.loadAccountDeletionStatus();
    } catch (_) {
      result = const AccountDeletionFailure(
        reason: ProfileOperationFailureReason.unknown,
      );
    }
    _applyResult(result, retryStatusCheck: true);
  }

  void _applyResult(
    AccountDeletionResult result, {
    required bool retryStatusCheck,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _checkingStatus = false;
      switch (result) {
        case AccountDeletionSubmitted():
          _stage = _DeletionStage.submitted;
        case AccountDeletionPending():
          _stage = _DeletionStage.pending;
        case AccountDeletionConfirmed():
          _stage = _DeletionStage.confirmed;
        case AccountDeletionFailure failure:
          _stage = _DeletionStage.failure;
          _failureReason = failure.reason;
          _retryStatusCheck = retryStatusCheck;
      }
    });
    _requestStatusFocus();
  }

  void _requestStatusFocus() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _statusFocusNode.canRequestFocus) {
        _statusFocusNode.requestFocus();
      }
    });
  }

  void _finishConfirmed() {
    Navigator.of(context).pop();
    widget.onDeletionConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final _DeletionContent content = _content;

    return PopScope<void>(
      canPop: !_busy && _stage != _DeletionStage.confirmed,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Focus(
                  key: DeleteAccountDialog.headingKey,
                  focusNode: _headingFocusNode,
                  skipTraversal: true,
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Delete account',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Focus(
                  focusNode: _statusFocusNode,
                  skipTraversal: _stage == _DeletionStage.confirmation,
                  child: Semantics(
                    key: DeleteAccountDialog.statusKey,
                    container: true,
                    liveRegion: _stage != _DeletionStage.confirmation,
                    label: '${content.title}. ${content.message}',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            content.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(content.message),
                          if (_busy) ...<Widget>[
                            const SizedBox(height: 18),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: DeleteAccountDialog.primaryButtonKey,
                  onPressed: _primaryAction,
                  style: _stage == _DeletionStage.confirmation
                      ? FilledButton.styleFrom(
                          minimumSize: const Size(48, 52),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        )
                      : null,
                  child: Text(_primaryLabel, textAlign: TextAlign.center),
                ),
                if (_stage == _DeletionStage.confirmation) ...<Widget>[
                  const SizedBox(height: 8),
                  TextButton(
                    key: DeleteAccountDialog.cancelButtonKey,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ] else if (!_busy &&
                    _stage != _DeletionStage.confirmed) ...<Widget>[
                  const SizedBox(height: 8),
                  TextButton(
                    key: DeleteAccountDialog.cancelButtonKey,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? get _primaryAction {
    return switch (_stage) {
      _DeletionStage.confirmation => _requestDeletion,
      _DeletionStage.busy => null,
      _DeletionStage.submitted || _DeletionStage.pending => _checkStatus,
      _DeletionStage.failure =>
        _retryStatusCheck ? _checkStatus : _requestDeletion,
      _DeletionStage.confirmed => _finishConfirmed,
    };
  }

  String get _primaryLabel {
    return switch (_stage) {
      _DeletionStage.confirmation => 'Request account deletion',
      _DeletionStage.busy =>
        _checkingStatus ? 'Checking status' : 'Sending request',
      _DeletionStage.submitted => 'Check status',
      _DeletionStage.pending => 'Check again',
      _DeletionStage.failure => 'Retry',
      _DeletionStage.confirmed => 'Done',
    };
  }

  _DeletionContent get _content {
    return switch (_stage) {
      _DeletionStage.confirmation => const _DeletionContent(
        title: 'Send a deletion request?',
        message:
            'If you continue, this app will ask the account service to delete '
            'your account. Your account will not be shown as deleted unless '
            'that service confirms completion.',
      ),
      _DeletionStage.busy => _DeletionContent(
        title: _checkingStatus ? 'Checking request status' : 'Sending request',
        message: _checkingStatus
            ? 'Waiting for the account service to report the current status.'
            : 'Waiting for the account service to accept or reject the request.',
      ),
      _DeletionStage.submitted => const _DeletionContent(
        title: 'Request submitted',
        message:
            'The account service accepted the request. It has not confirmed '
            'account deletion.',
      ),
      _DeletionStage.pending => const _DeletionContent(
        title: 'Request pending',
        message:
            'The account service reports that the request is still pending. '
            'Your account is not shown as deleted.',
      ),
      _DeletionStage.failure => _DeletionContent(
        title: 'Deletion was not confirmed',
        message:
            _failureReason?.userMessage ??
            ProfileOperationFailureReason.unknown.userMessage,
      ),
      _DeletionStage.confirmed => const _DeletionContent(
        title: 'Deletion confirmed',
        message:
            'The account service confirmed completion. Select Done to leave '
            'this account.',
      ),
    };
  }
}

final class _DeletionContent {
  const _DeletionContent({required this.title, required this.message});

  final String title;
  final String message;
}
