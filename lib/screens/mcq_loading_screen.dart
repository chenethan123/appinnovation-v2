import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mcq_provider.dart';
import 'mcq_quiz_screen.dart';

/// Full-screen loading view for generating AI questions
class MCQLoadingScreen extends ConsumerStatefulWidget {
  final String subjectName;

  const MCQLoadingScreen({
    super.key,
    required this.subjectName,
  });

  @override
  ConsumerState<MCQLoadingScreen> createState() => _MCQLoadingScreenState();
}

class _MCQLoadingScreenState extends ConsumerState<MCQLoadingScreen> {
  bool _isRetrying = false;
  String? _errorMessage;
  int _retryAttempt = 0;

  @override
  void initState() {
    super.initState();
    // Start generating after build completes to avoid provider modification error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateQuestion();
    });
  }

  Future<void> _generateQuestion() async {
    if (!mounted) return;

    setState(() {
      _isRetrying = _retryAttempt > 0;
      _errorMessage = null;
    });

    try {
      _retryAttempt++;
      
      print('🔄 Loading screen: Generating MCQ for ${widget.subjectName}...');
      
      // Generate MCQ for the selected subject
      await ref.read(mcqQuizProvider.notifier).generateMCQ(widget.subjectName);
      
      if (!mounted) return;

      // Verify MCQ was actually generated
      final quizState = ref.read(mcqQuizProvider);
      print('✅ Loading screen: Generation complete. MCQ exists: ${quizState.currentMCQ != null}');
      
      if (quizState.currentMCQ == null) {
        throw Exception('MCQ generation failed - no question returned');
      }

      print('🚀 Loading screen: Navigating to quiz screen...');
      
      // Success - navigate to quiz screen with smooth transition
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MCQQuizScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade transition for smooth experience
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      
      print('✅ Loading screen: Navigation initiated');
    
    } catch (error) {
      if (!mounted) return;

      final errorString = error.toString();
      print('❌ MCQ generation error (attempt $_retryAttempt): $errorString');
      
      // Auto-retry for ALL errors up to max attempts
      if (_retryAttempt < 3) {
        setState(() {
          _isRetrying = true;
          _errorMessage = null; // Clear error, show loading
        });
        
        // Wait before retry with exponential backoff
        final waitSeconds = 2 * _retryAttempt;
        print('⏳ Waiting ${waitSeconds}s before retry...');
        await Future.delayed(Duration(seconds: waitSeconds));
        
        if (mounted) {
          _generateQuestion();
        }
        return;
      }
      
      // Max retries exhausted - auto-navigate back
      print('❌ Max retries exhausted. Navigating back...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getFriendlyErrorMessage(errorString)),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        
        // Auto-navigate back after brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('403')) {
      return 'Unable to generate question.\nPlease check your API access.';
    } else if (error.contains('429')) {
      return 'AI service is busy.\nPlease try again in a moment.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection issue.\nPlease check your internet.';
    } else {
      return 'Unable to generate question.\nPlease try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or error indicator
                if (_errorMessage == null)
                  Icon(
                    Icons.psychology,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.error,
                  ),
                
                const SizedBox(height: 32),
                
                // Loading indicator
                if (_errorMessage == null)
                  Column(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                
                // Main message
                Text(
                  _errorMessage ?? (_isRetrying 
                    ? 'AI is busy—retrying...' 
                    : 'Generating question...'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                if (_errorMessage == null)
                  Text(
                    _isRetrying
                      ? 'Attempt ${_retryAttempt} of 3'
                      : 'Creating a fresh AI question for ${widget.subjectName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 40),
                
                // Cancel button only during loading/retry
                if (_errorMessage == null)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
