import 'package:flutter/material.dart';
import 'package:jaal/common/appconstants/app_colors.dart';
import 'package:jaal/common/appconstants/text_size_constants.dart';

class CommonStyleConstants {
  static const TextStyle appbarTextStyle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
    fontSize: TextSizeConstants.appBarTextSize,
  );

  static final BoxDecoration commonContainerDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: AppColors.commonContainerGradient,
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withOpacity(0.4),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
    border: Border.all(color: AppColors.divider, width: 2),
  );
}
