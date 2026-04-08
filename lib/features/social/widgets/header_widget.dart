import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CirclesHeader extends StatelessWidget {
  const CirclesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Circle",
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              "Manage your team & rankings",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),

        /// Avatar
        CircleAvatar(
          radius: 22.r,
          backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
        ),
      ],
    );
  }
}
