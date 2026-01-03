import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netra/common/appconstants/app_colors.dart';
import 'package:netra/common/appconstants/text_constants.dart';
import 'package:netra/common/appconstants/common_style_constants.dart';
import 'package:netra/view/network_scanner_screen/network_scanner_screen.dart';

import 'widgets/network_info_widget/network_info_widget.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(
          AppTextConstants.appName,
          style: CommonStyleConstants.appbarTextStyle,
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(children: [NetworkInfoWidget(),


        ElevatedButton(onPressed: (){

          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return ScannerScreen();
          },));
        }, child: Text("Scan"))
      ]),
    );
  }
}
