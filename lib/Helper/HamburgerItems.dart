import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HamburgerItems {
  final String title;
  final Widget icon;
  final String route;

  HamburgerItems({
    required this.title,
    required this.icon,
    required this.route,
  });
}

List<HamburgerItems> hamburgerList = [
  HamburgerItems(
    title: 'Categories',
    icon: Image.asset('assets/images/category.png', height: 25, width: 25,),
    route: '',
  ),
  HamburgerItems(
    title: 'Brands',
    icon: Image.asset('assets/images/price-tag.png', height: 25, width: 25),
    route: ''
  ),
  HamburgerItems(
    title: 'My Dashboard',
    icon: Image.asset('assets/images/dashboard.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Profile',
    icon: Icon(Icons.person_outline_rounded, size: 25, color: Colors.black),
    route: '',
  ),
  HamburgerItems(
    title: 'Birthday List',
    icon: Image.asset('assets/images/giftbox.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'WishList',
    icon: Image.asset('assets/images/wishlist.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Schemes',
    icon: Image.asset('assets/images/giftbox.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Group PV',
    icon: Image.asset('assets/images/chart.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My KYC',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'PAN Details',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'DAF Details',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Network',
    icon: Image.asset('assets/images/network.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Consistency',
    icon: Image.asset('assets/images/consistency.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Funds',
    icon: Image.asset('assets/images/funds.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Voucher',
    icon: Image.asset('assets/images/voucher.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Bonus',
    icon: Image.asset('assets/images/bonus.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Orders',
    icon: Image.asset('assets/images/order.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Make Payment',
    icon: Image.asset('assets/images/payment.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Training',
    icon: Image.asset('assets/images/training.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'SunEdge Branches',
    icon: Image.asset('assets/images/branches.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Recommendation',
    icon: Image.asset('assets/images/recommendation.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'New Member Registration',
    icon: Icon(Icons.person_outline_rounded, size: 25, color: Colors.black),
    route: '',
  ),
  HamburgerItems(
    title: 'Distributor Id Card',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Refer a Friend',
    icon: Image.asset('assets/images/share.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'My Prospect',
    icon: Image.asset('assets/images/prospect.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Change Password',
    icon: Icon(Icons.lock_outline_rounded, size: 25, color: Colors.black),
    route: '',
  ),
  HamburgerItems(
    title: 'Update Mobile Number',
    icon: Image.asset('assets/images/update-mobile.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'About Us',
    icon: Image.asset('assets/images/about-us.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Support',
    icon: Icon(Icons.chat_bubble_outline_rounded, size: 25, color: Colors.black),
    route: '',
  ),
  HamburgerItems(
    title: 'Share App With Network',
    icon: Image.asset('assets/images/share.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Logged-in Devices',
    icon: Icon(Icons.devices_rounded, size: 25, color: Colors.black),
    route: '',
  ),
  HamburgerItems(
    title: 'Contact Us',
    icon: Image.asset('assets/images/contact.png', height: 25, width: 25),
    route: '',
  ),
  HamburgerItems(
    title: 'Sign Out',
    icon: Image.asset('assets/images/sign-out.png', height: 25, width: 25),
    route: '',
  ),
];
