import 'package:accessibility_frontend/contracts/authentication_gateway.dart';
import 'package:accessibility_frontend/design_system/app_colors.dart';
import 'package:accessibility_frontend/domain/authentication/authentication_models.dart';
import 'package:accessibility_frontend/features/onboarding/presentation/widgets/bubble_backdrop.dart';
import 'package:flutter/material.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({
    required this.gateway,
    required this.onBack,
    required this.onAuthenticated,
    required this.onTerms,
    required this.onPrivacy,
    this.initialOperation = AuthenticationOperation.signUp,
    super.key,
  });

  final AuthenticationGateway gateway;
  final VoidCallback onBack;
  final ValueChanged<AuthenticationNextStep> onAuthenticated;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final AuthenticationOperation initialOperation;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;
  late AuthenticationOperation _operation;
  AuthenticationFailureReason? _failureReason;
  bool _autoValidate = false;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _operation = widget.initialOperation;
    _emailFocusNode = FocusNode(debugLabel: 'Authentication email');
    _passwordFocusNode = FocusNode(debugLabel: 'Authentication password');
    _confirmPasswordFocusNode = FocusNode(
      debugLabel: 'Authentication confirm password',
    );
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Duration get _motionDuration => prefersReducedMotion(context)
      ? const Duration(milliseconds: 90)
      : const Duration(milliseconds: 220);

  bool get _isSignUp => _operation == AuthenticationOperation.signUp;

  String get _headline => _isSignUp ? 'Create account' : 'Welcome back';

  String get _supportText => _isSignUp
      ? 'Save your answers so your accessibility profile and next steps stay together.'
      : 'Sign in to continue with your saved profile, progress, and recommendations.';

  String get _submitLabel => _isSignUp ? 'Create account' : 'Sign in';

  void _handleModeChanged(Set<AuthenticationOperation> selection) {
    if (_isSubmitting || selection.isEmpty) {
      return;
    }

    final AuthenticationOperation nextOperation = selection.first;
    if (nextOperation == _operation) {
      return;
    }

    setState(() {
      _operation = nextOperation;
      _failureReason = null;
      _autoValidate = false;
      if (nextOperation == AuthenticationOperation.signIn) {
        _confirmPasswordController.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      _passwordFocusNode.requestFocus();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _autoValidate = true;
      _failureReason = null;
    });

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    late final AuthenticationResult result;
    try {
      result = _isSignUp
          ? await widget.gateway.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await widget.gateway.signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case AuthenticationSuccess success:
        widget.onAuthenticated(success.nextStep);
      case AuthenticationFailure failure:
        setState(() => _failureReason = failure.reason);
    }
  }

  String? _validateEmail(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return 'Enter your email.';
    }
    const String pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (!_isSignUp) {
      return null;
    }
    final String confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return 'Confirm your password.';
    }
    if (confirmation != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: AppColors.outline),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: AppColors.primaryStrong,
          width: 1.6,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }

  Widget _buildVisibilityButton({
    required Key key,
    required bool visible,
    required String fieldName,
    required VoidCallback onPressed,
  }) {
    final String label = visible
        ? 'Hide $fieldName password'
        : 'Show $fieldName password';

    return IconButton(
      key: key,
      isSelected: visible,
      tooltip: label,
      onPressed: onPressed,
      icon: const Icon(
        Icons.visibility_rounded,
        color: AppColors.primaryStrong,
      ),
      selectedIcon: const Icon(
        Icons.visibility_off_rounded,
        color: AppColors.primaryStrong,
      ),
    );
  }

  Widget _buildErrorBanner() {
    final AuthenticationFailureReason? failureReason = _failureReason;
    if (failureReason == null) {
      return const SizedBox.shrink();
    }

    final bool showSwitchAction =
        failureReason == AuthenticationFailureReason.accountAlreadyExists &&
        _isSignUp;

    return Container(
      key: const Key('authentication_error_banner'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  failureReason.userMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (failureReason.canRetry || showSwitchAction) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (failureReason.canRetry)
                  TextButton(
                    key: const Key('authentication_retry_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: const Text('Try again'),
                  ),
                if (showSwitchAction)
                  TextButton(
                    key: const Key('switch_to_sign_in_button'),
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleModeChanged(<AuthenticationOperation>{
                            AuthenticationOperation.signIn,
                          }),
                    child: const Text('Sign in instead'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const BubbleBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: FocusTraversalGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const Key('authentication_back_button'),
                              onPressed: _isSubmitting ? null : widget.onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _AuthenticationShell(
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autoValidate
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const _NeutralMark(),
                                  const SizedBox(height: 20),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      _headline,
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _supportText,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 20),
                                  SegmentedButton<AuthenticationOperation>(
                                    key: const Key(
                                      'authentication_mode_switch',
                                    ),
                                    showSelectedIcon: false,
                                    multiSelectionEnabled: false,
                                    segments:
                                        const <
                                          ButtonSegment<AuthenticationOperation>
                                        >[
                                          ButtonSegment<
                                            AuthenticationOperation
                                          >(
                                            value:
                                                AuthenticationOperation.signUp,
                                            label: Text('Create account'),
                                          ),
                                          ButtonSegment<
                                            AuthenticationOperation
                                          >(
                                            value:
                                                AuthenticationOperation.signIn,
                                            label: Text('Sign in'),
                                          ),
                                        ],
                                    selected: <AuthenticationOperation>{
                                      _operation,
                                    },
                                    onSelectionChanged: _isSubmitting
                                        ? null
                                        : _handleModeChanged,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildErrorBanner(),
                                  TextFormField(
                                    key: const Key(
                                      'authentication_email_field',
                                    ),
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    enabled: !_isSubmitting,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const <String>[
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    decoration: _inputDecoration(
                                      label: 'Email',
                                      hint: 'name@example.com',
                                    ),
                                    validator: _validateEmail,
                                    onFieldSubmitted: (_) =>
                                        _passwordFocusNode.requestFocus(),
                                    onChanged: (_) {
                                      if (_failureReason != null) {
                                        setState(() => _failureReason = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    key: const Key(
                                      'authentication_password_field',
                                    ),
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    enabled: !_isSubmitting,
                                    obscureText: !_passwordVisible,
                                    textInputAction: _isSignUp
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    autofillHints: _isSignUp
                                        ? const <String>[
                                            AutofillHints.newPassword,
                                          ]
                                        : const <String>[
                                            AutofillHints.password,
                                          ],
                                    decoration: _inputDecoration(
                                      label: 'Password',
                                      suffixIcon: _buildVisibilityButton(
                                        key: const Key(
                                          'authentication_password_visibility_button',
                                        ),
                                        visible: _passwordVisible,
                                        fieldName: 'main',
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) {
                                      if (_isSignUp) {
                                        _confirmPasswordFocusNode
                                            .requestFocus();
                                        return;
                                      }
                                      _submit();
                                    },
                                    onChanged: (_) {
                                      if (_failureReason != null) {
                                        setState(() => _failureReason = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  AnimatedSize(
                                    duration: _motionDuration,
                                    curve: Curves.easeOutCubic,
                                    child: AnimatedSwitcher(
                                      duration: _motionDuration,
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeOutCubic,
                                      layoutBuilder:
                                          (
                                            Widget? currentChild,
                                            List<Widget> previousChildren,
                                          ) {
                                            return Column(
                                              children: <Widget>[
                                                ...previousChildren,
                                                if (currentChild
                                                    case final Widget child)
                                                  child,
                                              ],
                                            );
                                          },
                                      child: _isSignUp
                                          ? KeyedSubtree(
                                              key: const Key(
                                                'authentication_confirm_password_container',
                                              ),
                                              child: TextFormField(
                                                key: const Key(
                                                  'authentication_confirm_password_field',
                                                ),
                                                controller:
                                                    _confirmPasswordController,
                                                focusNode:
                                                    _confirmPasswordFocusNode,
                                                enabled: !_isSubmitting,
                                                obscureText:
                                                    !_confirmPasswordVisible,
                                                textInputAction:
                                                    TextInputAction.done,
                                                autofillHints: const <String>[
                                                  AutofillHints.newPassword,
                                                ],
                                                decoration: _inputDecoration(
                                                  label: 'Confirm password',
                                                  suffixIcon: _buildVisibilityButton(
                                                    key: const Key(
                                                      'authentication_confirm_password_visibility_button',
                                                    ),
                                                    visible:
                                                        _confirmPasswordVisible,
                                                    fieldName: 'confirmation',
                                                    onPressed: () {
                                                      setState(() {
                                                        _confirmPasswordVisible =
                                                            !_confirmPasswordVisible;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                validator:
                                                    _validateConfirmation,
                                                onFieldSubmitted: (_) =>
                                                    _submit(),
                                                onChanged: (_) {
                                                  if (_failureReason != null) {
                                                    setState(
                                                      () =>
                                                          _failureReason = null,
                                                    );
                                                  }
                                                },
                                              ),
                                            )
                                          : const SizedBox.shrink(
                                              key: Key(
                                                'authentication_confirm_password_hidden',
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    key: const Key(
                                      'authentication_submit_button',
                                    ),
                                    onPressed: _isSubmitting ? null : _submit,
                                    child: AnimatedSwitcher(
                                      duration: _motionDuration,
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              key: Key(
                                                'authentication_loading_indicator',
                                              ),
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.6,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _submitLabel,
                                              key: const Key(
                                                'authentication_submit_label',
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: <Widget>[
                                        Text(
                                          'Need the details?',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        TextButton(
                                          key: const Key(
                                            'authentication_terms_button',
                                          ),
                                          onPressed: _isSubmitting
                                              ? null
                                              : widget.onTerms,
                                          child: const Text('Terms'),
                                        ),
                                        Text(
                                          'and',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        TextButton(
                                          key: const Key(
                                            'authentication_privacy_button',
                                          ),
                                          onPressed: _isSubmitting
                                              ? null
                                              : widget.onPrivacy,
                                          child: const Text('Privacy'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthenticationShell extends StatelessWidget {
  const _AuthenticationShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.94),
              AppColors.surfaceBlue.withValues(alpha: 0.54),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _NeutralMark extends StatelessWidget {
  const _NeutralMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryStrong,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceBlueStrong,
                      width: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
