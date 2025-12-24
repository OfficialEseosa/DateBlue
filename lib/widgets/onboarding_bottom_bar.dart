import 'package:flutter/material.dart';

/// Reusable bottom navigation bar for onboarding steps
class OnboardingBottomBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final VoidCallback? onSkip;
  final bool isLoading;
  final bool canContinue;
  final String continueText;
  final String skipText;

  const OnboardingBottomBar({
    super.key,
    this.onBack,
    required this.onContinue,
    this.onSkip,
    this.isLoading = false,
    this.canContinue = true,
    this.continueText = 'Continue',
    this.skipText = 'Skip for now',
  });

  @override
  Widget build(BuildContext context) {
    // If onSkip is provided, use the stacked layout (Continue on top, Skip below)
    if (onSkip != null) {
      return _buildSkippableLayout();
    }
    
    // Otherwise use the standard layout (Back button + Continue)
    return _buildStandardLayout();
  }

  Widget _buildStandardLayout() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (only show if onBack is provided)
          if (onBack != null) ...[
            SizedBox(
              height: 50,
              width: 50,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Continue button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading || !canContinue ? null : onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0039A6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        continueText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkippableLayout() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row with Back button + Continue button
            Row(
              children: [
                // Back button (if provided)
                if (onBack != null) ...[
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Continue Button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading || !canContinue ? null : onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0039A6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              continueText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Skip Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: isLoading ? null : onSkip,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  skipText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isLoading ? Colors.grey[400] : const Color(0xFF0039A6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
