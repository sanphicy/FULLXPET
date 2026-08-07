import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF917CEE);
    const Color pageBgColor = Color(0xFFFEF7FF);

    return Scaffold(
      backgroundColor: pageBgColor,
      appBar: AppBar(
        backgroundColor: pageBgColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: const Text(
          '意见与反馈',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '意见与反馈',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
            const Text(
              '\u3000\u3000如果您有任何问题或建议，欢迎随时与我们联系：',
              softWrap: true, // 避免文本溢出
              style: TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.6),
            ),
            const SizedBox(height: 20),
            // 联系方式卡片（带防溢出换行）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.email_outlined, size: 20, color: primaryPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            children: const [
                              TextSpan(
                                text: '电子邮箱: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: 'thinoqie@163.com'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.language_outlined, size: 20, color: primaryPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            children: const [
                              TextSpan(
                                text: '官方网站: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: 'http://www.hoget.com'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
