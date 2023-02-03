import 'package:csc_picker/csc_picker.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Screen/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';

class MemberRegistration extends StatefulWidget {
  const MemberRegistration({super.key});

  @override
  State<MemberRegistration> createState() => _SignupState();
}

class _SignupState extends State<MemberRegistration> {
  String countryValue = "";
  String? stateValue = "";
  String? cityValue = "";
  String? address = "";
  DateTime _selectedDate = DateTime(2002);
  TextEditingController _dateCont = TextEditingController();
  var formatter = DateFormat('dd-MM-yyyy');
  late SingleValueDropDownController _cnt;
  late SingleValueDropDownController _cntGender;
  void showDateSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: ScrollDatePicker(
            selectedDate: _selectedDate,
            locale: Locale('en'),
            onDateTimeChanged: (DateTime value) {
              setState(() {
                _selectedDate = value;
                _dateCont.text = formatter.format(_selectedDate);
              });
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    _cnt = SingleValueDropDownController();
    _cntGender = SingleValueDropDownController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          'Sign Up',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, size: 30,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
          child: Form(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            //margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child: Column(children: [
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Referal Code",
                  prefixIcon: Icon(Icons.local_activity_outlined),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text('OR'),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Upline ID",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ]),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Contact Details as per Kyc Documents*'),
              SizedBox(
                height: 10,
              ),
              CSCPicker(
                defaultCountry: CscCountry.India,
                onCountryChanged: (value) {
                  setState(() {
                    countryValue = value;
                  });
                },
                onStateChanged: (value) {
                  setState(() {
                    stateValue = value;
                  });
                },
                onCityChanged: (value) {
                  setState(() {
                    cityValue = value;
                  });
                },
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Mobile",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Email ID",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Address (House No, Street Name, Locality)",
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ]),
          ),
          Container(
            //  margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personal Details as per Kyc Documents*'),
              SizedBox(
                height: 20,
              ),
              DropDownTextField(
                textFieldDecoration: InputDecoration(
                  hintText: 'Title',
                  contentPadding: EdgeInsets.only(top: 15),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                controller: _cnt,
                clearOption: false,
                clearIconProperty: IconProperty(color: Colors.green),
                validator: (value) {
                  if (value == null) {
                    return "Required field";
                  } else {
                    return null;
                  }
                },
                dropDownItemCount: 6,
                dropDownList: const [
                  DropDownValueModel(name: 'Mr.', value: "Mr."),
                  DropDownValueModel(name: 'Mrs.', value: "Mrs."),
                  DropDownValueModel(name: 'Dr.', value: "Dr."),
                  DropDownValueModel(name: 'Ms.', value: "Ms."),
                ],
                onChanged: (val) {
                  _cnt.dropDownValue = val;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "First Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              // SizedBox(
              //   height: 10,
              // ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Last Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              TextFormField(
                readOnly: true,
                onTap: () {
                  showDateSheet();
                  print(_selectedDate);
                },
                controller: _dateCont,
                decoration: InputDecoration(
                  // labelText: formatter.format(_selectedDate),
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Enter Date of Birth",
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              // SizedBox(
              //   height: 10,
              // ),
              DropDownTextField(
                textFieldDecoration: InputDecoration(
                  hintText: 'Gender',
                  contentPadding: EdgeInsets.only(top: 15),
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                controller: _cntGender,
                clearOption: false,
                clearIconProperty: IconProperty(color: Colors.green),
                validator: (value) {
                  if (value == null) {
                    return "Required field";
                  } else {
                    return null;
                  }
                },
                dropDownItemCount: 2,
                dropDownList: const [
                  DropDownValueModel(name: 'Male', value: "Male"),
                  DropDownValueModel(name: 'Female', value: "Female"),
                ],
                onChanged: (val) {
                  _cntGender.dropDownValue = val;
                },
              ),
              SizedBox(
                height: 10,
              ),
            ]),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nominee Details'),
              SizedBox(
                height: 20,
              ),
              DropDownTextField(
                textFieldDecoration: InputDecoration(
                  hintText: 'Title',
                  contentPadding: EdgeInsets.only(top: 15),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                controller: _cnt,
                clearOption: false,
                clearIconProperty: IconProperty(color: Colors.green),
                validator: (value) {
                  if (value == null) {
                    return "Required field";
                  } else {
                    return null;
                  }
                },
                dropDownItemCount: 4,
                dropDownList: const [
                  DropDownValueModel(name: 'Mr.', value: "Mr."),
                  DropDownValueModel(name: 'Mrs.', value: "Mrs."),
                  DropDownValueModel(name: 'Dr.', value: "Dr."),
                  DropDownValueModel(name: 'Ms.', value: "Ms."),
                ],
                onChanged: (val) {
                  _cnt.dropDownValue = val;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "First Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              // SizedBox(
              //   height: 10,
              // ),
              TextFormField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Last Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              TextFormField(
                readOnly: true,
                onTap: () {
                  showDateSheet();
                },
                controller: _dateCont,
                decoration: InputDecoration(
                  // labelText: formatter.format(_selectedDate),
                  contentPadding: EdgeInsets.only(top: 15),
                  hintText: "Enter Date of Birth",
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              SizedBox(
                height: 10,
              ),
            ]),
          ),
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child: DropDownTextField(
              textFieldDecoration: InputDecoration(
                hintText: 'Distributor ID',
                contentPadding: EdgeInsets.only(top: 15),
                prefixIcon: Icon(Icons.person_outline),
              ),
              controller: _cntGender,
              clearOption: false,
              clearIconProperty: IconProperty(color: Colors.green),
              validator: (value) {
                if (value == null) {
                  return "Required field";
                } else {
                  return null;
                }
              },
              dropDownItemCount: 2,
              dropDownList: const [
                DropDownValueModel(name: '10002', value: "10002"),
                DropDownValueModel(name: '223344', value: "223344"),
              ],
              onChanged: (val) {
                _cntGender.dropDownValue = val;
              },
            ),
          ),
          SizedBox(
            height: 35,
          ),
          SizedBox(
              height: 37,
              width: 320,
              child: ElevatedButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      //  side: BorderSide(color: Colors.red)
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Dashboard()),
                  );
                },
                child: Text('Sign Up'),
              )),
          SizedBox(
            height: 50,
          ),
        ],
      ))),
    );
  }
}
