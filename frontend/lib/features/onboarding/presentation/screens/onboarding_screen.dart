import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<Map<String, String>> _data = [
    {'image': 'assets/images/onboard1.jpg','title': 'Проектирование и установка дорожек','subtitle': 'от Brunswick и QubicaAMF'},
    {'image': 'assets/images/onboard2.jpg','title': 'Модернизация и обновление оборудования','subtitle': 'чтобы ваш бизнес оставался в авангарде технологических инноваций'},
    {'image': 'assets/images/onboard3.jpg','title': 'Обучение и техническая поддержка','subtitle': 'наши квалифицированные специалисты всегда готовы прийти на помощь'},
  ];

  Future<void> _finish() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('first_run_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_data.length, (i) {
        final isActive = i == _index;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: isActive ? const EdgeInsets.all(3) : EdgeInsets.zero,
          decoration: isActive
              ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2))
              : null,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.darkGray,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFFD7D7D7),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _data.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(33.05),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0, 0, 0, 1, 0,
                              ]),
                              child: Image.asset(
                                _data[i]['image']!,
                                width: 336,
                                height: 438.45,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildIndicator(),
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: screen.width * 0.9,
                                  child: Text(
                                    _data[i]['title']!,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.onboardingTitle,
                                    softWrap: true,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: screen.width * 0.95,
                                  child: Text(
                                    _data[i]['subtitle']!,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.onboardingSubtitle,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                width: 120,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFD),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0F0F0F),
                      offset: Offset(0, 40),
                      blurRadius: 32,
                      spreadRadius: -24,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _index > 0
                          ? () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                          : null,
                      child: Opacity(
                        opacity: _index > 0 ? 1.0 : 0.3,
                        child: Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_index < _data.length - 1) {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else {
                          _finish();
                        }
                      },
                      child: Icon(Icons.arrow_forward_ios, color: AppColors.textDark, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
