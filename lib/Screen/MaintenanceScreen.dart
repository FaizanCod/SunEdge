import 'package:eshop/Helper/Color.dart';
import 'package:eshop/ui/widgets/SimpleAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getSimpleAppBar('Under maintenance', context),
      body: Container(
        color: colors.secondary,
        padding: EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 25,
        ),
        child: Center(
          child: Column(
            children: [
              ClipRRect(
                child: Image.asset('assets/images/maintenance.png'),
                borderRadius: BorderRadius.circular(100),
              ),
              SizedBox(height: 15),
              Text(
                'We are currently under maintenance!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                'Sorry for the inconvenience. Please check back later.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
                textAlign: TextAlign.center
              ),
            ],
          ),
        ),
      ),
    );
  }
}
