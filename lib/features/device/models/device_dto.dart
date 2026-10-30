import 'package:fullxpet/core/utils/device_batch_helper.dart';
import 'device_hardware_info.dart';
import 'product_dto.dart';

class DeviceDto {
  final String deviceId;
  String pgDeviceId; //虚拟id
  String productId;
  String hardwareId; //imei
  String deviceName;
  String? iconCode;
  bool isOnline;
  String connectionStatus;

  // 家庭与房间信息
  String accessSource;
  String homeId;
  String homeName;
  String roomId;
  String roomName;
  int sortOrder;

  // 共享与权限控制
  String? shareId;
  String? sharerUserId;
  String? shareStatus;
  bool canView;
  bool canControl;
  bool canManage;
  bool canShare;

  // 关联的产品信息 与硬件底层信息
  ProductDto? product;
  DeviceHardwareInfo? hardwareInfo;

  // 原始 DP 属性字典
  final Map<String, dynamic> _attributes = {};
  Map<String, dynamic> get attributes => _attributes;

  // 通用固件升级运行态
  bool hasNewFirmware = false;
  String newFirmwareVersion = '';
  String pendingOtaRecordId = '';
  bool isOtaUpdating = false;

  DeviceDto({
    required this.deviceId,
    this.pgDeviceId = '',
    this.productId = '',
    this.hardwareId = '',
    this.deviceName = '',
    this.iconCode,
    this.isOnline = false,
    this.connectionStatus = 'OFFLINE',
    this.accessSource = 'HOME_MEMBER',
    this.homeId = '',
    this.homeName = '',
    this.roomId = '',
    this.roomName = '',
    this.sortOrder = 0,
    this.shareId,
    this.sharerUserId,
    this.shareStatus,
    this.canView = true,
    this.canControl = true,
    this.canManage = true,
    this.canShare = true,
    this.product,
    this.hardwareInfo,
    Map<String, dynamic>? attributes,
  }) {
    if (attributes != null) {
      _attributes.addAll(attributes);
    }
  }

  // 设备映射批次号
  String get displayId => DeviceBatchHelper().getDisplayBatchNo(deviceId);

  // 产品缩略图 URL
  String get thumbnailUrl => product?.thumbnailUrl ?? '';

  // 产品分类编码
  String get categoryCode => product?.categoryCode ?? '';

  // 产品标准名称
  String get productName => product?.name ?? '';

  // 从 GET /api/v1/devices 的单条 JSON 更新数据
  void updateFromListJson(Map<String, dynamic> json, {ProductDto? matchedProduct}) {
    pgDeviceId = json['pgDeviceId']?.toString() ?? pgDeviceId;
    final parsedPid = json['productId']?.toString() ?? '';
    if (parsedPid.isNotEmpty) productId = parsedPid;

    hardwareId = json['hardwareId']?.toString() ?? hardwareId;
    final parsedName = json['nickname']?.toString() ?? '';
    if (parsedName.isNotEmpty) deviceName = parsedName;

    iconCode = json['iconCode']?.toString();
    if (json['online'] is bool) isOnline = json['online'] as bool;
    accessSource = json['accessSource']?.toString() ?? accessSource;
    homeId = json['homeId']?.toString() ?? homeId;
    homeName = json['homeName']?.toString() ?? homeName;
    roomId = json['roomId']?.toString() ?? roomId;
    roomName = json['roomName']?.toString() ?? roomName;
    if (json['sortOrder'] is num) sortOrder = (json['sortOrder'] as num).toInt();

    shareId = json['shareId']?.toString();
    sharerUserId = json['sharerUserId']?.toString();
    shareStatus = json['shareStatus']?.toString();
    if (json['canView'] is bool) canView = json['canView'] as bool;
    if (json['canControl'] is bool) canControl = json['canControl'] as bool;
    if (json['canManage'] is bool) canManage = json['canManage'] as bool;
    if (json['canShare'] is bool) canShare = json['canShare'] as bool;

    if (matchedProduct != null) {
      product = matchedProduct;
    }
  }

  // 批量更新属性列表
  void updateAttributesFromList(List<dynamic> attrList) {
    for (final item in attrList) {
      if (item is Map<String, dynamic>) {
        final dpid = item['dpid']?.toString();
        final value = item['value'];
        if (dpid != null && value != null) {
          _attributes[dpid] = value;
        }
      }
    }
  }

  // 增量更新属性字典（来自 MQTT 上报或乐观更新）
  void updateAttributesFromMap(Map<String, dynamic> changedAttributes) {
    changedAttributes.forEach((dpid, value) {
      _attributes[dpid.toString()] = value;
    });
  }
}
// class DeviceDto {
//   final String deviceId;
//   String deviceName;
//   bool isOnline;
//   String productId;
//   String get displayId => DeviceBatchHelper().getDisplayBatchNo(deviceId);
//   final Map<String, dynamic> _attributes = {};
//   final List<DeviceLog> logs = [];

//   String? logNextPageToken;
//   bool hasMoreLogs = true;
//   Map<String, dynamic> get attributes => _attributes;
//   int savedCalibrationWeight = 5000;
//   String timeZoneId = 'Asia/Shanghai';
//   String timeZoneOffset = 'UTC+08:00';
//   bool hasNewFirmware = false;
//   String newFirmwareVersion = '';
//   String pendingOtaRecordId = '';
//   bool isOtaUpdating = false;
//   static const String pidV4 = '1a731d3e68cca08b';
//   static const String pidFeeder = '9c2608de680bf9b6';
//   bool get isV4 => productId == pidV4;
//   bool get isFeeder => productId == pidFeeder;
//   bool get isLitterBox => !isFeeder;
//   bool get hasPlasma => !isV4 && !isFeeder;
//   String get displayImage {
//     if (isFeeder) {
//       return 'assets/images/product-feeder.png';
//     }
//     return isV4 ? 'assets/images/product-v4.png' : 'assets/images/product-pic.png';
//   }

//   DeviceDto({
//     required this.deviceId,
//     this.deviceName = 'FULLXPET',
//     this.productId = '',
//     this.isOnline = false,
//     Map<String, dynamic>? attributes,
//   }) {
//     if (attributes != null) {
//       _attributes.addAll(attributes);
//     }
//   }

//   // 物模型属性与计算属性
//   ExecuteAction get executeAction {
//     if (!isOnline) return ExecuteAction.idle;
//     final val = _attributes[DeviceThingModel.deviceExecute.dpid];
//     if (val?.toString() == '5') {
//       return ExecuteAction.idle;
//     }
//     return ExecuteAction.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
//   }

//   bool get isDeviceIdle => executeAction == ExecuteAction.idle;

//   WorkMode get workMode {
//     final val = _attributes[DeviceThingModel.deviceMode.dpid];
//     return WorkMode.fromValue(int.tryParse(val?.toString() ?? '') ?? 0);
//   }

//   bool get isChildLockEnabled {
//     final val = _attributes[DeviceThingModel.childLockSwitch.dpid];
//     return val == true || val?.toString() == 'true';
//   }

//   bool get isPlasmaEnabled {
//     final val = _attributes[DeviceThingModel.palsmaState.dpid];
//     return val == true || val?.toString() == 'true';
//   }

//   bool get isDndEnabled {
//     final val = _attributes[DeviceThingModel.notdisturbModeStatus.dpid];
//     return val == true || val?.toString() == 'true';
//   }

//   String get wifiSsid => _attributes[DeviceThingModel.deviceSsid.dpid]?.toString() ?? '';
//   String get wifiRssi => "${_attributes[DeviceThingModel.deviceRssi.dpid] ?? 0}dBm";
//   String get wifiIp => _attributes[DeviceThingModel.deviceIp.dpid]?.toString() ?? '0.0.0.0';
//   String get wifiMac => _attributes[DeviceThingModel.deviceMac.dpid]?.toString() ?? '00:00:00:00:00:00';
//   String get firmwareVersion => _attributes[DeviceThingModel.deviceVersion.dpid]?.toString() ?? '';

//   String get todayTimes => _attributes[DeviceThingModel.excretionTimesDay.dpid]?.toString() ?? '0';
//   String get averageSeconds => _attributes[DeviceThingModel.excretionTimeDay.dpid]?.toString() ?? '0';

//   int get autoModeDelaySeconds {
//     final val = _attributes[DeviceThingModel.autoModeDelay.dpid];
//     return int.tryParse(val?.toString() ?? '') ?? 60;
//   }

//   int get autoModeIndex {
//     int mins = autoModeDelaySeconds ~/ 60;
//     int idx = mins - 1;
//     return (idx >= 0 && idx <= 4) ? idx : 0;
//   }

//   List<String> get timerList {
//     final val = _attributes[DeviceThingModel.timerModeSchedule.dpid];
//     if (val == null) return [];
//     try {
//       final List<dynamic> tList = jsonDecode(val.toString());
//       List<String> result = [];
//       for (var t in tList) {
//         int seconds = int.parse(t.toString());
//         result.add(TimeUtils.secondsToTime(seconds));
//       }
//       result.sort();
//       return result;
//     } catch (_) {
//       return [];
//     }
//   }

//   Map<String, String> get dndTimeRange {
//     final val = _attributes[DeviceThingModel.notdisturbModeSchedule.dpid];
//     String start = '22:00';
//     String end = '06:00';
//     if (val != null) {
//       try {
//         final Map<String, dynamic> dndMap = jsonDecode(val.toString());
//         if (dndMap.containsKey('TimerStart')) {
//           start = TimeUtils.secondsToTime(int.parse(dndMap['TimerStart'].toString()));
//         }
//         if (dndMap.containsKey('TimerEnd')) {
//           end = TimeUtils.secondsToTime(int.parse(dndMap['TimerEnd'].toString()));
//         }
//       } catch (_) {}
//     }
//     return {'start': start, 'end': end};
//   }

//   String get categoryName {
//     if (isFeeder) return '猫脸喂食器';
//     if (isV4) return 'PETLUX V4';
//     return 'PETLUX V3';
//   }

//   bool get isOperating {
//     if (!isOnline) return false;
//     final dpid8 = _attributes[DeviceThingModel.deviceStatus.dpid]?.toString();
//     final dpid9 = _attributes[DeviceThingModel.deviceExecute.dpid]?.toString();
//     if (dpid9 == '5') return false;
//     if (dpid8 != '0' || dpid9 != '0') return true;
//     return false;
//   }

//   void updateAttributes(List<dynamic> newAttributes) {
//     for (var attr in newAttributes) {
//       if (attr is Map<String, dynamic>) {
//         final dpid = attr['dpid']?.toString();
//         final value = attr['value'];
//         if (dpid != null && value != null) {
//           _attributes[dpid] = value;
//         }
//       }
//     }
//   }

//   void updateAttributesFromMap(Map<String, dynamic> changedAttributes) {
//     changedAttributes.forEach((dpid, value) {
//       _attributes[dpid.toString()] = value;
//     });
//   }

//   // 等离子工作时间排期 (DP 32: {"runTime":"3600","outTime":"1800"})
//   Map<String, int> get plasmaSchedule {
//     final val = _attributes[DeviceThingModel.plasmaSchedule.dpid];
//     if (val == null || val.toString().isEmpty) {
//       return {'runTime': 3600, 'outTime': 1800}; // 默认配置
//     }
//     try {
//       final decoded = jsonDecode(val.toString());
//       if (decoded is Map) {
//         return {
//           'runTime': int.tryParse(decoded['runTime']?.toString() ?? '0') ?? 0,
//           'outTime': int.tryParse(decoded['outTime']?.toString() ?? '0') ?? 0,
//         };
//       }
//     } catch (_) {}
//     return {'runTime': 3600, 'outTime': 1800};
//   }

//   // 是否为常开模式 (runTime == 0 && outTime == 0)
//   bool get isPlasmaAlwaysOn {
//     final sched = plasmaSchedule;
//     return sched['runTime'] == 0 && sched['outTime'] == 0;
//   }
// }
