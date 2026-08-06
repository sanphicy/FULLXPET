import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController();
    // 初始化时从 Provider 中读取持久化的重量
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActiveDeviceProvider>();
      _weightCtrl.text = provider.savedCalibrationWeight.toString();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _nextStep(ActiveDeviceProvider provider) async {
    if (_currentStep == 0) {
      // 第一步：点击下一步前，验证在线和空闲，并发送 DPID 27
      final success = await provider.startCalibrationStep1();
      if (!success) return;
    } else if (_currentStep == 1) {
      // 第二步：验证重量输入是否合法（先不发请求，只是拦截）
      final weight = int.tryParse(_weightCtrl.text.trim());
      if (weight == null || weight <= 0) {
        provider.setError("Please enter a valid weight");
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (_currentStep == 2) {
      // 第三步：点击下一步，保存重量并发送 DPID 30 & 28
      final weight = int.parse(_weightCtrl.text.trim());
      final success = await provider.submitCalibrationStep3(weight);
      if (!success) return;
    } else if (_currentStep == 3) {
      // 第四步：完成，退出页面
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
    final provider = context.watch<ActiveDeviceProvider>();
    const Color primaryColor = Color(0xFFF3D14B); // 契合 UI 的黄色

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁用手势滑动，只能通过按钮控制
                children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4()],
              ),
            ),

            // 底部指示器与按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  // 圆点指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = _currentStep == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF8CC152) : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 25),

                  // 底部操作按钮
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: provider.isLoading ? null : () => _nextStep(provider),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 3 ? 'Done' : 'Next Step',
                            style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 步骤 1：确保平地无遮挡 =================
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weighing calibration', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text(
            '· Ensure that there are no obstacles around the litter box\n'
            '· Ensure that the litter box is placed on a flat and hard floor',
            style: TextStyle(fontSize: 14, color: Color(0xFF8CC152), height: 1.5),
          ),
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 正确示例图标
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF8CC152), size: 24),
                  const SizedBox(height: 10),
                  Icon(Icons.crop_square, size: 80, color: Colors.grey.shade400), // 用正方形图标替代正确放置
                ],
              ),
              // 错误示例图标
              Column(
                children: [
                  const Icon(Icons.cancel, color: Color(0xFFF37474), size: 24),
                  const SizedBox(height: 10),
                  Icon(Icons.dashboard_customize, size: 80, color: Colors.grey.shade400), // 用堆叠图标替代错误放置
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 步骤 2：输入砝码重量 =================
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose object of reference', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text(
            '· Ensure that the reference object is between 1000g-5000g',
            style: TextStyle(fontSize: 14, color: Color(0xFF8CC152), height: 1.5),
          ),
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Enter weight in grams', border: InputBorder.none),
                  ),
                ),
                const Text('g', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text('Select the objectfrom the list', style: TextStyle(fontSize: 14, color: Color(0xFF8CC152))),
          ),
        ],
      ),
    );
  }

  // ================= 步骤 3：放入参考物 =================
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Put the reference object into the device',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.local_drink, size: 100, color: Colors.blue.shade300), // 用水瓶Icon替代农夫山泉
                const SizedBox(height: 30),
                const Text(
                  'Put the reference object into the device',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8CC152)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 步骤 4：校准完成 =================
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text('Calibration completed', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.album_outlined, size: 100, color: Colors.grey.shade400), // 设备Icon
              const SizedBox(width: 20),
              const Column(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF8CC152), size: 30),
                  SizedBox(height: 20),
                  Icon(Icons.pets, size: 60, color: Colors.grey), // 猫咪Icon
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
