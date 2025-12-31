import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sr_ghani/services/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Premium Ghani Management',
      description: 'Streamline your oil business with our modern, offline-first solution.',
      icon: Icons.oil_barrel_rounded,
    ),
    OnboardingData(
      title: 'Real-time Tracking',
      description: 'Monitor every seed and process live, synchronized across all your devices.',
      icon: Icons.track_changes_rounded,
    ),
    OnboardingData(
      title: 'Insights & Growth',
      description: 'Understand your revenue and performance with beautiful analytics.',
      icon: Icons.auto_graph_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: _finishOnboarding,
          child: Text(
            'Keep it simple',
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 60),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDotIndicator(),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          height: 6,
          width: _currentPage == index ? 24 : 6,
          decoration: BoxDecoration(
            color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentPage == _pages.length - 1;
    return GestureDetector(
      onTap: () {
        if (!isLast) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _finishOnboarding();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isLast ? 140 : 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLast
              ? const Text(
                  'Get Started',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                )
              : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _finishOnboarding() async {
    await ref.read(storageServiceProvider).setOnboardingComplete(ref);
    // No manual navigation needed, InitialAuthWrapper watches onboardingStatusProvider
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
