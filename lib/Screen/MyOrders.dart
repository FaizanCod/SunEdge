import 'package:eshop/Helper/Color.dart';
import 'package:flutter/material.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({Key? key}) : super(key: key);

  @override
  _MyOrdersState createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          'My Orders',
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.primary,
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    child: Text(
                      'Cancelled',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    child: Text(
                      'Invoiced',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    child: Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.5),
                          child: VerticalDivider(
                            color: Colors.grey[250],
                            thickness: 1,
                            width: 2,
                            indent: 2,
                            endIndent: 2,
                          ),
                        ),
                        Text(
                          '2023-01-08',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.5),
                          child: VerticalDivider(
                            color: Colors.grey[250],
                            thickness: 1,
                            width: 2,
                            indent: 2,
                            endIndent: 2,
                          ),
                        ),
                        Text(
                          '2023-01-08',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  child: Text('Clear'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    primary: colors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
