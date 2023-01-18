import 'package:eshop/Helper/HamburgerItems.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eshop/Helper/Color.dart';

import '../../Provider/UserProvider.dart';

class HamburgerMenu extends StatefulWidget {
  const HamburgerMenu({Key? key}) : super(key: key);

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  Color iconActiveColor = colors.primary;
  Color iconInactiveColor = Colors.black;
  Color textColor = Color(0xFF000000);

  // set_opt(int i) {
  //   for (int k = 0; k < selected_opt.length; k++) {
  //     if (k == i)
  //       selected_opt[k] = true;
  //     else
  //       selected_opt[k] = false;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: DrawerHeader(
              decoration: BoxDecoration(color: colors.lightWhite2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    "assets/images/logo1.png",
                    height: 75,
                    width: 75,
                  ),
                  CircleAvatar(
                    child: ClipOval(
                      child: Image.network(
                        userProvider.profilePic,
                        height: 175,
                        width: 175,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...hamburgerList
                    .map(
                      (e) => ListTile(
                        leading: e.icon,
                        focusColor: colors.primary,
                        // enabled: isEnabled,
                        title: Text(
                          e.title,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        horizontalTitleGap: 5,
                        onTap: () {
                          // isEnabled = !isEnabled;
                          // print("HELLO");
                          Navigator.pushNamed(context, e.route);
                        },
                      ),
                    )
                    .toList(),
                SizedBox(
                  height: 5,
                ),
                Container(
                  child: Text(
                    "Version - 4.0.0",
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.end,
                  ),
                  padding: EdgeInsets.only(
                    top: 0,
                    bottom: 8,
                    right: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
