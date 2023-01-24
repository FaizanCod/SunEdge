// import 'package:eshop/Helper/Session.dart';
// import 'package:eshop/Model/Section_Model.dart';
// import 'package:eshop/ui/widgets/SimpleAppBar.dart';
// import 'package:flutter/material.dart';
// import 'package:eshop/Helper/Color.dart';


// class ProductListScreen extends StatefulWidget {
//   const ProductListScreen({Key? key}) : super(key: key);

//   @override
//   _ProductListScreenState createState() => _ProductListScreenState();
// }

// class _ProductListScreenState extends State<ProductListScreen> {
//   List<Product> productList = [];
//   List<Product> filterList = [];
//     bool listType = true;
//   final List<TextEditingController> _controller = [];
//   List<String>? tagList = [];
//   ChoiceChip? tagChip, choiceChip;
//   RangeValues? _currentRangeValues;
//   AnimationController? _animationController;
//   AnimationController? _animationController1;
// String sortBy = 'p.id', orderBy = "DESC";
//   bool _isLoading = true, _isProgress = false;
//   int total = 0, offset = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: getSimpleAppBar('Shop By PV', context),
//       body: Container(
//         child: Column(
//           children: [
//             filterOptions(),

//           ],
//         ),
//       ),
//     );
//   }

//   filterOptions() {
//     return Container(
//       height: 45.0,
//       width: MediaQuery.of(context).size.width,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.gray,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           TextButton.icon(
//               onPressed: () {
//                 filterDialog();
//               },
//               icon: const Icon(
//                 Icons.filter_list,
//                 color: colors.primary,
//               ),
//               label: Text(
//                 getTranslated(context, 'FILTER')!,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.fontColor,
//                 ),
//               )),
//           TextButton.icon(
//               onPressed: sortDialog,
//               icon: const Icon(
//                 Icons.swap_vert,
//                 color: colors.primary,
//               ),
//               label: Text(
//                 getTranslated(context, 'SORT_BY')!,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.fontColor,
//                 ),
//               )),
//           InkWell(
//             child: Icon(
//               listType ? Icons.grid_view : Icons.list,
//               color: colors.primary,
//             ),
//             onTap: () {
//               productList.isNotEmpty
//                   ? setState(() {
//                       _animationController!.reverse();
//                       _animationController1!.reverse();
//                       listType = !listType;
//                     })
//                   : null;
//             },
//           ),
//         ],
//       ),
//     );
//   }

//     void sortDialog() {
//     showModalBottomSheet(
//       backgroundColor: Theme.of(context).colorScheme.white,
//       context: context,
//       enableDrag: false,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25.0),
//           topRight: Radius.circular(25.0),
//         ),
//       ),
//       builder: (builder) {
//         return StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//           return SingleChildScrollView(
//             child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Padding(
//                         padding: const EdgeInsetsDirectional.only(
//                             top: 19.0, bottom: 16.0),
//                         child: Text(
//                           getTranslated(context, 'SORT_BY')!,
//                           style: Theme.of(context)
//                               .textTheme
//                               .headline6!
//                               .copyWith(
//                                   color:
//                                       Theme.of(context).colorScheme.fontColor),
//                         )),
//                   ),
//                   InkWell(
//                     onTap: () {
//                       sortBy = '';
//                       orderBy = 'DESC';
//                       if (mounted) {
//                         setState(() {
//                           _isLoading = true;
//                           total = 0;
//                           offset = 0;
//                           productList.clear();
//                         });
//                       }
//                       getProduct("1");
//                       Navigator.pop(context, 'option 1');
//                     },
//                     child: Container(
//                       width: deviceWidth,
//                       color: sortBy == ''
//                           ? colors.primary
//                           : Theme.of(context).colorScheme.white,
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 15),
//                       child: Text(getTranslated(context, 'TOP_RATED')!,
//                           style: Theme.of(context)
//                               .textTheme
//                               .subtitle1!
//                               .copyWith(
//                                   color: sortBy == ''
//                                       ? Theme.of(context).colorScheme.white
//                                       : Theme.of(context)
//                                           .colorScheme
//                                           .fontColor)),
//                     ),
//                   ),
//                   InkWell(
//                       child: Container(
//                           width: deviceWidth,
//                           color: sortBy == 'p.date_added' && orderBy == 'DESC'
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 15),
//                           child: Text(getTranslated(context, 'F_NEWEST')!,
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .subtitle1!
//                                   .copyWith(
//                                       color: sortBy == 'p.date_added' &&
//                                               orderBy == 'DESC'
//                                           ? Theme.of(context).colorScheme.white
//                                           : Theme.of(context)
//                                               .colorScheme
//                                               .fontColor))),
//                       onTap: () {
//                         sortBy = 'p.date_added';
//                         orderBy = 'DESC';
//                         if (mounted) {
//                           setState(() {
//                             _isLoading = true;
//                             total = 0;
//                             offset = 0;
//                             productList.clear();
//                           });
//                         }
//                         getProduct("0");
//                         Navigator.pop(context, 'option 1');
//                       }),
//                   InkWell(
//                       child: Container(
//                           width: deviceWidth,
//                           color: sortBy == 'p.date_added' && orderBy == 'ASC'
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 15),
//                           child: Text(
//                             getTranslated(context, 'F_OLDEST')!,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .subtitle1!
//                                 .copyWith(
//                                     color: sortBy == 'p.date_added' &&
//                                             orderBy == 'ASC'
//                                         ? Theme.of(context).colorScheme.white
//                                         : Theme.of(context)
//                                             .colorScheme
//                                             .fontColor),
//                           )),
//                       onTap: () {
//                         sortBy = 'p.date_added';
//                         orderBy = 'ASC';
//                         if (mounted) {
//                           setState(() {
//                             _isLoading = true;
//                             total = 0;
//                             offset = 0;
//                             productList.clear();
//                           });
//                         }
//                         getProduct("0");
//                         Navigator.pop(context, 'option 2');
//                       }),
//                   InkWell(
//                       child: Container(
//                           width: deviceWidth,
//                           color: sortBy == 'pv.price' && orderBy == 'ASC'
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 15),
//                           child: Text(
//                             getTranslated(context, 'F_LOW')!,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .subtitle1!
//                                 .copyWith(
//                                     color: sortBy == 'pv.price' &&
//                                             orderBy == 'ASC'
//                                         ? Theme.of(context).colorScheme.white
//                                         : Theme.of(context)
//                                             .colorScheme
//                                             .fontColor),
//                           )),
//                       onTap: () {
//                         sortBy = 'pv.price';
//                         orderBy = 'ASC';
//                         if (mounted) {
//                           setState(() {
//                             _isLoading = true;
//                             total = 0;
//                             offset = 0;
//                             productList.clear();
//                           });
//                         }
//                         getProduct("0");
//                         Navigator.pop(context, 'option 3');
//                       }),
//                   InkWell(
//                       child: Container(
//                           width: deviceWidth,
//                           color: sortBy == 'pv.price' && orderBy == 'DESC'
//                               ? colors.primary
//                               : Theme.of(context).colorScheme.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 15),
//                           child: Text(
//                             getTranslated(context, 'F_HIGH')!,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .subtitle1!
//                                 .copyWith(
//                                     color: sortBy == 'pv.price' &&
//                                             orderBy == 'DESC'
//                                         ? Theme.of(context).colorScheme.white
//                                         : Theme.of(context)
//                                             .colorScheme
//                                             .fontColor),
//                           )),
//                       onTap: () {
//                         sortBy = 'pv.price';
//                         orderBy = 'DESC';
//                         if (mounted) {
//                           setState(() {
//                             _isLoading = true;
//                             total = 0;
//                             offset = 0;
//                             productList.clear();
//                           });
//                         }
//                         getProduct("0");
//                         Navigator.pop(context, 'option 4');
//                       }),
//                 ]),
//           );
//         });
//       },
//     );
//   }


//     void filterDialog() {
//     showModalBottomSheet(
//       context: context,
//       enableDrag: false,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       builder: (builder) {
//         _currentRangeValues =
//             RangeValues(double.parse(minPrice), double.parse(maxPrice));
//         return StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//           return Column(mainAxisSize: MainAxisSize.min, children: [
//             Padding(
//                 padding: const EdgeInsetsDirectional.only(top: 30.0),
//                 child: AppBar(
//                   title: Text(
//                     getTranslated(context, 'FILTER')!,
//                     style: TextStyle(
//                       color: Theme.of(context).colorScheme.fontColor,
//                     ),
//                   ),
//                   centerTitle: true,
//                   elevation: 5,
//                   backgroundColor: Theme.of(context).colorScheme.white,
//                   leading: Builder(builder: (BuildContext context) {
//                     return Container(
//                       margin: const EdgeInsets.all(10),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(4),
//                         onTap: () => Navigator.of(context).pop(),
//                         child: const Padding(
//                           padding: EdgeInsetsDirectional.only(end: 4.0),
//                           child: Icon(Icons.arrow_back_ios_rounded,
//                               color: colors.primary),
//                         ),
//                       ),
//                     );
//                   }),
//                 )),
//             Expanded(
//                 child: Container(
//               color: Theme.of(context).colorScheme.lightWhite,
//               padding: const EdgeInsetsDirectional.only(
//                   start: 7.0, end: 7.0, top: 7.0),
//               child: filterList != null
//                   ? ListView.builder(
//                       shrinkWrap: true,
//                       scrollDirection: Axis.vertical,
//                       padding: const EdgeInsetsDirectional.only(top: 10.0),
//                       itemCount: filterList.length + 1,
//                       itemBuilder: (context, index) {
//                         if (index == 0) {
//                           return Column(
//                             children: [
//                               SizedBox(
//                                   width: deviceWidth,
//                                   child: Card(
//                                       elevation: 0,
//                                       child: Padding(
//                                           padding: const EdgeInsets.all(8.0),
//                                           child: Text(
//                                             'Price Range',
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .subtitle1!
//                                                 .copyWith(
//                                                     color: Theme.of(context)
//                                                         .colorScheme
//                                                         .lightBlack,
//                                                     fontWeight:
//                                                         FontWeight.normal),
//                                             overflow: TextOverflow.ellipsis,
//                                             maxLines: 2,
//                                           )))),
//                               RangeSlider(
//                                 values: _currentRangeValues!,
//                                 min: double.parse(minPrice),
//                                 max: double.parse(maxPrice),
//                                 divisions: 10,
//                                 labels: RangeLabels(
//                                   _currentRangeValues!.start.round().toString(),
//                                   _currentRangeValues!.end.round().toString(),
//                                 ),
//                                 onChanged: (RangeValues values) {
//                                   setState(() {
//                                     _currentRangeValues = values;
//                                   });
//                                 },
//                               ),
//                             ],
//                           );
//                         } else {
//                           index = index - 1;
//                           attsubList =
//                               filterList[index]['attribute_values'].split(',');

//                           attListId = filterList[index]['attribute_values_id']
//                               .split(',');

//                           List<Widget?> chips = [];
//                           List<String> att =
//                               filterList[index]['attribute_values']!.split(',');

//                           List<String> attSType =
//                               filterList[index]['swatche_type'].split(',');

//                           List<String> attSValue =
//                               filterList[index]['swatche_value'].split(',');

//                           for (int i = 0; i < att.length; i++) {
//                             Widget itemLabel;
//                             if (attSType[i] == "1") {
//                               String clr = (attSValue[i].substring(1));

//                               String color = "0xff$clr";

//                               itemLabel = Container(
//                                 width: 25,
//                                 decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: Color(int.parse(color))),
//                               );
//                             } else if (attSType[i] == "2") {
//                               itemLabel = ClipRRect(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                   child: Image.network(attSValue[i],
//                                       width: 80,
//                                       height: 80,
//                                       errorBuilder:
//                                           (context, error, stackTrace) =>
//                                               erroWidget(80)));
//                             } else {
//                               itemLabel = Padding(
//                                 padding:
//                                     const EdgeInsets.symmetric(horizontal: 8.0),
//                                 child: Text(att[i],
//                                     style: TextStyle(
//                                         color:
//                                             selectedId.contains(attListId![i])
//                                                 ? Theme.of(context)
//                                                     .colorScheme
//                                                     .white
//                                                 : Theme.of(context)
//                                                     .colorScheme
//                                                     .fontColor)),
//                               );
//                             }

//                             choiceChip = ChoiceChip(
//                               selected: selectedId.contains(attListId![i]),
//                               label: itemLabel,
//                               labelPadding: const EdgeInsets.all(0),
//                               selectedColor: colors.primary,
//                               backgroundColor:
//                                   Theme.of(context).colorScheme.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(
//                                     attSType[i] == "1" ? 100 : 10),
//                                 side: BorderSide(
//                                     color: selectedId.contains(attListId![i])
//                                         ? colors.primary
//                                         : colors.black12,
//                                     width: 1.5),
//                               ),
//                               onSelected: (bool selected) {
//                                 attListId = filterList[index]
//                                         ['attribute_values_id']
//                                     .split(',');

//                                 if (mounted) {
//                                   setState(() {
//                                     if (selected == true) {
//                                       selectedId.add(attListId![i]);
//                                     } else {
//                                       selectedId.remove(attListId![i]);
//                                     }
//                                   });
//                                 }
//                               },
//                             );

//                             chips.add(choiceChip);
//                           }

//                           return Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               SizedBox(
//                                 width: deviceWidth,
//                                 child: Card(
//                                   elevation: 0,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Text(
//                                       filterList[index]['name'],
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .subtitle1!
//                                           .copyWith(
//                                               color: Theme.of(context)
//                                                   .colorScheme
//                                                   .fontColor,
//                                               fontWeight: FontWeight.normal),
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               chips.isNotEmpty
//                                   ? Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Wrap(
//                                         children:
//                                             chips.map<Widget>((Widget? chip) {
//                                           return Padding(
//                                             padding: const EdgeInsets.all(2.0),
//                                             child: chip,
//                                           );
//                                         }).toList(),
//                                       ),
//                                     )
//                                   : Container()
//                             ],
//                           );
//                         }
//                       })
//                   : Container(),
//             )),
//             Container(
//               color: Theme.of(context).colorScheme.white,
//               child: Row(children: <Widget>[
//                 Container(
//                   margin: const EdgeInsetsDirectional.only(start: 20),
//                   width: deviceWidth! * 0.4,
//                   child: OutlinedButton(
//                     onPressed: () {
//                       if (mounted) {
//                         setState(() {
//                           selectedId.clear();
//                         });
//                       }
//                     },
//                     child: Text(getTranslated(context, 'DISCARD')!),
//                   ),
//                 ),
//                 const Spacer(),
//                 Padding(
//                   padding: const EdgeInsetsDirectional.only(end: 20),
//                   child: SimBtn(
//                       width: 0.4,
//                       height: 35,
//                       title: getTranslated(context, 'APPLY'),
//                       onBtnSelected: () {
//                         selId = selectedId.join(',');

//                         if (mounted) {
//                           setState(() {
//                             _isLoading = true;
//                             total = 0;
//                             offset = 0;
//                             productList.clear();
//                           });
//                         }
//                         getProduct("0");
//                         Navigator.pop(context, 'Product Filter');
//                       }),
//                 ),
//               ]),
//             )
//           ]);
//         });
//       },
//     );
//   }
// }

