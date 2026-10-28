import 'package:flutter/material.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/locator.dart';

class CountryPickerSheet {
  static Future<CountryDto?> show(BuildContext context) async {
    final s = S.of(context)!;
    final regionService = locator<RegionService>();

    // 核心保护：若内存中为空，立即异步加载（本地缓存 0ms 读取）
    List<CountryDto> countries = regionService.countries;
    if (countries.isEmpty) {
      countries = await regionService.loadCountryList();
    }
    final selectedCountry = regionService.currentCountry;

    const Color primaryPurple = Color(0xFF917CEE);
    const Color textColor = Color(0xFF333333);
    const Color hintColor = Color(0xFF9E9E9E);
    const Color lineColor = Color(0xFFE5E5E5);

    return showModalBottomSheet<CountryDto>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  s.selectCountry,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              const Divider(height: 1, color: lineColor),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final isSelected = selectedCountry?.countryCode == country.countryCode;
                    return ListTile(
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: isSelected ? primaryPurple : textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(country.phoneCountryCode, style: const TextStyle(color: hintColor)),
                      onTap: () => Navigator.pop(ctx, country),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
