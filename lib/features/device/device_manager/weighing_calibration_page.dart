import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/features/device/active_device_provider.dart';

class WeighingCalibrationPage extends StatefulWidget {
  const WeighingCalibrationPage({super.key});

  @override
  State<WeighingCalibrationPage> createState() => _WeighingCalibrationPageState();
}

class _WeighingCalibrationPageState extends State<WeighingCalibrationPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late TextEditingController _weightCtrl;
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _textColor = const Color(0xFF333333);
  final Color _hintColor = const Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActiveDeviceProvider>();
      _weightCtrl.text = provider.savedCalibrationWeight.toString();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightCtrl.dispose();
    _isProcessing.dispose();
    super.dispose();
  }

  Future<void> _nextStep(ActiveDeviceProvider provider, S s) async {
    if (_currentStep == 0) {
      _isProcessing.value = true;
      final success = await provider.startCalibrationStep1();
      if (mounted) _isProcessing.value = false;
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.errorMsg.isNotEmpty ? provider.errorMsg : s.operationFailed)));
        }
        return;
      }
    } else if (_currentStep == 1) {
      final weight = int.tryParse(_weightCtrl.text.trim());
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.invalidWeightError)));
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (_currentStep == 2) {
      final weight = int.parse(_weightCtrl.text.trim());
      _isProcessing.value = true;
      final success = await provider.submitCalibrationStep3(weight);
      if (mounted) _isProcessing.value = false;
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.errorMsg.isNotEmpty ? provider.errorMsg : s.operationFailed)));
        }
        return;
      }
    } else if (_currentStep == 3) {
      context.pop();
      return;
    }

    setState(() {
      _currentStep++;
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final provider = context.read<ActiveDeviceProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 540,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildStep1(s), _buildStep2(s), _buildStep3(s), _buildStep4(s)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isActive = _currentStep == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? _primaryPurple : const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isProcessing,
                      builder: (context, isProcessing, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            onPressed: isProcessing ? null : () => _nextStep(provider, s),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _currentStep == 3 ? s.done : s.nextStep,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.scaleStep1Title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 16),
          Text(s.scaleStep1Desc, style: TextStyle(fontSize: 14, color: _primaryPurple, height: 1.6)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(Icons.check_circle, color: _primaryPurple, size: 28),
                  const SizedBox(height: 12),
                  Icon(Icons.crop_square_rounded, size: 84, color: Colors.grey.shade300),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.cancel, color: Color(0xFFF37474), size: 28),
                  const SizedBox(height: 12),
                  Icon(Icons.dashboard_customize_outlined, size: 84, color: Colors.grey.shade300),
                ],
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep2(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.scaleStep2Title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 16),
          Text(s.scaleStep2Desc, style: TextStyle(fontSize: 14, color: _primaryPurple, height: 1.6)),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 18, color: _textColor, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: s.enterWeightInGrams,
                      hintStyle: TextStyle(color: _hintColor, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Text(
                  'g',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(s.selectObjectFromList, style: TextStyle(fontSize: 13, color: _hintColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.scaleStep3Title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 16),
          Text(s.scaleStep3Desc, style: TextStyle(fontSize: 14, color: _primaryPurple, height: 1.6)),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(Icons.local_drink_rounded, size: 96, color: _primaryPurple),
                const SizedBox(height: 20),
                Text(s.scaleStep3Desc, style: TextStyle(fontSize: 14, color: _hintColor)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStep4(S s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            s.scaleStep4Title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 12),
          Text(s.scaleStep4Desc, style: TextStyle(fontSize: 14, color: _hintColor)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.album_outlined, size: 90, color: Colors.grey.shade400),
              const SizedBox(width: 24),
              Column(
                children: [
                  Icon(Icons.check_circle, color: _primaryPurple, size: 36),
                  const SizedBox(height: 16),
                  const Icon(Icons.pets, size: 50, color: Colors.grey),
                ],
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
