import 'package:flutter/material.dart';
import 'package:fullxpet/common/theme/app_theme.dart';
import 'package:fullxpet/core/network/api_exception.dart';
import 'package:fullxpet/locator.dart';
import '../models/pet_dto.dart';
import '../repositories/pet_repository.dart';

class BreedPickerSheet extends StatefulWidget {
  final String petType;
  final String selectedBreedCode;

  const BreedPickerSheet({super.key, required this.petType, required this.selectedBreedCode});

  static Future<PetBreedDto?> show(BuildContext context, {required String petType, required String selectedBreedCode}) {
    return showModalBottomSheet<PetBreedDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BreedPickerSheet(petType: petType, selectedBreedCode: selectedBreedCode),
    );
  }

  @override
  State<BreedPickerSheet> createState() => _BreedPickerSheetState();
}

class _BreedPickerSheetState extends State<BreedPickerSheet> {
  final PetRepository _petRepo = locator<PetRepository>();
  final TextEditingController _searchCtrl = TextEditingController();

  List<PetBreedDto> _allBreeds = const [];
  String _keyword = '';
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final list = await _petRepo.getBreeds(petType: widget.petType, forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _allBreeds = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = ApiException.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kw = _keyword.trim().toLowerCase();
    final filtered = kw.isEmpty
        ? _allBreeds
        : _allBreeds
              .where(
                (b) =>
                    b.breedName.toLowerCase().contains(kw) ||
                    b.breedCode.toLowerCase().contains(kw) ||
                    b.letterIndex.toLowerCase() == kw,
              )
              .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                widget.petType == 'dog' ? '选择狗狗品种' : '选择猫咪品种',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _keyword = v),
                decoration: InputDecoration(
                  hintText: '搜索品种名称或首字母',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  suffixIcon: _keyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _keyword = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
                  : _errorMsg.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMsg, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => _loadBreeds(forceRefresh: true),
                            child: const Text('重试', style: TextStyle(color: AppTheme.primaryPurple)),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                  ? const Center(
                      child: Text('未找到匹配品种', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    )
                  : ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final selected = item.breedCode == widget.selectedBreedCode;
                        return ListTile(
                          title: Text(
                            item.breedName.isNotEmpty ? item.breedName : item.breedCode,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? AppTheme.primaryPurple : const Color(0xFF333333),
                            ),
                          ),
                          trailing: selected ? const Icon(Icons.check, color: AppTheme.primaryPurple, size: 18) : null,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
