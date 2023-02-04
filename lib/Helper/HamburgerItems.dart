import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HamburgerItems {
  final String title;
  final Widget icon;
  final String route;
  final bool requireLogin;

  HamburgerItems({
    required this.title,
    required this.icon,
    required this.route,
    required this.requireLogin,
  });
}

List<HamburgerItems> hamburgerList = [
  HamburgerItems(
    title: 'Categories',
    icon: Image.asset(
      'assets/images/category.png',
      height: 25,
      width: 25,
    ),
    route: '/categories',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Brands',
    icon: Image.asset('assets/images/price-tag.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'My Dashboard',
    icon: Image.asset('assets/images/dashboard.png', height: 25, width: 25),
    route: '/home',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'My Profile',
    icon: Icon(Icons.person_outline_rounded, size: 25, color: Colors.black),
    route: '/profile',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Birthday List',
    icon: Image.asset('assets/images/giftbox.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'WishList',
    icon: Image.asset('assets/images/wishlist.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Schemes',
    icon: Image.asset('assets/images/giftbox.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'My Group PV',
    icon: Image.asset('assets/images/chart.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My KYC',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'PAN Details',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'DAF Details',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Network',
    icon: Image.asset('assets/images/network.png', height: 25, width: 25),
    route: '/my-networks',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Consistency',
    icon: Image.asset('assets/images/consistency.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Funds',
    icon: Image.asset('assets/images/funds.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Voucher',
    icon: Image.asset('assets/images/voucher.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Bonus',
    icon: Image.asset('assets/images/bonus.png', height: 25, width: 25),
    route: '/my-bonus',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Orders',
    icon: Image.asset('assets/images/order.png', height: 25, width: 25),
    route: '/my-orders',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Make Payment',
    icon: Image.asset('assets/images/payment.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Training',
    icon: Image.asset('assets/images/training.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'SunEdge Branches',
    icon: Image.asset('assets/images/branches.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Recommendation',
    icon:
        Image.asset('assets/images/recommendation.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'New Member Registration',
    icon: Icon(Icons.person_outline_rounded, size: 25, color: Colors.black),
    route: '/new-member-registration',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Distributor Id Card',
    icon: Image.asset('assets/images/user-id.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Refer a Friend',
    icon: Image.asset('assets/images/share.png', height: 25, width: 25),
    route: '/refer',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'My Prospect',
    icon: Image.asset('assets/images/prospect.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Change Password',
    icon: Icon(Icons.lock_outline_rounded, size: 25, color: Colors.black),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Update Mobile Number',
    icon: Image.asset('assets/images/update-mobile.png', height: 25, width: 25),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'About Us',
    icon: Image.asset('assets/images/about-us.png', height: 25, width: 25),
    route: '/about',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Support',
    icon:
        Icon(Icons.chat_bubble_outline_rounded, size: 25, color: Colors.black),
    route: '/customer-support',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Share App With Network',
    icon: Image.asset('assets/images/share.png', height: 25, width: 25),
    route: '/share',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Logged-in Devices',
    icon: Icon(Icons.devices_rounded, size: 25, color: Colors.black),
    route: '/maintenance',
    requireLogin: true,
  ),
  HamburgerItems(
    title: 'Contact Us',
    icon: Image.asset('assets/images/contact.png', height: 25, width: 25),
    route: '/contact',
    requireLogin: false,
  ),
  HamburgerItems(
    title: 'Sign Out',
    icon: Image.asset('assets/images/sign-out.png', height: 25, width: 25),
    route: '/logout',
    requireLogin: true,
  ),
];
