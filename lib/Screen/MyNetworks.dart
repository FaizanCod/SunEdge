import 'package:eshop/Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyNetworks extends StatefulWidget {
  const MyNetworks({Key? key}) : super(key: key);

  @override
  _MyNetworksState createState() => _MyNetworksState();
}

class _MyNetworksState extends State<MyNetworks> {
  bool _isExpanded = false;
  int tabSelected = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          'My Networks',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        onPressed: () {},
        child: Icon(
          Icons.refresh_rounded,
          size: 30,
        ),
      ),
      body: Container(
        color: Colors.blueGrey[100],
        padding: EdgeInsets.only(bottom: 5),
        child: Column(
          children: [
            Container(
              height: 52,
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        tabSelected = 0;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: tabSelected == 0
                                ? colors.primary
                                : Colors.grey[100]!,
                            width: tabSelected == 0 ? 2 : 0,
                          ),
                        ),
                      ),
                      child: Text(
                        'My Network',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: tabSelected == 0
                              ? colors.primary
                              : Colors.grey[500]!,
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    color: Colors.grey[500],
                    thickness: 1,
                    width: 2,
                    indent: 15,
                    endIndent: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        tabSelected = 1;
                      });
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: tabSelected == 1
                                ? colors.primary
                                : Colors.grey[100]!,
                            width: tabSelected == 1 ? 2 : 0,
                          ),
                        ),
                      ),
                      child: Text(
                        'Starred (1)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: tabSelected == 1
                              ? colors.primary
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            tabSelected == 0
                ? Container(
                    color: Colors.grey[100],
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Distributor',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                        ),
                        suffix: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Search',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 60,
                    color: Colors.grey[100],
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[400]!, width: 1.5)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              VerticalDivider(
                                color: Colors.grey[500],
                                thickness: 1,
                                width: 2,
                                indent: 2,
                                endIndent: 2,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '2022-12-08',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey[400]!, width: 1.5)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              VerticalDivider(
                                color: Colors.grey[500],
                                thickness: 1,
                                width: 2,
                                indent: 2,
                                endIndent: 2,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '2023-01-08',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Color.fromARGB(24, 96, 125, 139),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AMOL PARAKH',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Distributor ID-50155353',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            tabSelected == 0
                ? Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top: 10,
                          bottom: 16,
                          left: 12,
                          right: 12,
                        ),
                        padding: EdgeInsets.only(
                            left: 12, right: 12, bottom: 20, top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ExpansionTile(
                          key: GlobalKey(),
                          onExpansionChanged: (value) {
                            setState(() {
                              _isExpanded = value;
                            });
                          },
                          initiallyExpanded: _isExpanded,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NIVRUTTI MEHTRE',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Point Value  ',
                                          style: TextStyle(
                                            color: Color(0xff1f1f1f),
                                          ),
                                        ),
                                        TextSpan(
                                          text: '0',
                                          style:
                                              TextStyle(color: colors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: 35017903',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '5%',
                                          style: TextStyle(
                                            color: Colors.amber[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Designation',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'DISTRIBUTOR',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Previous Cumulative PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Exclusive PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Self PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Short Point',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '600.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Next Level',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '8.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Group PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Cumulative PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Last Month Point Details',
                              style: TextStyle(
                                color: Color(0xff0f0f0f),
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Previous Exclusive PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Previous Total PV',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    '0.00',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Previous Level',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  Text(
                                    'DISTRIBUTOR',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Image.asset(
                                  'assets/images/edit-message.png',
                                  height: 30,
                                  width: 30,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              'DAF IS NOT SUBMITTED!',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Main Upline',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  Text(
                                    'Upline',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  Text(
                                    'Downline',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 25,
                            ),
                          ],
                          trailing: Icon(
                            Icons.star,
                            color: Colors.grey[700],
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: MediaQuery.of(context).size.width / 2 - 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            icon: _isExpanded
                                ? Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 25,
                                    color: Colors.grey[800],
                                  )
                                : Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 25,
                                    color: Colors.grey[800],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          top: 10,
                          bottom: 16,
                          left: 12,
                          right: 12,
                        ),
                        padding: EdgeInsets.only(
                            left: 12, right: 12, bottom: 20, top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ExpansionTile(
                          key: GlobalKey(),
                          onExpansionChanged: (value) {
                            setState(() {
                              _isExpanded = value;
                            });
                          },
                          initiallyExpanded: _isExpanded,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AMOL PARAKH',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Point Value  ',
                                          style: TextStyle(
                                            color: Color(0xff1f1f1f),
                                          ),
                                        ),
                                        TextSpan(
                                          text: '0',
                                          style:
                                              TextStyle(color: colors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: 50155353',
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '11%',
                                          style: TextStyle(
                                            color: Colors.amber[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Attribute',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'PV',
                                          style: TextStyle(
                                            color: Color(0xff1f1f1f),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          ' -100.00%',
                                          style: TextStyle(
                                            color: Colors.red[400],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: Colors.red[400],
                                          size: 30,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'From Date PV',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text('51.34'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'To Date PV',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text('0'),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 25,
                            ),
                          ],
                          trailing: Icon(
                            Icons.star,
                            color: Colors.amber[400],
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: MediaQuery.of(context).size.width / 2 - 20,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            icon: _isExpanded
                                ? Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 25,
                                    color: Colors.grey[800],
                                  )
                                : Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 25,
                                    color: Colors.grey[800],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
