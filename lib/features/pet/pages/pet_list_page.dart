import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/common/widgets/app_avatar.dart';
import 'package:fullxpet/common/widgets/responsive_layout.dart';
import 'package:fullxpet/routes/app_router.dart';
import '../models/pet_dto.dart';
import '../pet_provider.dart';
import 'package:fullxpet/common/widgets/app_dialogs.dart';

class PetListPage extends StatefulWidget {
  const PetListPage({super.key});

  @override
  State<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  static const Color _primaryPurple = AppTheme.primaryPurple;
  static const Color _bgLight = Color(0xFFF9F9FC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().fetchPets();
    });
  }

  void _showDeleteDialog(BuildContext context, PetDto pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除宠物', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('确定要删除“${pet.name}”的资料吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF37474),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<PetProvider>();
              final success = await provider.deletePet(pet.id);
              if (mounted) {
                context.showAppToast(
                  message: success ? '已删除宠物' : (provider.errorMsg.isNotEmpty ? provider.errorMsg : '删除失败'),
                  type: success ? AppToastType.success : AppToastType.error,
                );
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text(
          '爱宠档案',
          style: TextStyle(color: Color(0xFF222222), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: _primaryPurple, size: 24),
            onPressed: () => context.push(AppRoutes.petEdit),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFormContainer(
          maxWidth: 600,
          child: RefreshIndicator(
            color: _primaryPurple,
            onRefresh: () => provider.fetchPets(),
            child: provider.isLoading && provider.pets.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
                : provider.pets.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: provider.pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final pet = provider.pets[index];
                      return _buildPetCard(pet);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: 120),
        Icon(Icons.pets_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Center(
          child: Text('暂无宠物资料，点击右上角添加', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        const SizedBox(height: 30),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              '添加宠物',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () => context.push(AppRoutes.petEdit),
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(PetDto pet) {
    return Slidable(
      key: ValueKey(pet.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _showDeleteDialog(context, pet),
            backgroundColor: const Color(0xFFF37474),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.petEdit, extra: pet),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              AppAvatar(avatarUrl: pet.avatarDisplay, radius: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pet.petSex.label,
                            style: const TextStyle(fontSize: 10, color: _primaryPurple, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '品种: ${pet.breedName.isNotEmpty ? pet.breedName : "未知"} · 体重: ${pet.weightKgStr}kg',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '年龄: ${pet.ageStr} · 活跃度: ${pet.petActiveness.label}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
