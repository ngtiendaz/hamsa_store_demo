import 'package:flutter/material.dart';
import '../../../user/profile/view/profile_view.dart';

class CustomerProfileView extends StatelessWidget {
  const CustomerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileView(showLogout: true);
  }
}
