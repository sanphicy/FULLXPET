class AppConfig {
  final String appName; //应用标题
  final String baseUrl; //服务器地址
  final String accessTokenKey; //访问令牌

  AppConfig({required this.appName, required this.baseUrl, required this.accessTokenKey});

  // 开发环境配置
  factory AppConfig.dev() {
    return AppConfig(
      appName: "FULLXPET",
      baseUrl: 'https://web.api.stellapets.com',
      accessTokenKey: 'v3_dev_access_token',
    );
  }

  // 生产环境配置
  factory AppConfig.prod() {
    return AppConfig(
      appName: "FULLXPET",
      baseUrl: 'https://us-web.iot.junvine.com.cn',
      accessTokenKey: 'v3_prod_access_token',
    );
  }
}
