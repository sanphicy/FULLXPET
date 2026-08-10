import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/features/device/device_provider.dart';
import 'package:fullxpet/features/device/device_usage/device_usage_provider.dart';
import 'package:fullxpet/routes/app_router.dart';

class DeviceUsagePage extends StatefulWidget {
  const DeviceUsagePage({super.key});

  @override
  State<DeviceUsagePage> createState() => _DeviceUsagePageState();
}

class _DeviceUsagePageState extends State<DeviceUsagePage> {
  // 浅紫风格配色体系
  final Color _primaryPurple = const Color(0xFF917CEE);
  final Color _bgColor = const Color(0xFFF9F9FC);
  final Color _textColor = const Color(0xFF333333);
  final Color _subTextColor = const Color(0xFF666666);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceProvider = context.read<DeviceProvider>();
      context.read<DeviceUsageProvider>().syncDevices(deviceProvider.devices);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final usageProvider = context.watch<DeviceUsageProvider>();

    if (deviceProvider.devices.length != usageProvider.deviceList.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        usageProvider.syncDevices(deviceProvider.devices);
      });
    }

    final selectedData = usageProvider.selectedDayData;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '数据统计',
          style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: usageProvider.isLoading && usageProvider.weekDays.isEmpty
          ? Center(child: CircularProgressIndicator(color: _primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==============================
                  // 1. 顶部设备切换列表卡片
                  // ==============================
                  Container(
                    height: 95,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: usageProvider.deviceList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == usageProvider.deviceList.length) {
                          return GestureDetector(
                            onTap: () => context.push(AppRoutes.deviceAddSearch),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _primaryPurple.withOpacity(0.5), width: 1),
                                      color: _primaryPurple.withOpacity(0.05),
                                    ),
                                    child: Icon(Icons.add, color: _primaryPurple),
                                  ),
                                  const SizedBox(height: 5),
                                  Text('添加设备', style: TextStyle(fontSize: 11, color: _subTextColor)),
                                ],
                              ),
                            ),
                          );
                        }
                        final isSelected = usageProvider.selectedDeviceIndex == index;
                        final device = usageProvider.deviceList[index];
                        return GestureDetector(
                          onTap: () => usageProvider.selectDevice(index),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? _primaryPurple : Colors.transparent,
                                      width: 2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Image.asset('assets/images/product-pic.png', fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 5),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? _primaryPurple : _subTextColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  ),
                                  child: Text(device.deviceName),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==============================
                  // 2. 7天选择卡片 (周/日) - 平滑颜色过渡
                  // ==============================
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(usageProvider.weekDays.length, (index) {
                        final isSelected = usageProvider.selectedDayIndex == index;
                        final dayData = usageProvider.weekDays[index];
                        return GestureDetector(
                          onTap: () => usageProvider.selectDay(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            width: 42,
                            height: 56,
                            decoration: BoxDecoration(
                              // 明确指定纯紫与纯白，绝不使用 transparent
                              color: isSelected ? _primaryPurple : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white.withOpacity(0.8) : _subTextColor,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  ),
                                  child: Text(dayData.weekDay),
                                ),
                                const SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : _textColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  ),
                                  child: Text(dayData.dayStr),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==============================
                  // 3. 核心统计指标卡片
                  // ==============================
                  Row(
                    children: [
                      _buildStatCard('如厕次数', '${selectedData?.times ?? 0}', '次', Icons.pets_rounded),
                      const SizedBox(width: 15),
                      _buildStatCard('如厕时长', '${selectedData?.duration ?? 0}', '秒', Icons.timer_outlined),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ==============================
                  // 4. 如厕次数趋势图表
                  // ==============================
                  Text(
                    '如厕次数趋势',
                    style: TextStyle(fontSize: 16, color: _textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 210,
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _buildLineChart(usageProvider, isTimes: true),
                  ),
                  const SizedBox(height: 25),

                  // ==============================
                  // 5. 如厕时长趋势图表
                  // ==============================
                  Text(
                    '如厕时长趋势',
                    style: TextStyle(fontSize: 16, color: _textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 210,
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _buildLineChart(usageProvider, isTimes: false),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  /// 数据统计卡片
  Widget _buildStatCard(String title, String value, String unit, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: _subTextColor, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _primaryPurple.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: _primaryPurple),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textColor, height: 1),
                ),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: _subTextColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// LineChart 折线图绘制（保留全部 FlSpot 与 Provider 数据流）
  Widget _buildLineChart(DeviceUsageProvider provider, {bool isTimes = false}) {
    final List<FlSpot> spots = provider.weekDays.asMap().entries.map((e) {
      final val = isTimes ? e.value.times : e.value.duration;
      return FlSpot(e.key.toDouble(), val.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF0EFF5), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx >= 0 && idx < provider.weekDays.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(provider.weekDays[idx].weekDay, style: TextStyle(fontSize: 11, color: _subTextColor)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}${isTimes ? '次' : '秒'}',
                  style: TextStyle(fontSize: 10, color: _subTextColor),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E5EE), width: 1)),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: _primaryPurple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2.5, strokeColor: _primaryPurple),
            ),
            belowBarData: BarAreaData(show: true, color: _primaryPurple.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }
}
