class ApiEndpoints {
  // 定义 API 版本和全局基础前缀
  static const String _apiV1 = '/app/api/v1';
  static const String _apiV1Byplatform = '/platform/api/v1';

  // --- 认证相关 ---
  static const String loginByPhone = '$_apiV1/auth/login';
  static const String loginByEmail = '$_apiV1/auth/login/email';
  static const String register = "$_apiV1/auth/register/email";
  static const String resetPassword = "$_apiV1/auth/password/reset/email";
  static const String logout = "$_apiV1/auth/logout";

  // --- 用户相关 ---
  static const String homeList = "$_apiV1/me/homes";
  static String homeInfo(String homeId) => "$_apiV1/homes/$homeId";
  static const String userInfo = "$_apiV1/auth/me";
  static const String uploadAvatar = "$_apiV1/auth/me/avatar";
  static const String countries = "$_apiV1Byplatform/countries";

  // --- 设备相关 ---
  static const String devices = '$_apiV1/me/devices';
  static String deviceProperties(String deviceId) => "$_apiV1/devices/$deviceId/properties";
  static String deviceInvoke(String deviceId) => "$_apiV1/devices/$deviceId/properties/set";
  static String checkFirmware(String deviceId) => "$_apiV1/devices/$deviceId/ota/pending";
  static String upgradeFirmware(String deviceId, String recordId) => "$_apiV1/devices/$deviceId/ota/$recordId/dispatch";
  static String deviceName(String deviceId) => "$_apiV1/devices/$deviceId";
  static String deviceBind(String homeId) => "$_apiV1/homes/$homeId/devices";
  static String deviceUnBind(String homeId, String deviceId) => "$_apiV1/homes/$homeId/devices/$deviceId";
  static String deviceLogs(String deviceId) => "$_apiV1/devices/$deviceId/attr-logs";

  // --- MQTT相关 ---
  static String mqttUri = "$_apiV1Byplatform/bootstrap";
  static const String mqttCredentials = '$_apiV1/me/mqtt/credentials/refresh';
  static String mqttSubscribe(String deviceId) => '$_apiV1/me/mqtt/subscriptions/$deviceId';
  static const String mqttSubscribeSync = '$_apiV1/me/mqtt/subscriptions/sync';
}
