class AppConfig {
  final String baseUrl; //服务器地址
  final String accessTokenKey; //访问令牌

  AppConfig({required this.baseUrl, required this.accessTokenKey});

  // 开发环境配置
  factory AppConfig.dev() {
    return AppConfig(baseUrl: 'http://192.168.100.71:8080', accessTokenKey: 'v3_dev_access_token');
  }

  // 生产环境配置
  factory AppConfig.prod() {
    return AppConfig(baseUrl: 'https://web.api.stellapets.com', accessTokenKey: 'v3_prod_access_token');
  }
}
