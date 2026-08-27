import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fullxpet/common/config/app_constants.dart';
import 'package:fullxpet/common/theme/app_theme.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 5 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 5 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = AppTheme.primaryPurple;
    const Color titleBgColor = Color(0xFFE8E2F0);
    const Color pageBgColor = Color(0xFFFEF7FF);

    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: _isScrolled ? titleBgColor : pageBgColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: const Text(
          '关于我们',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParagraph(
              "我们是一家专注于智能宠物产品设计与创新的公司，致力于通过前沿科技提升宠物及其主人的生活质量。"
              "我们的产品线涵盖宠物健康监测设备、智能喂食器、自动猫砂盆、宠物可穿戴设备等，旨在为全球宠物家庭提供便捷、舒适与安心的体验。",
            ),
            _buildSectionTitle("我们的使命"),
            _buildParagraph(
              "我们相信，利用先进的 AI 技术可以为宠物和主人创造更加和谐的共居环境。"
              "我们的产品能够实时分析宠物的行为和健康状况，帮助主人尽早发现异常并及时采取措施。"
              "从根据区域气候定制的空调宠舍，到个性化的宠物护理方案，我们努力让科技成为连接宠物与家庭的桥梁。",
            ),
            _buildSectionTitle("为什么选择我们？"),
            _buildBulletPoint(
              "全品类产品线",
              "我们的产品覆盖宠物生活的方方面面，包括饮食、健康、清洁与娱乐。"
                  "例如，我们的智能喂食器可以在定时定量喂食的同时监测饮食习惯；自动猫砂盆可分析排泄数据并提供早期健康预警。",
            ),
            _buildBulletPoint(
              "立足全球，贴近本地",
              "服务超过 40 个国家和地区，我们根据不同市场的需求定制产品。"
                  "无论是针对泰国的极高美学设计，还是全球首款宠物智能手机（PetPhone）等创新功能，我们都确保方案能引起全球用户的共鸣。",
            ),
            _buildBulletPoint("持续创新", "我们融合人工智能、机器学习和云技术，重新定义宠物护理标准。我们的目标是让养宠变得更智能、更轻松、更有趣。"),
            _buildSectionTitle("与我们携手共创未来"),
            _buildParagraph(
              "随着对智能宠物产品需求的不断增长，预计到 2028 年全球市场规模将达到 107.3 亿美元，我们已准备好引领这一变革性行业。"
              "让我们携手共进，为宠物和它们的家庭创造更美好的未来！",
            ),
            const SizedBox(height: 10),
            _buildParagraph("如果您对我们的产品或服务有任何疑问，请随时与我们联系。期待与您的合作！"),
            _buildParagraph("如果您有任何问题或建议，欢迎随时联系我们："),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.email_outlined, size: 18, color: primaryPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            children: const [
                              TextSpan(
                                text: "电子邮箱: ",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: AppConstants.officialEmail),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.language_outlined, size: 18, color: primaryPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            children: const [
                              TextSpan(
                                text: "官方网站: ",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: AppConstants.officialWebsite),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        "\u3000\u3000$text",
        softWrap: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title,
        softWrap: true,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
      ),
    );
  }

  Widget _buildBulletPoint(String boldTitle, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        softWrap: true,
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6),
          children: [
            const TextSpan(text: "• "),
            TextSpan(
              text: "$boldTitle：",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
