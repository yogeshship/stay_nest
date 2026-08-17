import 'package:flutter/material.dart';

import '../models/app_user_model.dart';
import '../models/verification_request_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/verification_service.dart';

class OwnerVerificationRequestScreen extends StatefulWidget {
  const OwnerVerificationRequestScreen({super.key});

  static const Color primaryColor = Color(0xFF6C3BFF);
  static const Color bgColor = Color(0xFFF8F7FC);

  @override
  State<OwnerVerificationRequestScreen> createState() =>
      _OwnerVerificationRequestScreenState();
}

class _OwnerVerificationRequestScreenState
    extends State<OwnerVerificationRequestScreen> {
  final VerificationService _verificationService = VerificationService();
  Stream<AppUserModel?>? _profileStream;
  Stream<VerificationRequestModel?>? _requestStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      _profileStream = UserService().watchUserProfile(user.uid);
      _requestStream = _verificationService.watchMyVerificationRequest();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _verificationService.submitVerificationRequest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted for review.'),
          backgroundColor: OwnerVerificationRequestScreen.primaryColor,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyVerificationError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerVerificationRequestScreen.bgColor,
      appBar: AppBar(
        backgroundColor: OwnerVerificationRequestScreen.bgColor,
        elevation: 0,
        title: const Text(
          'Owner Verification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _profileStream == null || _requestStream == null
          ? const _VerificationMessage(
              icon: Icons.lock_outline,
              title: 'Owner sign-in required',
              message:
                  'Sign in with an active owner account before requesting verification.',
            )
          : StreamBuilder<AppUserModel?>(
              stream: _profileStream,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (profileSnapshot.hasError || profileSnapshot.data == null) {
                  return const _VerificationMessage(
                    icon: Icons.error_outline,
                    title: 'Profile unavailable',
                    message:
                        'Your owner profile could not be loaded. Please try again.',
                  );
                }
                final profile = profileSnapshot.data!;
                if (profile.role != 'owner' || !profile.isActive) {
                  return const _VerificationMessage(
                    icon: Icons.lock_outline,
                    title: 'Owner access required',
                    message:
                        'Only an active owner account can request verification.',
                  );
                }
                return StreamBuilder<VerificationRequestModel?>(
                  stream: _requestStream,
                  builder: (context, requestSnapshot) {
                    if (requestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (requestSnapshot.hasError) {
                      return const _VerificationMessage(
                        icon: Icons.error_outline,
                        title: 'Request unavailable',
                        message:
                            'Your verification request could not be loaded.',
                      );
                    }
                    return _VerificationState(
                      profile: profile,
                      request: requestSnapshot.data,
                      isSubmitting: _isSubmitting,
                      onSubmit: _submit,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _VerificationState extends StatelessWidget {
  const _VerificationState({
    required this.profile,
    required this.request,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final AppUserModel profile;
  final VerificationRequestModel? request;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final status = profile.verificationStatus;
    final isApproved = status == AppUserModel.approvedVerification;
    final isPending = status == AppUserModel.pendingVerification;
    final isRejected = status == AppUserModel.rejectedVerification;
    final rejectionReason = request?.rejectionReason?.trim();

    final icon = isApproved
        ? Icons.verified_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : isRejected
                ? Icons.cancel_outlined
                : Icons.verified_user_outlined;
    final title = isApproved
        ? 'Owner verification approved'
        : isPending
            ? 'Verification under review'
            : isRejected
                ? 'Verification request rejected'
                : 'Build trust with owner verification';
    final message = isApproved
        ? 'Your owner account is approved for trusted owner actions.'
        : isPending
            ? 'Your verification request is under review.'
            : isRejected
                ? 'You may submit a new request for trusted project administration to review.'
                : 'Verification is required before publishing or changing listings and responding to customer inquiries.';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          icon,
          size: 68,
          color: isApproved
              ? Colors.green
              : isRejected
                  ? Colors.red
                  : OwnerVerificationRequestScreen.primaryColor,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.5),
        ),
        if (isRejected && rejectionReason?.isNotEmpty == true) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Reason: $rejectionReason'),
          ),
        ],
        if (!isApproved && !isPending) ...[
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OwnerVerificationRequestScreen.primaryColor,
              ),
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isRejected
                          ? 'Request Verification Again'
                          : 'Request Verification',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Requests are currently reviewed by trusted StayNest project administration. Approval is not automatic.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _VerificationMessage extends StatelessWidget {
  const _VerificationMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
