import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fullxpet/common/models/country_dto.dart';
import 'package:fullxpet/core/services/region_service.dart';
import 'package:fullxpet/locator.dart';

class CountryPickerSheet {
  static Future<CountryDto?> show(BuildContext context) async {
    final regionService = locator<RegionService>();
    final countries = regionService.countries;
    final selectedCountry = regionService.currentCountry;

    const Color primaryPurple = Color(0xFF917CEE);
    const Color textColor = Color(0xFF333333);
    const Color hintColor = Color(0xFF9E9E9E);
    const Color lineColor = Color(0xFFE5E5E5);

    return showModalBottomSheet<CountryDto>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  "选择国家/地区",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor),
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
                      onTap: () async {
                        await regionService.switchCountry(country);
                        if (ctx.mounted) Navigator.pop(ctx, country);
                      },
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
