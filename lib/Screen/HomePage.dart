import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/ui/widgets/AppBtn.dart';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/ui/widgets/HamburgerMenu.dart';
import 'package:eshop/ui/widgets/SimBtn.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Model.dart';
import 'package:eshop/Model/UserLoginModel.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/CategoryProvider.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Search.dart';

import 'package:eshop/Screen/SubCategory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:version/version.dart';

import '../Provider/ProductDetailProvider.dart';
import '../Provider/ProductProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/ProductListView.dart';
import '../ui/widgets/setTitleWidget.dart';
import 'Login.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';
import 'Product_DetailNew.dart';
import 'SectionList.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

List<SectionModel> sectionList = [];
List<Product> catList = [];
List<Product> popularList = [];
ApiBaseHelper apiBaseHelper = ApiBaseHelper();
List<String> tagList = [];
List<Product> sellerList = [];
List<Model> homeSliderList = [];
List<Widget> pages = [];
UserLoginData? userLoginData;
int count = 1;

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final _controller = PageController();
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
//  List<Model> offerImages = [];
  final ScrollController _scrollBottomBarController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  double beginAnim = 0.0;

  double endAnim = 1.0;
  var db = DatabaseHelper();
  List<String> proIds = [];
  List<Product> mostLikeProList = [];
  List<String> proIds1 = [];
  List<Product> mostFavProList = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    callApi();
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) => _animateSlider());
  }

  @override
  void dispose() {
    _scrollBottomBarController.removeListener(() {});
    _controller.dispose();
    buttonController.dispose();
    super.dispose();
  }

  setUserData() {
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);
    UserProvider user = Provider.of<UserProvider>(context, listen: false);

    user.setMobile(setting.mobile);
    user.setName(setting.userName);
    user.setEmail(setting.email);
    user.setPassword(setting.password);
    user.setProfilePic(setting.profileUrl);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userDetails =
        Provider.of<UserProvider>(context, listen: false);
    hideAppbarAndBottomBarOnScroll(_scrollBottomBarController, context);
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        drawer: HamburgerMenu(),
        body: _isNetworkAvail
            ? RefreshIndicator(
                color: colors.primary,
                key: _refreshIndicatorKey,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  controller: _scrollBottomBarController,
                  child: Column(
                    children: [
                      _deliverPincode(),
                      _userDashboard(),
                      // _getSearchBar(),
                      _slider(),
                      _catList(),
                      _shopByPV(),
                      _achievers(),
                      _youtube(),
                      _successStories(),
                      _section(),
                      _mostLike(),
                    ],
                  ),
                ))
            : noInternet(context));
  }

  Future<void> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setOfferLoading(true);
    context.read<HomeProvider>().setMostLikeLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);
    proIds.clear();

    return callApi();
  }

  Widget _slider() {
    double height = deviceWidth! / 2.2;

    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? sliderLoading()
            : Stack(
                children: [
                  SizedBox(
                    height: height,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: homeSliderList.length,
                      scrollDirection: Axis.horizontal,
                      controller: _controller,
                      physics: const AlwaysScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          context.read<HomeProvider>().setCurSlider(index);
                        });
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return pages[index];
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    height: 40,
                    left: 0,
                    width: deviceWidth,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: map<Widget>(
                        homeSliderList,
                        (index, url) {
                          return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: context.read<HomeProvider>().curSlider ==
                                      index
                                  ? 25
                                  : 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 2.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: context.read<HomeProvider>().curSlider ==
                                        index
                                    ? Theme.of(context).colorScheme.fontColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .lightBlack
                                        .withOpacity(0.7),
                              ));
                        },
                      ),
                    ),
                  ),
                ],
              );
      },
      selector: (_, homeProvider) => homeProvider.sliderLoading,
    );
  }

  void _animateSlider() {
    Future.delayed(const Duration(seconds: 10)).then((_) {
      if (mounted) {
        int nextPage = _controller.hasClients
            ? _controller.page!.round() + 1
            : _controller.initialPage;

        if (nextPage == homeSliderList.length) {
          nextPage = 0;
        }
        if (_controller.hasClients) {
          _controller
              .animateToPage(nextPage,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear)
              .then((_) {
            _animateSlider();
          });
        }
      }
    });
  }

  _singleSection(int index) {
    Color back;
    int pos = index % 5;
    if (pos == 0) {
      back = Theme.of(context).colorScheme.back1;
    } else if (pos == 1) {
      back = Theme.of(context).colorScheme.back2;
    } else if (pos == 2) {
      back = Theme.of(context).colorScheme.back3;
    } else if (pos == 3) {
      back = Theme.of(context).colorScheme.back4;
    } else {
      back = Theme.of(context).colorScheme.back5;
    }

    return sectionList[index].productList!.isNotEmpty
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20)))),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _getHeading(
                            sectionList[index].title ?? "", index, 1, []),
                        _getSection(index),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : Container();
  }

  _getHeading(String title, int index, int from, List<Product> productList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (from == 1)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20)),
                    color: Colors.yellow,
                  ),
                  padding: const EdgeInsetsDirectional.only(
                      start: 12, bottom: 3, top: 3, end: 12),
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(color: colors.blackTemp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Padding(
            padding: const EdgeInsetsDirectional.only(start: 12.0, end: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      from == 2 ? title : sectionList[index].shortDesc ?? "",
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor)),
                ),
                TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero, //
                        backgroundColor: (Theme.of(context).colorScheme.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5)),
                    child: Text(
                      getTranslated(context, 'SHOP_NOW')!,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      SectionModel model = sectionList[index];
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => SectionList(
                              index: index,
                              section_model: model,
                              from: from,
                              productList: productList,
                            ),
                          ));
                    }),
              ],
            )),
      ],
    );
  }

/*  _getOfferImage(index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: InkWell(
        child: CachedNetworkImage(
            imageUrl: offerImages[index].image!,
            fadeInDuration: const Duration(milliseconds: 150),
            width: double.maxFinite,
            errorWidget: (context, error, stackTrace) => erroWidget(50),

            // errorWidget: (context, url, e) => return return placeHolder(50),
            placeholder: (BuildContext context, url) {
              return Image.asset(
                "assets/images/sliderph.png",
              );
            }),
        onTap: () {
          if (offerImages[index].type == "products") {
            Product? item = offerImages[index].list;
            currentHero = homeHero;
            Navigator.push(
              context,
              PageRouteBuilder(
                  //transitionDuration: Duration(seconds: 1),
                  pageBuilder: (_, __, ___) => ProductDetail(
                        secPos: 0, index: 0, list: true, id: item!.id!,
                        //  title: sectionList[secPos].title,
                      )),
            );
          } else if (offerImages[index].type == "categories") {
            Product item = offerImages[index].list;
            if (item.subList == null || item.subList!.isEmpty) {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ProductList(
                      name: item.name,
                      id: item.id,
                      tag: false,
                      fromSeller: false,
                    ),
                  ));
            } else {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => SubCategory(
                      title: item.name!,
                      subList: item.subList,
                    ),
                  ));
            }
          }
        },
      ),
    );
  }*/

  _getSection(int i) {
    var orient = MediaQuery.of(context).orientation;

    return sectionList[i].style == DEFAULT
        ? Padding(
            padding: const EdgeInsets.all(15.0),
            child: GridView.count(
                padding: const EdgeInsetsDirectional.only(top: 5),
                crossAxisCount: 2,
                shrinkWrap: true,
                //childAspectRatio: 0.8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  sectionList[i].productList!.length < 4
                      ? sectionList[i].productList!.length
                      : 4,
                  (index) {
                    return productItem(
                        i,
                        index,
                        index % 2 == 0 ? true : false,
                        sectionList[i].productList![index],
                        1,
                        sectionList[i].productList!.length);
                  },
                )),
          )
        : sectionList[i].style == STYLE1
            ? sectionList[i].productList!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: SizedBox(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.4
                                    : deviceHeight,
                                child: sectionList[i].productList!.length ==
                                            1 ||
                                        sectionList[i].productList!.length > 1
                                    ? productItem(
                                        i,
                                        0,
                                        true,
                                        sectionList[i].productList![0],
                                        1,
                                        sectionList[i].productList!.length)
                                    : Container())),
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: sectionList[i].productList!.length ==
                                              2 ||
                                          sectionList[i].productList!.length > 2
                                      ? productItem(
                                          i,
                                          1,
                                          false,
                                          sectionList[i].productList![1],
                                          1,
                                          sectionList[i].productList!.length)
                                      : Container()),
                              SizedBox(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: sectionList[i].productList!.length ==
                                              3 ||
                                          sectionList[i].productList!.length > 3
                                      ? productItem(
                                          i,
                                          2,
                                          false,
                                          sectionList[i].productList![2],
                                          1,
                                          sectionList[i].productList!.length)
                                      : Container()),
                            ],
                          ),
                        ),
                      ],
                    ))
                : Container()
            : sectionList[i].style == STYLE2
                ? Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 2,
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: sectionList[i].productList!.length ==
                                              1 ||
                                          sectionList[i].productList!.length > 1
                                      ? productItem(
                                          i,
                                          0,
                                          true,
                                          sectionList[i].productList![0],
                                          1,
                                          sectionList[i].productList!.length)
                                      : Container()),
                              SizedBox(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: sectionList[i].productList!.length ==
                                              2 ||
                                          sectionList[i].productList!.length > 2
                                      ? productItem(
                                          i,
                                          1,
                                          true,
                                          sectionList[i].productList![1],
                                          1,
                                          sectionList[i].productList!.length)
                                      : Container()),
                            ],
                          ),
                        ),
                        Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: SizedBox(
                                height: orient == Orientation.portrait
                                    ? deviceHeight! * 0.4
                                    : deviceHeight,
                                child: sectionList[i].productList!.length ==
                                            3 ||
                                        sectionList[i].productList!.length > 3
                                    ? productItem(
                                        i,
                                        2,
                                        false,
                                        sectionList[i].productList![2],
                                        1,
                                        sectionList[i].productList!.length)
                                    : Container())),
                      ],
                    ))
                : sectionList[i].style == STYLE3
                    ? Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                                flex: 1,
                                fit: FlexFit.loose,
                                child: SizedBox(
                                    height: orient == Orientation.portrait
                                        ? deviceHeight! * 0.3
                                        : deviceHeight! * 0.6,
                                    child: sectionList[i].productList!.length ==
                                                1 ||
                                            sectionList[i].productList!.length >
                                                1
                                        ? productItem(
                                            i,
                                            0,
                                            false,
                                            sectionList[i].productList![0],
                                            1,
                                            sectionList[i].productList!.length)
                                        : Container())),
                            SizedBox(
                              height: orient == Orientation.portrait
                                  ? deviceHeight! * 0.2
                                  : deviceHeight! * 0.5,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: sectionList[i]
                                                      .productList!
                                                      .length >=
                                                  2 ||
                                              sectionList[i]
                                                      .productList!
                                                      .length >
                                                  2
                                          ? productItem(
                                              i,
                                              1,
                                              true,
                                              sectionList[i].productList![1],
                                              1,
                                              sectionList[i]
                                                  .productList!
                                                  .length)
                                          : Container()),
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: sectionList[i]
                                                      .productList!
                                                      .length ==
                                                  3 ||
                                              sectionList[i]
                                                      .productList!
                                                      .length >
                                                  3
                                          ? productItem(
                                              i,
                                              2,
                                              true,
                                              sectionList[i].productList![2],
                                              1,
                                              sectionList[i]
                                                  .productList!
                                                  .length)
                                          : Container()),
                                  Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: sectionList[i]
                                                  .productList!
                                                  .length >=
                                              4
                                          ? productItem(
                                              i,
                                              3,
                                              false,
                                              sectionList[i].productList![3],
                                              1,
                                              sectionList[i]
                                                  .productList!
                                                  .length)
                                          : Container()),
                                ],
                              ),
                            ),
                          ],
                        ))
                    : sectionList[i].style == STYLE4
                        ? Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    flex: 1,
                                    fit: FlexFit.loose,
                                    child: SizedBox(
                                        height: orient == Orientation.portrait
                                            ? deviceHeight! * 0.25
                                            : deviceHeight! * 0.5,
                                        child: sectionList[i]
                                                        .productList!
                                                        .length ==
                                                    1 ||
                                                sectionList[i]
                                                        .productList!
                                                        .length >
                                                    1
                                            ? productItem(
                                                i,
                                                0,
                                                false,
                                                sectionList[i].productList![0],
                                                1,
                                                sectionList[i]
                                                    .productList!
                                                    .length)
                                            : Container())),
                                SizedBox(
                                  height: orient == Orientation.portrait
                                      ? deviceHeight! * 0.2
                                      : deviceHeight! * 0.5,
                                  child: Row(
                                    children: [
                                      Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: sectionList[i]
                                                          .productList!
                                                          .length ==
                                                      2 ||
                                                  sectionList[i]
                                                          .productList!
                                                          .length >
                                                      2
                                              ? productItem(
                                                  i,
                                                  1,
                                                  true,
                                                  sectionList[i]
                                                      .productList![1],
                                                  1,
                                                  sectionList[i]
                                                      .productList!
                                                      .length)
                                              : Container()),
                                      Flexible(
                                          flex: 1,
                                          fit: FlexFit.loose,
                                          child: sectionList[i]
                                                          .productList!
                                                          .length ==
                                                      3 ||
                                                  sectionList[i]
                                                          .productList!
                                                          .length >
                                                      3
                                              ? productItem(
                                                  i,
                                                  2,
                                                  false,
                                                  sectionList[i]
                                                      .productList![2],
                                                  1,
                                                  sectionList[i]
                                                      .productList!
                                                      .length)
                                              : Container()),
                                    ],
                                  ),
                                ),
                              ],
                            ))
                        : Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: GridView.count(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5),
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                childAspectRatio: 1.2,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 0,
                                children: List.generate(
                                  sectionList[i].productList!.length < 6
                                      ? sectionList[i].productList!.length
                                      : 6,
                                  (index) {
                                    return productItem(
                                        i,
                                        index,
                                        index % 2 == 0 ? true : false,
                                        sectionList[i].productList![index],
                                        1,
                                        sectionList[i].productList!.length);
                                  },
                                )));
  }

  Widget productItem(
      int secPos, int index, bool pad, Product product, int from, int len) {
    if (len > index) {
      String? offPer;
      double price = double.parse(product.prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(product.prVarientList![0].price!);
      } else {
        double off = double.parse(product.prVarientList![0].price!) - price;
        offPer = ((off * 100) / double.parse(product.prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;
      return Card(
        elevation: 0.0,

        margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
        //end: pad ? 5 : 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5)),
                    child: Hero(
                        transitionOnUserGestures: true,
                        tag: "$homeHero$index${product.id}$secPos",
                        child: networkImageCommon(product.image!, width, false,
                            height: double.maxFinite,
                            width: double
                                .maxFinite) /*CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          imageUrl: product.image!,
                          height: double.maxFinite,
                          width: double.maxFinite,
                          fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(double.maxFinite),
                          //fit: BoxFit.fill,
                          placeholder: (context, url) {
                            return placeHolder(width);
                          }),*/
                        )),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 10.0,
                  top: 5,
                ),
                child: Text(
                  product.name!,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 10.0, top: 2),
                  child: Text(
                      product.isSalesOn == "1"
                          ? getPriceFormat(
                              context,
                              double.parse(
                                  product.prVarientList![0].saleFinalPrice!))!
                          : '${getPriceFormat(context, price)!} ',
                      style: TextStyle(
                          fontSize: 11.0,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 10.0, bottom: 8, top: 2),
                child: double.parse(product.prVarientList![0].disPrice!) != 0
                    ? Row(
                        children: <Widget>[
                          Text(
                            double.parse(product.prVarientList![0].disPrice!) !=
                                    0
                                ? getPriceFormat(
                                    context,
                                    double.parse(
                                        product.prVarientList![0].price!))!
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .overline!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.6)),
                          ),
                          Flexible(
                            child: Text(
                                " | "
                                "-${product.isSalesOn == "1" ? double.parse(product.saleDis!).toStringAsFixed(2) : offPer}%",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .overline!
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              )
            ],
          ),
          onTap: () {
            Product model = product;
            currentHero = homeHero;
            Navigator.push(
              context,
              PageRouteBuilder(
                  // transitionDuration: Duration(milliseconds: 150),
                  pageBuilder: (_, __, ___) => ProductDetail(
                        secPos: secPos,
                        index: index,
                        list: false,
                        id: model.id!,

                        //  title: sectionList[secPos].title,
                      )),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

  _section() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? SizedBox(
                width: double.infinity,
                child: Shimmer.fromColors(
                    baseColor: Theme.of(context).colorScheme.simmerBase,
                    highlightColor: Theme.of(context).colorScheme.simmerHigh,
                    child: sectionLoading()))
            : ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: sectionList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _singleSection(index);
                },
              );
      },
      selector: (_, homeProvider) => homeProvider.secLoading,
    );
  }

  _mostLike() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Stack(children: [
                Positioned.fill(
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.back3,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20)))),
                ),
                Selector<ProductProvider, List<Product>>(
                  builder: (context, data1, child) {
                    return data1.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _getHeading(
                                      "You might also like", 0, 2, data1),
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: GridView.count(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                top: 5),
                                        crossAxisCount: 2,
                                        shrinkWrap: true,
                                        //childAspectRatio: 0.8,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        children: List.generate(
                                          data1.length < 4 ? data1.length : 4,
                                          (index) {
                                            return productItem(
                                                0,
                                                index,
                                                index % 2 == 0 ? true : false,
                                                data1[index],
                                                2,
                                                data1.length);
                                          },
                                        )),
                                  ),
                                  //  setHeadTitle("You might also like",context),
                                  /*Container(
                            height: 230,
                           // padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child:  ListView.builder(
                                      physics:
                                      const AlwaysScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                       itemCount:  data1.length,
                                      itemBuilder: (context, index) {
                                        return productItemView(index, data1,context);
                                      },
                                    ),
                            ),
                          ),*/
                                ]))
                        : SizedBox();
                  },
                  selector: (_, provider) => provider.productList,
                )
              ]))
        ]);
      },
      selector: (_, homeProvider) => homeProvider.mostLikeLoading,
    );
  }

  /*_mostFav() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return mostFavProList.isNotEmpty?Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[

                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                              margin: const EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.back1,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20)))),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _getFavHead("Your favourite"),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: GridView.count(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5),
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  //childAspectRatio: 0.8,
                                  physics:
                                  const NeverScrollableScrollPhysics(),
                                  children: List.generate(
                                    mostFavProList.length < 4 ? mostFavProList.length: 4,
                                        (index) {
                                      return productItemView(index, mostFavProList,context);
                                    },
                                  )),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ):SizedBox();
      },
      selector: (_, homeProvider) => homeProvider.mostLikeLoading,
    );
  }*/

  /*Widget productItem1(int index, List<Product> mostLikePro) {
    if (mostLikePro.length > index) {
      String? offPer;
      double price =
          double.parse(mostLikePro[index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(mostLikePro[index].prVarientList![0].price!);
      } else {
        double off =
            double.parse(mostLikePro[index].prVarientList![0].price!) - price;
        offPer = ((off * 100) /
                double.parse(mostLikePro[index].prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.5;

      return Card(
        elevation: 0.0,

        margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
        //end: pad ? 5 : 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)),
                        child: Hero(
                          transitionOnUserGestures: true,
                          tag: "$index${mostLikePro[index].id}",
                          child: FadeInImage(
                            fadeInDuration: const Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(mostLikePro[index].image!),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            fit: extendImg ? BoxFit.fill : BoxFit.fitHeight,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(double.maxFinite),
                            //fit: BoxFit.fill,
                            placeholder: (context,url) {return placeHolder(width),
                          ),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 10.0,
                  top: 5,
                ),
                child: Text(
                  mostLikePro[index].name!,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 10.0, top: 2),
                  child: Text('${getPriceFormat(context, price)!} ',
                      style: TextStyle(
                          fontSize: 11.0,
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 10.0, bottom: 8, top: 2),
                child: double.parse(
                            mostLikePro[index].prVarientList![0].disPrice!) !=
                        0
                    ? Row(
                        children: <Widget>[
                          Text(
                            double.parse(mostLikePro[index]
                                        .prVarientList![0]
                                        .disPrice!) !=
                                    0
                                ? getPriceFormat(
                                    context,
                                    double.parse(mostLikePro[index]
                                        .prVarientList![0]
                                        .price!))!
                                : "",
                            style: Theme.of(context)
                                .textTheme
                                .overline!
                                .copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    letterSpacing: 0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.6)),
                          ),
                          Flexible(
                            child: Text(" | " "-$offPer%",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .overline!
                                    .copyWith(
                                        color: colors.primary,
                                        letterSpacing: 0)),
                          ),
                        ],
                      )
                    : Container(
                        height: 5,
                      ),
              )
            ],
          ),
          onTap: () {
            Product model = mostLikePro[index];
            Navigator.push(
              context,
              PageRouteBuilder(
                  // transitionDuration: Duration(milliseconds: 150),
                  pageBuilder: (_, __, ___) => ProductDetail(
                        model: model, secPos: 0, index: index, list: false,

                        //  title: sectionList[secPos].title,
                      )),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }*/

  _catList() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? SizedBox(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: catLoading(),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Shop by Category',
                    style: Theme.of(context).textTheme.headline6!.copyWith(
                        color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 125,
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: ListView.builder(
                      itemCount: catList.length < 10 ? catList.length : 10,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container();
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              // borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey[200]!,
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: Offset(
                                      0, 5), // changes position of shadow
                                ),
                              ],
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: InkWell(
                              onTap: () async {
                                if (catList[index].subList == null ||
                                    catList[index].subList!.isEmpty) {
                                  await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ProductList(
                                        name: catList[index].name,
                                        id: catList[index].id,
                                        tag: false,
                                        fromSeller: false,
                                      ),
                                    ),
                                  );
                                } else {
                                  await Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => SubCategory(
                                        title: catList[index].name!,
                                        subList: catList[index].subList,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        bottom: 5.0, top: 8.0),
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          // shape: BoxShape.circle,
                                          // boxShadow: [
                                          //   BoxShadow(
                                          //     color: Theme.of(context)
                                          //         .colorScheme
                                          //         .fontColor
                                          //         .withOpacity(0.048),
                                          //     spreadRadius: 2,
                                          //     blurRadius: 13,
                                          //     offset: const Offset(0,
                                          //         0), // changes position of shadow
                                          //   ),
                                          // ],
                                        ),
                                        child: Image.network(
                                          catList[index].image!,
                                          height: 75,
                                          width: 75,
                                        )
                                        /*CachedNetworkImage(
                                                fadeInDuration: const Duration(
                                                    milliseconds: 150),
                                                imageUrl: catList[index].image!,
                                                fit: BoxFit.fill,
                                                errorWidget:
                                                    (context, error, stackTrace) =>
                                                        erroWidget(50),
                                                placeholder: (context, url) {
                                                  return placeHolder(50);
                                                }),*/
                                        ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      capitalize(
                                          catList[index].name!.toLowerCase()),
                                      style: Theme.of(context)
                                          .textTheme
                                          .caption!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                ],
              );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );
  }

  _shopByPV() {
    return Selector<HomeProvider, bool>(
      builder: (context, data, child) {
        return data
            ? SizedBox(
                width: double.infinity,
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.simmerBase,
                  highlightColor: Theme.of(context).colorScheme.simmerHigh,
                  child: catLoading(),
                ),
              )
            : Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Shop by PV',
                      style: Theme.of(context).textTheme.headline6!.copyWith(
                          color: colors.primary, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      height: 125,
                      padding: const EdgeInsets.only(top: 10, left: 10),
                      child: ListView.builder(
                        itemCount: catList.length < 10 ? catList.length : 10,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container();
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                // borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[200]!,
                                    spreadRadius: 1,
                                    blurRadius: 7,
                                    offset: Offset(
                                        5, 5), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 10),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              child: InkWell(
                                onTap: () async {
                                  if (catList[index].subList == null ||
                                      catList[index].subList!.isEmpty) {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ProductList(
                                          name: catList[index].name,
                                          id: catList[index].id,
                                          tag: false,
                                          fromSeller: false,
                                        ),
                                      ),
                                    );
                                  } else {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => SubCategory(
                                          title: catList[index].name!,
                                          subList: catList[index].subList,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          bottom: 5.0, top: 8.0),
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                          ),
                                          child: Image.network(
                                            catList[index].image!,
                                            height: 75,
                                            width: 75,
                                          )),
                                    ),
                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        capitalize(
                                            catList[index].name!.toLowerCase()),
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              );
      },
      selector: (_, homeProvider) => homeProvider.catLoading,
    );

    // return Container(
    //   color: Color(0xfffdfdff),
    //   margin: const EdgeInsets.symmetric(vertical: 10),
    //   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         'Shop By PV',
    //         style: TextStyle(
    //           color: colors.primary,
    //           fontSize: 16,
    //           fontWeight: FontWeight.w600,
    //         ),
    //       ),
    //       SizedBox(
    //         height: 10,
    //       ),
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //         children: [
    //           Container(
    //             padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    //             child: Text(
    //               '0-25',
    //               style: TextStyle(color: Color(0xfff0f0f0)),
    //             ),
    //             decoration: BoxDecoration(
    //               color: colors.primary,
    //               borderRadius: BorderRadius.circular(15),
    //             ),
    //           ),
    //           Container(
    //             padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    //             child: Text(
    //               '25-50',
    //               style: TextStyle(color: Color(0xff1f1f1f)),
    //             ),
    //             decoration: BoxDecoration(
    //               color: Colors.blueGrey[300],
    //               borderRadius: BorderRadius.circular(15),
    //             ),
    //           ),
    //           Container(
    //             padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    //             child: Text(
    //               '50-100',
    //               style: TextStyle(color: Color(0xff1f1f1f)),
    //             ),
    //             decoration: BoxDecoration(
    //               color: Colors.blueGrey[300],
    //               borderRadius: BorderRadius.circular(15),
    //             ),
    //           ),
    //           Container(
    //             padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    //             child: Text('100+', style: TextStyle(color: Color(0xff1f1f1f))),
    //             decoration: BoxDecoration(
    //               color: Colors.blueGrey[300],
    //               borderRadius: BorderRadius.circular(15),
    //             ),
    //           ),
    //         ],
    //       ),
    //       SingleChildScrollView(
    //         scrollDirection: Axis.vertical,
    //         physics: ScrollPhysics(parent: BouncingScrollPhysics()),
    //         child: Container(
    //           padding: EdgeInsets.symmetric(vertical: 12),
    //           child: ListView.builder(
    //             padding: const EdgeInsets.all(0),
    //             itemCount: 2,
    //             shrinkWrap: true,
    //             itemBuilder: (context, index) {
    //               return Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //                 children: [
    //                   _productCard(),
    //                   _productCard(),
    //                 ],
    //               );
    //             },
    //           ),
    //         ),
    //       )
    //     ],
    //   ),
    // );
  }

  // _productCard() {
  //   return Card(
  //     shadowColor: Colors.blueGrey[300],
  //     elevation: 5,
  //     child: InkWell(
  //       onTap: () {},
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Stack(
  //               children: [
  //                 Container(
  //                   height: 120,
  //                   width: MediaQuery.of(context).size.width / 2.75,
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.only(
  //                       topLeft: Radius.circular(5),
  //                       topRight: Radius.circular(5),
  //                     ),
  //                     // color: Colors.blueGrey[300],
  //                   ),
  //                   child: Image.asset('assets/images/logo1.png'),
  //                 ),
  //                 Positioned(
  //                   bottom: 5,
  //                   right: 0,
  //                   child: Icon(Icons.bookmark_border_outlined),
  //                 )
  //               ],
  //             ),
  //             Text(
  //               '13.89 PV',
  //               style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.green[600],
  //                   fontWeight: FontWeight.w600),
  //             ),
  //             Text(
  //               'Item Code: 26015A',
  //               style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.green[600],
  //                   fontWeight: FontWeight.w600),
  //             ),
  //             Text(
  //               'Assure Soap 100 G',
  //               style: TextStyle(fontSize: 11, color: Colors.grey[400]),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  _youtube() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      height: 130,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            child: Image.asset(
              'assets/images/youtube.png',
              height: 50,
              width: 50,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUNEDGE MEDIA',
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Text(
                'Stay updated on the latest happenings',
                style: TextStyle(
                  color: colors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(
                height: 7,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/youtube');
                },
                label: Text('Watch Now'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _achievers() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      height: 200,
      decoration: BoxDecoration(
        color: Color(0xfffdfdff),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width / 3.5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                shadowColor: Colors.blueGrey[300],
                child: Stack(
                  children: [
                    Ink.image(
                      image: NetworkImage(
                          'https://www.motorbeam.com/wp-content/uploads/Tata-Harrier-Front-1200x900.jpg'),
                      fit: BoxFit.cover,
                      child: InkWell(
                        onTap: () => _showDialog(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Car Fund\nAchievers',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width / 3.5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                shadowColor: Colors.blueGrey[300],
                child: Stack(
                  children: [
                    Ink.image(
                      image: NetworkImage(
                          'https://www.motorbeam.com/wp-content/uploads/Tata-Harrier-Front-1200x900.jpg'),
                      fit: BoxFit.cover,
                      child: InkWell(
                        onTap: () => _showDialog(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Car Fund\nAchievers',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width / 3.5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                shadowColor: Colors.blueGrey[300],
                child: Stack(
                  children: [
                    Ink.image(
                      image: NetworkImage(
                          'https://www.motorbeam.com/wp-content/uploads/Tata-Harrier-Front-1200x900.jpg'),
                      fit: BoxFit.cover,
                      child: InkWell(
                        onTap: () => _showDialog(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Car Fund\nAchievers',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width / 3.5,
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                shadowColor: Colors.blueGrey[300],
                child: Stack(
                  children: [
                    Ink.image(
                      image: NetworkImage(
                          'https://www.motorbeam.com/wp-content/uploads/Tata-Harrier-Front-1200x900.jpg'),
                      fit: BoxFit.cover,
                      child: InkWell(
                        onTap: () => _showDialog(context),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Car Fund\nAchievers',
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _showDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      title: Stack(
        children: [
          Positioned(
            right: 0,
            child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close_rounded)),
          ),
          Center(
            child: Text(
              'Top Car Winners',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: colors.primary,
                  width: 1,
                ),
              ),
              child: Text(
                '1188',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: colors.primary,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: 25,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 5),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            child: Text(
                              'PJ',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'PREET JHUNJHUNWALA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(context: context, builder: (context) => alert);
  }

  _successStories() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/quote.png'),
          alignment: Alignment.topRight,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.1),
            BlendMode.dstATop,
          ),
          scale: 4,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 27,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Success Stories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.primary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      padding:
                          EdgeInsets.symmetric(vertical: 24, horizontal: 15),
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: Center(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vel malesuada urna. Morbi dignissim ex ipsum. Nullam vel ultricies tortor, nec efficitur libero. Etiam rutrum dignissim consequat. Nunc ac nunc tristique orci consectetur porttitor at nec massa. Nam tempor eleifend nulla ac placerat. Mauris faucibus turpis augue, a pulvinar sem sagittis sit amet.',
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right:
                          (MediaQuery.of(context).size.width * 0.75) / 2 - 20,
                      child: Image.asset(
                        'assets/images/user.png',
                        height: 40,
                        width: 40,
                        color: colors.primary,
                      ),
                    )
                  ],
                ),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.primary,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      padding:
                          EdgeInsets.symmetric(vertical: 24, horizontal: 15),
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: Center(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vel malesuada urna. Morbi dignissim ex ipsum. Nullam vel ultricies tortor, nec efficitur libero. Etiam rutrum dignissim consequat. Nunc ac nunc tristique orci consectetur porttitor at nec massa. Nam tempor eleifend nulla ac placerat. Mauris faucibus turpis augue, a pulvinar sem sagittis sit amet.',
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right:
                          (MediaQuery.of(context).size.width * 0.75) / 2 - 20,
                      child: Image.asset(
                        'assets/images/user.png',
                        height: 40,
                        width: 40,
                        color: colors.primary,
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Future<void> callApi() async {
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);

    user.setUserId(setting.userId);
    user.setMobile(setting.mobile);
    user.setName(setting.userName);
    user.setEmail(setting.email);
    print("Setting password: ${setting.password}");
    user.setPassword(setting.password);
    user.setProfilePic(setting.profileUrl);

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }

    return;
  }

  Future _getFav() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (CUR_USERID != null) {
          Map parameter = {
            USER_ID: CUR_USERID,
          };

          apiBaseHelper.postAPICall(getFavApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();

              context.read<FavoriteProvider>().setFavlist(tempList);
            } else {
              if (msg != 'No Favourite(s) Product Are Added') {
                setSnackbar(msg!, context);
              }
            }

            context.read<FavoriteProvider>().setLoading(false);
          }, onError: (error) {
            setSnackbar(error.toString(), context);
            context.read<FavoriteProvider>().setLoading(false);
          });
        } else {
          context.read<FavoriteProvider>().setLoading(false);
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const Login()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  /* void getOfferImages() {
    try {
      Map parameter = {};

      apiBaseHelper.postAPICall(getOfferImageApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          offerImages.clear();
          offerImages =
              (data as List).map((data) => Model.fromSlider(data)).toList();
        } else {
          setSnackbar(msg!, context);
        }

        context.read<HomeProvider>().setOfferLoading(false);
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        context.read<HomeProvider>().setOfferLoading(false);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }*/

  void getSection() {
    try {
      Map parameter = {PRODUCT_LIMIT: "6", PRODUCT_OFFSET: "0"};

      if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
      String curPin = context.read<UserProvider>().curPincode;
      if (curPin != '') parameter[ZIPCODE] = curPin;

      apiBaseHelper.postAPICall(getSectionApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        sectionList.clear();
        if (!error) {
          var data = getdata["data"];

          sectionList = (data as List)
              .map((data) => SectionModel.fromJson(data))
              .toList();
        } else {
          if (curPin != '') context.read<UserProvider>().setPincode('');
          setSnackbar(msg!, context);
        }

        context.read<HomeProvider>().setSecLoading(false);
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        context.read<HomeProvider>().setSecLoading(false);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  void getSetting() {
    try {
      CUR_USERID = context.read<SettingProvider>().userId;

      Map parameter = {};
      if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

      apiBaseHelper.postAPICall(getSettingApi, parameter).then((getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"]["system_settings"][0];
          SUPPORTED_LOCALES = data["supported_locals"];
          if (data.toString().contains(MAINTAINANCE_MODE)) {
            Is_APP_IN_MAINTANCE = data[MAINTAINANCE_MODE];
          }
          if (Is_APP_IN_MAINTANCE != "1") {
            getSlider();
            getCat();
            getSection();
            //  getOfferImages();

            proIds = (await db.getMostLike())!;
            getMostLikePro();
            proIds1 = (await db.getMostFav())!;
            getMostFavPro();
          }

          if (data.toString().contains(MAINTAINANCE_MESSAGE)) {
            IS_APP_MAINTENANCE_MESSAGE = data[MAINTAINANCE_MESSAGE];
            print("Is app maintance: $IS_APP_MAINTENANCE_MESSAGE");
          }

          cartBtnList = data["cart_btn_on_list"] == "1" ? true : false;
          refer = data["is_refer_earn_on"] == "1" ? true : false;
          CUR_CURRENCY = data["currency"];
          RETURN_DAYS = data['max_product_return_days'];
          MAX_ITEMS = data["max_items_cart"];
          MIN_AMT = data['min_amount'];
          CUR_DEL_CHR = data['delivery_charge'];
          String? isVerion = data['is_version_system_on'];
          extendImg = data["expand_product_images"] == "1" ? true : false;
          String? del = data["area_wise_delivery_charge"];
          MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];
          IS_LOCAL_PICKUP = data[LOCAL_PICKUP];
          ADMIN_ADDRESS = data[ADDRESS];
          ADMIN_LAT = data[LATITUDE];
          ADMIN_LONG = data[LONGITUDE];
          ADMIN_MOB = data[SUPPORT_NUM];
          // IS_SHIPROCKET_ON=getdata["data"]["shipping_method"][0]["shiprocket_shipping_method"];
          // IS_LOCAL_ON=getdata["data"]["shipping_method"][0]["local_shipping_method"];

          ALLOW_ATT_MEDIA = data[ALLOW_ATTACH];

          if (data.toString().contains(UPLOAD_LIMIT)) {
            UP_MEDIA_LIMIT = data[UPLOAD_LIMIT];
          }

          if (Is_APP_IN_MAINTANCE == "1") {
            appMaintenanceDialog(context);
          }

          if (del == "0") {
            ISFLAT_DEL = true;
          } else {
            ISFLAT_DEL = false;
          }

          if (CUR_USERID != null) {
            REFER_CODE = getdata['data']['user_data'][0]['referral_code'];

            context
                .read<UserProvider>()
                .setPincode(getdata["data"]["user_data"][0][PINCODE]);

            if (REFER_CODE == null || REFER_CODE == '' || REFER_CODE!.isEmpty) {
              generateReferral();
            }

            context.read<UserProvider>().setCartCount(
                getdata["data"]["user_data"][0]["cart_total_items"].toString());
            context
                .read<UserProvider>()
                .setBalance(getdata["data"]["user_data"][0]["balance"]);
            if (Is_APP_IN_MAINTANCE != "1") {
              _getFav();
              _getCart("0");
            }
          } else {
            if (Is_APP_IN_MAINTANCE != "1") {
              _getOffFav();
              _getOffCart();
            }
          }

          Map<String, dynamic> tempData = getdata["data"];
          if (tempData.containsKey(TAG)) {
            tagList = List<String>.from(getdata["data"][TAG]);
          }

          if (isVerion == "1") {
            String? verionAnd = data['current_version'];
            String? verionIOS = data['current_version_ios'];

            PackageInfo packageInfo = await PackageInfo.fromPlatform();

            String version = packageInfo.version;

            final Version currentVersion = Version.parse(version);
            final Version latestVersionAnd = Version.parse(verionAnd!);

            final Version latestVersionIos = Version.parse(verionIOS!);

            if ((Platform.isAndroid && latestVersionAnd > currentVersion) ||
                (Platform.isIOS && latestVersionIos > currentVersion)) {
              updateDailog();
            }
          }
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getMostLikePro() async {
    if (proIds.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        try {
          var parameter = {"product_ids": proIds.join(',')};

          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata["error"];
            if (!error) {
              var data = getdata["data"];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              mostLikeProList.clear();
              mostLikeProList.addAll(tempList);

              context.read<ProductProvider>().setProductList(mostLikeProList);
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomeProvider>().setMostLikeLoading(false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
            context.read<HomeProvider>().setMostLikeLoading(false);
          });
        }
      }
    } else {
      context.read<ProductProvider>().setProductList([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Future<void> getMostFavPro() async {
    if (proIds1.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        try {
          var parameter = {"product_ids": proIds1.join(',')};

          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata["error"];
            if (!error) {
              var data = getdata["data"];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              mostFavProList.clear();
              mostFavProList.addAll(tempList);
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomeProvider>().setMostLikeLoading(false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
            context.read<HomeProvider>().setMostLikeLoading(false);
          });
        }
      }
    } else {
      context.read<CartProvider>().setCartlist([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Future<void> _getOffCart() async {
    if (CUR_USERID == null || CUR_USERID == "") {
      List<String>? proIds = (await db.getCart())!;

      if (proIds.isNotEmpty) {
        _isNetworkAvail = await isNetworkAvailable();

        if (_isNetworkAvail) {
          try {
            var parameter = {"product_variant_ids": proIds.join(',')};
            apiBaseHelper.postAPICall(getProductApi, parameter).then(
                (getdata) async {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              if (!error) {
                var data = getdata["data"];

                List<Product> tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();
                List<SectionModel> cartSecList = [];
                for (int i = 0; i < tempList.length; i++) {
                  for (int j = 0; j < tempList[i].prVarientList!.length; j++) {
                    if (proIds.contains(tempList[i].prVarientList![j].id)) {
                      String qty = (await db.checkCartItemExists(
                          tempList[i].id!, tempList[i].prVarientList![j].id!))!;
                      List<Product>? prList = [];
                      prList.add(tempList[i]);
                      cartSecList.add(SectionModel(
                        id: tempList[i].id,
                        varientId: tempList[i].prVarientList![j].id,
                        qty: qty,
                        productList: prList,
                      ));
                    }
                  }
                }

                context.read<CartProvider>().setCartlist(cartSecList);
              }
              if (mounted) {
                setState(() {
                  context.read<CartProvider>().setProgress(false);
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            context.read<CartProvider>().setProgress(false);
          }
        } else {
          if (mounted) {
            setState(() {
              _isNetworkAvail = false;
              context.read<CartProvider>().setProgress(false);
            });
          }
        }
      } else {
        context.read<CartProvider>().setCartlist([]);
        setState(() {
          context.read<CartProvider>().setProgress(false);
        });
      }
    }
  }

  Future<void> _getOffFav() async {
    if (CUR_USERID == null || CUR_USERID == "") {
      List<String>? proIds = (await db.getFav())!;
      if (proIds.isNotEmpty) {
        _isNetworkAvail = await isNetworkAvailable();

        if (_isNetworkAvail) {
          try {
            var parameter = {"product_ids": proIds.join(',')};
            apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              if (!error) {
                var data = getdata["data"];

                List<Product> tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();

                context.read<FavoriteProvider>().setFavlist(tempList);
              }
              if (mounted) {
                setState(() {
                  context.read<FavoriteProvider>().setLoading(false);
                });
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            context.read<FavoriteProvider>().setLoading(false);
          }
        } else {
          if (mounted) {
            setState(() {
              _isNetworkAvail = false;
              context.read<FavoriteProvider>().setLoading(false);
            });
          }
        }
      } else {
        context.read<FavoriteProvider>().setFavlist([]);
        setState(() {
          context.read<FavoriteProvider>().setLoading(false);
        });
      }
    }
  }

  Future<void> _getCart(String save) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        if (CUR_USERID != null) {
          try {
            var parameter = {
              USER_ID: CUR_USERID,
              SAVE_LATER: save,
              "only_delivery_charge": "0",
            };
            apiBaseHelper.postAPICall(getCartApi, parameter).then((getdata) {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              if (!error) {
                var data = getdata["data"];

                List<SectionModel> cartList = (data as List)
                    .map((data) => SectionModel.fromCart(data))
                    .toList();
                context.read<CartProvider>().setCartlist(cartList);
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          } on TimeoutException catch (_) {}
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<void> generateReferral() async {
    try {
      String refer = getRandomString(8);

      //////

      Map parameter = {
        REFERCODE: refer,
      };

      apiBaseHelper.postAPICall(validateReferalApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          REFER_CODE = refer;

          Map parameter = {
            USER_ID: CUR_USERID,
            REFERCODE: refer,
          };

          apiBaseHelper.postAPICall(getUpdateUserApi, parameter);
        } else {
          if (count < 5) generateReferral();
          count++;
        }

        context.read<HomeProvider>().setSecLoading(false);
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        context.read<HomeProvider>().setSecLoading(false);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  updateDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: Text(getTranslated(context, 'UPDATE_APP')!),
        content: Text(
          getTranslated(context, 'UPDATE_AVAIL')!,
          style: Theme.of(this.context)
              .textTheme
              .subtitle1!
              .copyWith(color: Theme.of(context).colorScheme.fontColor),
        ),
        actions: <Widget>[
          TextButton(
              child: Text(
                getTranslated(context, 'NO')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          TextButton(
              child: Text(
                getTranslated(context, 'YES')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.of(context).pop(false);

                String url = '';
                if (Platform.isAndroid) {
                  url = androidLink + packageName;
                } else if (Platform.isIOS) {
                  url = iosLink;
                }

                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              })
        ],
      );
    }));
  }

  Widget homeShimmer() {
    return SizedBox(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
          children: [
            catLoading(),
            sliderLoading(),
            sectionLoading(),
          ],
        )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget _buildImagePageItem(Model slider) {
    double height = deviceWidth! / 0.5;

    return InkWell(
      child: networkImageCommon(slider.image!, height, false,
          height: height, width: double.maxFinite)
      /* CachedNetworkImage(
          fadeInDuration: const Duration(milliseconds: 150),
          imageUrl: slider.image!,
          height: height,
          width: double.maxFinite,
          fit: BoxFit.fill,
          errorWidget: (context, error, stackTrace) => Image.asset(
                "assets/images/Placeholder_Rectangle.png",
                fit: BoxFit.fill,
                height: height,
                width: deviceWidth! / 2,
              ),
          placeholder: (BuildContext context, url) {
            return Image.asset(
              "${imagePath}Placeholder_Rectangle.png",
            );
          })*/
      ,
      onTap: () async {
        int curSlider = context.read<HomeProvider>().curSlider;

        if (homeSliderList[curSlider].type == "products") {
          Product? item = homeSliderList[curSlider].list;
          currentHero = homeHero;
          Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      secPos: 0,
                      index: 0,
                      list: true,
                      id: item!.id!,
                    )),
          );
        } else if (homeSliderList[curSlider].type == "categories") {
          Product item = homeSliderList[curSlider].list;
          if (item.subList!.isEmpty) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ProductList(
                    name: item.name,
                    id: item.id,
                    tag: false,
                    fromSeller: false,
                  ),
                ));
          } else {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => SubCategory(
                    title: item.name!,
                    subList: item.subList,
                  ),
                ));
          }
        }
      },
    );
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            shape: BoxShape.circle,
                          ),
                          width: 50.0,
                          height: 50.0,
                        ))
                    .toList()),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            context.read<HomeProvider>().setCatLoading(true);
            context.read<HomeProvider>().setSecLoading(true);
            context.read<HomeProvider>().setOfferLoading(true);
            context.read<HomeProvider>().setMostLikeLoading(true);
            context.read<HomeProvider>().setSliderLoading(true);
            _playAnimation();

            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                if (mounted) {
                  setState(() {
                    _isNetworkAvail = true;
                  });
                }
                callApi();
              } else {
                await buttonController.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  _deliverPincode() {
    // String curpin = context.read<UserProvider>().curPincode;
    return InkWell(
      onTap: _pincodeCheck,
      child: Container(
        // padding: EdgeInsets.symmetric(vertical: 8),
        color: Theme.of(context).colorScheme.lightWhite,
        child: ListTile(
          dense: true,
          minLeadingWidth: 10,
          leading: const Icon(
            Icons.location_pin,
          ),
          title: Selector<UserProvider, String>(
            builder: (context, data, child) {
              return Text(
                data == ''
                    ? getTranslated(context, 'SELOC')!
                    : getTranslated(context, 'DELIVERTO')! + data,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.fontColor),
              );
            },
            selector: (_, provider) => provider.curPincode,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right),
        ),
      ),
    );
  }

  _getSearchBar() {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
        child: SizedBox(
          height: 38,
          child: TextField(
            enabled: false,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(15.0, 5.0, 0, 5.0),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                  borderSide: BorderSide(
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                isDense: true,
                hintText: getTranslated(context, 'searchHint'),
                hintStyle: Theme.of(context).textTheme.bodyText2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                    ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    'assets/images/search.svg',
                    color: colors.primary,
                  ),
                ),
                fillColor: Theme.of(context).colorScheme.lightWhite,
                filled: true),
          ),
        ),
      ),
      onTap: () async {
        await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const Search(),
            ));
        if (mounted) setState(() {});
      },
    );
  }

  Future<http.Response> getData() async {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    print("Password: ${userProvider.pass.toString()}");
    return http.post(getUserLoginDetailsApi,
        headers: <String, String>{
          'Content-Type': 'text/plain',
        },
        body:
            '{"distributor_id": "${userProvider.curUserName}", "password": "${userProvider.pass}", "loginuser": "$loginUser", "loginpass": "$loginPass"}');
    // password to be fetched dynamically
  }

  Widget _userDashboard() {
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return FutureBuilder(
      future: getData(),
      builder: (context, snapshot) {
        print(snapshot.toString());
        if (snapshot.hasData) {
          print("DATA: ${snapshot.data!.body}");
          if (snapshot.data!.body.toString()[0] == '<') {
            // print(userProvider.mobile);
            return userProvider.curUserName != '' &&
                    userProvider.mobile.length != 10
                ? Container(
                    child: Center(
                      child: Text(
                        "SunEdge API is not working",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  )
                : Container();
          }
          userLoginData = userLoginDataFromJson(snapshot.data!.body);
          print("DATA: ${userLoginData!.distributorId}");
          return userLoginData != null &&
                  userLoginData!.status == "1" &&
                  userProvider.curUserName != '' &&
                  userLoginData!.distributorId!.length != 10
              ? Container(
                  margin: EdgeInsets.only(bottom: 15),
                  child: Column(
                    children: <Widget>[
                      // SizedBox(
                      //   height: 8,
                      // ),
                      // Divider(
                      //   height: 5,
                      //   color: Colors.grey[300],
                      //   thickness: 8,
                      // ),
                      // SizedBox(
                      //   height: 8,
                      // ),
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/user.png',
                              height: 50,
                              width: 50,
                              color: Colors.grey[500],
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text('${userLoginData!.distributorId}',
                                style: TextStyle(fontSize: 16)),
                            Text(
                              "${userLoginData!.distributorId}",
                              style: TextStyle(fontSize: 11),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Last Month Level',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '${userLoginData!.lastMonthLevel}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                // SizedBox(width: 50),
                                Column(
                                  children: [
                                    Text(
                                      'Next Level',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '${userLoginData!.nextLevel}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'MY PV',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      '${userLoginData!.currentSelfPv}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'GROUP PV',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1b7b41),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      '${userLoginData!.currentGroupPv}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1b7b41),
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(width: 33),
                                // VerticalDivider(),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'MY NETWORK',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow[800],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      '-',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Container(
                                width: MediaQuery.of(context).size.width * 0.75,
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Color.fromARGB(255, 233, 236, 239),
                                ),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'RECOMMENDATION',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(
                                              255, 124, 126, 128),
                                        ),
                                      ),
                                      Text(
                                        ' | ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(
                                              255, 124, 126, 128),
                                        ),
                                      ),
                                      Text(
                                        'REFER A FRIEND',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(
                                              255, 124, 126, 128),
                                        ),
                                      ),
                                    ])),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff58cdb3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 26),
                              ),
                              onPressed: () {},
                              icon: Icon(
                                Icons.repeat_rounded,
                                size: 20,
                              ),
                              label: Text(
                                'REPEAT ORDER',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Divider(
                        height: 5,
                        color: Colors.grey[300],
                        thickness: 8,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Container(
                        height: 75,
                        margin: const EdgeInsets.only(top: 8, left: 10),
                        decoration: BoxDecoration(
                          // borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[200]!,
                              spreadRadius: 1,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 5), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              width: 100,
                              child: Column(
                                children: [
                                  Container(
                                    height: 40,
                                    width: 60,
                                    padding: EdgeInsets.only(top: 12),
                                    child:
                                        Image.asset('assets/images/chart.png'),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'My Group PV',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              width: 100,
                              child: Column(
                                children: [
                                  Container(
                                      height: 40,
                                      width: 60,
                                      padding: EdgeInsets.only(top: 12),
                                      // decoration: BoxDecoration(
                                      //   color: Color.fromARGB(255, 233, 236, 239),
                                      //   borderRadius: BorderRadius.circular(50),
                                      // ),
                                      child: Image.asset(
                                          'assets/images/network.png')),
                                  SizedBox(height: 5),
                                  Text(
                                    'My Network',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              width: 100,
                              child: Column(
                                children: [
                                  Container(
                                      height: 40,
                                      width: 60,
                                      padding: EdgeInsets.only(top: 12),
                                      // decoration: BoxDecoration(
                                      //   color: Color.fromARGB(255, 233, 236, 239),
                                      //   borderRadius: BorderRadius.circular(50),
                                      // ),
                                      child: Image.asset(
                                          'assets/images/voucher.png')),
                                  SizedBox(height: 5),
                                  Text(
                                    'My Voucher',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              width: 100,
                              child: Column(
                                children: [
                                  Container(
                                      height: 40,
                                      width: 60,
                                      padding: EdgeInsets.only(top: 12),
                                      // decoration: BoxDecoration(
                                      //   color: Color.fromARGB(255, 233, 236, 239),
                                      //   borderRadius: BorderRadius.circular(50),
                                      // ),
                                      child: Image.asset(
                                          'assets/images/bonus.png')),
                                  SizedBox(height: 5),
                                  Text(
                                    'My Bonus',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        color: Color.fromARGB(255, 197, 214, 221),
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                  'Only way to do great work is to love what you do',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            SizedBox(height: 8),
                            Stack(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[500],
                                    thickness: 2,
                                    height: 45,
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                                ),
                                Center(
                                  // top: ,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.video_library_rounded,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 197, 214, 221),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      elevation: 0,
                                      side: BorderSide(
                                        color: Colors.grey[500]!,
                                        width: 2,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 26),
                                    ),
                                    label: Text(
                                      'SunEdge Demo',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff6896d4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 50),
                              ),
                              child: Text(
                                'Add New Distributor',
                                // style: TextStyle(
                                //   fontSize: 12,
                                // ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  // child: Center(
                  //   child: CircularProgressIndicator(),
                  // ),
                  // padding: EdgeInsets.symmetric(vertical: 16),
                  );
        }
        return Container(
          child: Center(child: CircularProgressIndicator()),
          padding: EdgeInsets.only(bottom: 8),
        );
      },
    );
    // final queryParameters = {
    //   "distributor_id": "7351279",
    //   "password": "123456",
    //   "loginuser": loginUser,
    //   "loginpass": Uri.decodeComponent(loginPass)
    // };
    // String resBody = "";
    // getData(queryParameters).then((value) async {
    //   print("value: ${value}");
    //   resBody = value.body.toString();
    // });
    // print('${userLoginData!.distributorId}');
    // final headers = {HttpHeaders.contentTypeHeader: 'text/plain'};
    // final value = userLoginDataFromJson(resBody);
    // print("NEXT LEVEL: ${userLoginData!.nextLevel}");
  }

  void _pincodeCheck() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: ListView(shrinkWrap: true, children: [
                Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20, bottom: 40, top: 30),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close),
                                ),
                              ),
                              TextFormField(
                                keyboardType: TextInputType.number,
                                textCapitalization: TextCapitalization.words,
                                validator: (val) => validatePincode(val!,
                                    getTranslated(context, 'PIN_REQUIRED')),
                                onSaved: (String? value) {
                                  context
                                      .read<UserProvider>()
                                      .setPincode(value!);
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.location_on),
                                  hintText:
                                      getTranslated(context, 'PINCODEHINT_LBL'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsetsDirectional.only(
                                          start: 20),
                                      width: deviceWidth! * 0.35,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          context
                                              .read<UserProvider>()
                                              .setPincode('');

                                          context
                                              .read<HomeProvider>()
                                              .setSecLoading(true);
                                          getSection();
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            getTranslated(context, 'All')!),
                                      ),
                                    ),
                                    const Spacer(),
                                    SimBtn(
                                        width: 0.35,
                                        height: 35,
                                        title: getTranslated(context, 'APPLY'),
                                        onBtnSelected: () async {
                                          if (validateAndSave()) {
                                            // validatePin(curPin);
                                            context
                                                .read<HomeProvider>()
                                                .setSecLoading(true);
                                            getSection();

                                            Navigator.pop(context);
                                          }
                                        }),
                                  ],
                                ),
                              ),
                            ],
                          )),
                    ))
              ]),
            );
            //});
          });
        });
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  void getSlider() {
    try {
      Map map = {};

      apiBaseHelper.postAPICall(getSliderApi, map).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          homeSliderList =
              (data as List).map((data) => Model.fromSlider(data)).toList();

          pages = homeSliderList.map((slider) {
            return _buildImagePageItem(slider);
          }).toList();
        } else {
          setSnackbar(msg!, context);
        }

        context.read<HomeProvider>().setSliderLoading(false);
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        context.read<HomeProvider>().setSliderLoading(false);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  void getCat() {
    try {
      Map parameter = {
        CAT_FILTER: "false",
      };
      apiBaseHelper.postAPICall(getCatApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          catList =
              (data as List).map((data) => Product.fromCat(data)).toList();

          if (getdata.containsKey("popular_categories")) {
            var data = getdata["popular_categories"];
            popularList =
                (data as List).map((data) => Product.fromCat(data)).toList();

            if (popularList.isNotEmpty) {
              Product pop =
                  Product.popular("Popular", "${imagePath}popular.svg");
              catList.insert(0, pop);
              context.read<CategoryProvider>().setSubList(popularList);
            }
          }
        } else {
          setSnackbar(msg!, context);
        }

        context.read<HomeProvider>().setCatLoading(false);
      }, onError: (error) {
        setSnackbar(error.toString(), context);
        context.read<HomeProvider>().setCatLoading(false);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 40),
                                decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.white,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20)))),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 5),
                                width: double.infinity,
                                height: 18.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                              GridView.count(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  childAspectRatio: 1.0,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                  children: List.generate(
                                    4,
                                    (index) {
                                      return Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color:
                                            Theme.of(context).colorScheme.white,
                                      );
                                    },
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    sliderLoading()
                    //offerImages.length > index ? _getOfferImage(index) : Container(),
                  ],
                ))
            .toList());
  }
}

void appMaintenanceDialog(BuildContext context) async {
  await dialogAnimate(context,
      StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: Text(
          getTranslated(context, 'APP_MAINTENANCE')!,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
              fontWeight: FontWeight.normal,
              fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: Lottie.asset('assets/animation/maintenance.json'),
            ),
            const SizedBox(
              height: 25,
            ),
            Text(
              IS_APP_MAINTENANCE_MESSAGE != ''
                  ? IS_APP_MAINTENANCE_MESSAGE!
                  : getTranslated(context, 'MAINTENANCE_DEFAULT_MESSAGE')!,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 12),
            )
          ],
        ),
      ),
    );
  }));
}
