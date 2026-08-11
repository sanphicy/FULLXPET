/// 单个传感器的物模型定义项
class DebugSchemaItem {
  final String jsonPath; // 例如: "sensors.io_state.hall_1"
  final String label; // UI 显示名称
  final String unit; // 单位
  final dynamic alertValue; // 当值等于该设定值时，触发标红警告
  final dynamic infoValue; // 当值等于该设定值时（如 1），触发浅蓝/浅绿“感应到”提示，不标红
  final double? alertMin; // 当数值小于该值时标红
  final double? alertMax; // 当数值大于该值时标红
  final Map<dynamic, String>? enumMap; // 枚举映射表

  const DebugSchemaItem({
    required this.jsonPath,
    required this.label,
    this.unit = '',
    this.alertValue,
    this.infoValue,
    this.alertMin,
    this.alertMax,
    this.enumMap,
  });

  /// 从嵌套 Map 中提取值
  dynamic extractValue(Map<String, dynamic>? data) {
    if (data == null) return null;
    List<String> keys = jsonPath.split('.');
    dynamic current = data;
    for (String key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// 检查当前值是否处于异常/错误状态（标红警告）
  bool checkIsAlert(dynamic rawVal) {
    if (rawVal == null) return false;

    if (alertValue != null) {
      if (rawVal.toString() == alertValue.toString()) return true;
    }

    if (rawVal is num) {
      if (alertMin != null && rawVal < alertMin!) return true;
      if (alertMax != null && rawVal > alertMax!) return true;
    }

    return false;
  }

  /// 检查当前值是否处于“正常感应到/定位到位”状态（浅蓝色高亮）
  bool checkIsInfoHighlight(dynamic rawVal) {
    if (rawVal == null || checkIsAlert(rawVal)) return false;
    if (infoValue != null && rawVal.toString() == infoValue.toString()) {
      return true;
    }
    return false;
  }

  /// 获取格式化后的 UI 字符串
  String getDisplayValue(dynamic rawVal) {
    if (rawVal == null) return "N/A";

    if (enumMap != null && enumMap!.containsKey(rawVal)) {
      return enumMap![rawVal]!;
    }

    if (rawVal is bool) {
      return rawVal ? "触发 / ON" : "正常 / OFF";
    }

    return "$rawVal$unit";
  }
}

/// 标准物模型配置列表
final List<DebugSchemaItem> kFactoryDebugSchemaList = [
  // --- 称重系统 ---
  const DebugSchemaItem(
    jsonPath: 'sensors.weight.weight_g',
    label: '称重重量',
    unit: ' g',
    alertMin: -100,
    alertMax: 15000,
  ),
  const DebugSchemaItem(jsonPath: 'sensors.weight.raw_adc', label: '称重 ADC 原始值'),
  const DebugSchemaItem(jsonPath: 'sensors.weight.bin_limit_sw', label: '集便舱限位开关', alertValue: true),

  // --- IO & 霍尔/红外传感器 ---
  // 霍尔定位传感器：alertValue 为 null（绝对不标红），infoValue 设为 1（感应到时浅蓝色高亮）
  const DebugSchemaItem(
    jsonPath: 'sensors.io_state.hall_1',
    label: '中间霍尔定位',
    infoValue: 1,
    enumMap: {0: '未感应 (0)', 1: '已到位 (1)'},
  ),
  const DebugSchemaItem(
    jsonPath: 'sensors.io_state.hall_2',
    label: '侧边霍尔定位',
    infoValue: 1,
    enumMap: {0: '未感应 (0)', 1: '已到位 (1)'},
  ),
  const DebugSchemaItem(jsonPath: 'sensors.io_state.ir_left', label: '设备右侧红外', alertValue: 1),
  const DebugSchemaItem(jsonPath: 'sensors.io_state.ir_right', label: '设备左侧红外', alertValue: 1),

  // --- 电机与故障标记 ---
  const DebugSchemaItem(
    jsonPath: 'sensors.motor.state',
    label: '电机运行状态',
    enumMap: {0: '空闲', 1: '复位中', 2: '运行中', 3: '异常故障'},
    alertValue: 3,
  ),
  const DebugSchemaItem(jsonPath: 'sensors.motor.encoder_cnt', label: '编码器脉冲计数'),
  const DebugSchemaItem(jsonPath: 'sensors.motor.overload_flt', label: '电机过载/防夹故障', alertValue: true),
  const DebugSchemaItem(jsonPath: 'sensors.motor.reset_flt', label: '电机寻零复位故障', alertValue: true),

  // --- 系统与拓展硬件 ---
  const DebugSchemaItem(jsonPath: 'sensors.plasma.power_en', label: '等离子除臭状态'),
  const DebugSchemaItem(jsonPath: 'sys.sys_lock', label: '系统锁状态', alertValue: true),
  const DebugSchemaItem(jsonPath: 'sys.child_lock', label: '童锁状态'),
];
