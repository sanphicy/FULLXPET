import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../factory_debug_provider.dart';
import '../models/factory_debug_schema.dart';

class FactoryDebugUiView extends StatelessWidget {
  const FactoryDebugUiView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FactoryDebugProvider>();

    // 获取最新接收到的数据包
    Map<String, dynamic>? latestTelemetry;
    for (var log in provider.logs) {
      if (!log.isTx && log.parsedJson != null) {
        latestTelemetry = log.parsedJson;
        break;
      }
    }

    if (latestTelemetry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF917CEE)),
            SizedBox(height: 16.h),
            Text(
              "等待设备下发数据包 (2s/次)...",
              style: TextStyle(color: const Color(0xFF868E96), fontSize: 13.sp),
            ),
          ],
        ),
      );
    }

    final bool hasMotorOverload = latestTelemetry['sensors']?['motor']?['overload_flt'] == true;
    final bool hasResetFlt = latestTelemetry['sensors']?['motor']?['reset_flt'] == true;
    final bool hasErrorAlert = hasMotorOverload || hasResetFlt;
    final bool isMotorStuck = provider.isMotorStuckWarning;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 设备基本信息卡片
          _buildDeviceInfoCard(latestTelemetry),
          SizedBox(height: 12.h),

          // 2. 硬件故障警告（红框）
          if (hasErrorAlert) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFFC9C9), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE03131)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "警告：设备检测到硬件故障！ [${hasMotorOverload ? '电机过载 ' : ''}${hasResetFlt ? '复位失败' : ''}]",
                      style: TextStyle(color: const Color(0xFFE03131), fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
          ],

          // 3. 电机处于“非空闲”但编码器完全停滞无变化（黄色警报）
          if (isMotorStuck) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9DB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFFE066), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE67700)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "提示：电机处于运转/异常状态，但脉冲计数持续未变化！请检查电机是否堵转或接线不良。",
                      style: TextStyle(color: const Color(0xFFD9480F), fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // 4. 传感器与状态网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kFactoryDebugSchemaList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemBuilder: (context, index) {
              final schema = kFactoryDebugSchemaList[index];
              final rawVal = schema.extractValue(latestTelemetry);
              final isAlert = schema.checkIsAlert(rawVal); // 错误标红
              final isInfoHighlight = schema.checkIsInfoHighlight(rawVal); // 霍尔到位（浅蓝色提示）
              final displayStr = schema.getDisplayValue(rawVal);

              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isAlert
                      ? const Color(0xFFFFF5F5)
                      : isInfoHighlight
                      ? const Color(0xFFE7F5FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isAlert
                        ? const Color(0xFFFFC9C9)
                        : isInfoHighlight
                        ? const Color(0xFFA5D8FF)
                        : const Color(0xFFE9ECEF),
                    width: isAlert ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      schema.label,
                      style: TextStyle(
                        color: isAlert
                            ? const Color(0xFFE03131)
                            : isInfoHighlight
                            ? const Color(0xFF1971C2)
                            : const Color(0xFF868E96),
                        fontSize: 12.sp,
                        fontWeight: (isAlert || isInfoHighlight) ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      displayStr,
                      style: TextStyle(
                        color: isAlert
                            ? const Color(0xFFE03131)
                            : isInfoHighlight
                            ? const Color(0xFF1864AB)
                            : const Color(0xFF212529),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MAC: ${data['mac'] ?? 'Unknown'}",
                style: TextStyle(color: const Color(0xFF495057), fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
              Text(
                "固件: v${data['fw_ver'] ?? '-'}",
                style: TextStyle(color: const Color(0xFF495057), fontSize: 12.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DevID: ${data['dev_id'] ?? '-'}",
                style: TextStyle(color: const Color(0xFF868E96), fontSize: 11.sp),
              ),
              Text(
                "模式: ${data['fac_mode'] == true ? '出厂调试' : '常规模式'}",
                style: TextStyle(color: const Color(0xFF917CEE), fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
