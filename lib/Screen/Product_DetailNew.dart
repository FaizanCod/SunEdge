import 'dart:async';
import 'dart:io';

import 'package:collection/src/iterable_extensions.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Screen/Cart.dart';
import 'package:eshop/Screen/FaqsProduct.dart';
import 'package:eshop/Screen/ListItemCompare.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/FavoriteProvider.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:eshop/Provider/ProductDetailProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/ReviewList.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Model/FlashSaleModel.dart';
import '../Provider/FlashSaleProvider.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../ui/widgets/ProductListView.dart';
import '../ui/widgets/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Faqs_Model.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/setTitleWidget.dart';
import 'CompareList.dart';
import 'Favorite.dart';
import 'HomePage.dart';
import 'Login.dart';
import 'MultipleTimer.dart';
import 'Product_Preview.dart';
import 'Review_Gallary.dart';
import 'Review_Preview.dart';
import 'Search.dart';

class ProductDetail extends StatefulWidget {
  // final Product? model;

  final int? secPos, index;
  final bool? list;
  final String id;

  // final FlashSaleModel? pro;
  final int? saleIndex;

  const ProductDetail(
      {Key? key,

/* this.model, */
      this.secPos,
      this.index,
      this.list,
      this.saleIndex,
      required this.id})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateItem();
}

List<User> reviewList = [];
List<imgModel> revImgList = [];
int offset = 0;
int total = 0;

List<FaqsModel> faqsProductList = [];
int faqsOffset = 0;
int faqsTotal = 0;

class StateItem extends State<ProductDetail> with TickerProviderStateMixin {
  int _curSlider = 0;
  final _pageController = PageController();
  final List<int?> _selectedIndex = [];
  ChoiceChip? choiceChip, tagChip;
  int _oldSelVarient = 0;
  bool _isLoading = true;
  bool _isFaqsLoading = true;
  var star1 = "0", star2 = "0", star3 = "0", star4 = "0", star5 = "0";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int notificationoffset = 0;
  late int totalProduct = 0;

  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;
  List<Product> productList = [];
  List<Product> productList1 = [];
  bool seeView = false;

  // var isDarkTheme;
  late ShortDynamicLink shortenedLink;
  String? shareLink;
  late String curPin;
  late double growStepWidth, beginWidth, endWidth = 0.0;
  TextEditingController qtyController = TextEditingController();
  List<String?> sliderList = [];
  int? varSelected;

  List<Product> compareList = [];
  bool isBottom = false;
  var db = DatabaseHelper();
  bool qtyChange = false;
  bool? available, outOfStock;
  int? selectIndex = 0;
  final edtFaqs = TextEditingController();
  final GlobalKey<FormState> faqsKey = GlobalKey<FormState>();
  List<String> proIds1 = [];
  List<Product> mostFavProList = [];

  String deliveryDate = '',
      codDeliveryCharges = '',
      prePaymentDeliveryCharges = '',
      deliveryMsg = '';

  bool isLoadedAll = false;
  late StreamController streamController;

  Future allApiAndFun() async {
    await getProduct1();
    if (mounted) {
      Product model = context.read<ProductDetailProvider>().productData;

      sliderList.clear();
      sliderList.insert(0, model.image);

      addImage().then((value) {
        if (model.videType != "" &&
            model.video!.isNotEmpty &&
            model.video != "") {
          sliderList.insert(1, "youtube");
        }
      });

      revImgList.clear();
      if (model.reviewList!.isNotEmpty)
        for (int i = 0; i < model.reviewList![0].productRating!.length; i++) {
          for (int j = 0;
              j < model.reviewList![0].productRating![i].imgList!.length;
              j++) {
            imgModel m = imgModel.fromJson(
                i, model.reviewList![0].productRating![i].imgList![j]);
            revImgList.add(m);
          }
        }

      getShare();
      _oldSelVarient = model.selVarient!;

      reviewList.clear();
      offset = 0;
      total = 0;
      await getReview();
      await getDeliverable(context.read<ProductDetailProvider>().productData);
      notificationoffset = 0;
      await getProduct();
      faqsProductList.clear();
      faqsOffset = 0;
      faqsTotal = 0;
      await getProductFaqs();
      checkProId();
      await getProFavIds();
      compareList = context.read<ProductDetailProvider>().compareList;
      _selectedIndex.clear();
      if (model.stockType == '0' || model.stockType == '1') {
        if (model.availability == '1') {
          available = true;
          outOfStock = false;
          _oldSelVarient = model.selVarient!;
        } else {
          available = false;
          outOfStock = true;
        }
      } else if (model.stockType == '') {
        available = true;
        outOfStock = false;
        _oldSelVarient = model.selVarient!;
      } else if (model.stockType == '2') {
        if (model.prVarientList![model.selVarient!].availability == '1') {
          available = true;
          outOfStock = false;
          _oldSelVarient = model.selVarient!;
        } else {
          available = false;
          outOfStock = true;
        }
      }

      List<String> selList = model
          .prVarientList![model.selVarient!].attribute_value_ids!
          .split(',');

      for (int i = 0; i < model.attributeList!.length; i++) {
        List<String> sinList = model.attributeList![i].id!.split(',');

        for (int j = 0; j < sinList.length; j++) {
          if (selList.contains(sinList[j])) {
            _selectedIndex.insert(i, j);
          }
        }

        if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
      }

      setState(() {
        isLoadedAll = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    setupChannel();

    getProductDetails();

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
  }

  getProFavIds() async {
    proIds1 = (await db.getMostFav())!;
    getMostFavPro();
  }

  @override
  void dispose() {
    streamController.close();
    buttonController!.dispose();
    edtFaqs.dispose();
    super.dispose();
  }

  checkProId() {
    db.addMostFav(context.read<ProductDetailProvider>().productData.id!);
  }

  Future<void> addImage() async {
    Product model = context.read<ProductDetailProvider>().productData;
    if (model.otherImage != "" && model.otherImage!.isNotEmpty) {
      sliderList.addAll(model.otherImage!);
    }

    for (int i = 0; i < model.prVarientList!.length; i++) {
      for (int j = 0; j < model.prVarientList![i].images!.length; j++) {
        sliderList.add(model.prVarientList![i].images![j]);
      }
    }
  }

  Future<void> createDynamicLink(Product data) async {
    String documentDirectory;

    if (Platform.isIOS) {
      documentDirectory = (await getApplicationDocumentsDirectory()).path;
    } else {
      documentDirectory = (await getExternalStorageDirectory())!.path;
    }

    final response1 = await get(Uri.parse(data.image!));
    final bytes1 = response1.bodyBytes;

    final File imageFile = File('$documentDirectory/temp.png');

    imageFile.writeAsBytesSync(bytes1);
    Share.shareFiles([imageFile.path],
        text: "${data.name}\n${shortenedLink.shortUrl.toString()}\n$shareLink");
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getMostFavPro() async {
    if (proIds1.isNotEmpty) {
      Product model = context.read<ProductDetailProvider>().productData;
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
              var extPro = tempList.firstWhereOrNull((cp) => cp.id == model.id);
              if (extPro == null) {
                mostFavProList.addAll(tempList);
              } else {
                tempList.removeWhere((element) => element.id == model.id);
                mostFavProList.addAll(tempList);
              }
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            if (mounted) setSnackbar(error.toString(), context);
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
            _playAnimation();

            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget));
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  _mostFav() {
    return mostFavProList.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  setHeadTitle("You are looking for", context),
                  Container(
                    height: 230,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: mostFavProList.length,
                      itemBuilder: (context, index) {
                        return productItemView(
                            index, mostFavProList, context, detail1Hero);
                      },
                    ),
                  ),
                ]))
        : SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isBottom
          ? Colors.transparent.withOpacity(0.5)
          : Theme.of(context).canvasColor,
      body: _isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showContent(),
                Selector<CartProvider, bool>(
                  builder: (context, data, child) {
                    return showCircularProgress(data, colors.primary);
                  },
                  selector: (_, provider) => provider.isProgress,
                ),
              ],
            )
          : noInternet(context),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  Widget _slider(Product data) {
    Product model = data;
    double height = MediaQuery.of(context).size.height * .43;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProductPreview(
                pos: _curSlider,
                secPos: widget.secPos,
                index: widget.index,
                id: model.id,
                imgList: sliderList,
                list: widget.list,
                video: model.video,
                videoType: model.videType,
                from: true,
                // screenSize: MediaQuery.of(context).size,
              ),
            ));
      },
      child: Stack(
        children: <Widget>[
          Hero(
              tag: "$currentHero${widget.index}${model.id}${widget.secPos}",
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: sliderList.length,
                  scrollDirection: Axis.horizontal,
                  controller: _pageController,
                  reverse: false,
                  onPageChanged: (index) {
                    setState(() {
                      _curSlider = index;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        sliderList[index] != "youtube"
                            ? networkImageCommon(
                                sliderList[index]!, height, true)

                            /*CachedNetworkImage(
                                imageUrl: sliderList[index]!,
                                placeholder: (BuildContext context, url) {
                                  return Image.asset(
                                    "assets/images/sliderph.png",
                                  );
                                },
                                fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                errorWidget: (context, error, stackTrace) =>
                                    erroWidget(height),
                              )*/
                            : playIcon(data)
                      ],
                    );
                  },
                ),
              )),
          Positioned(
            bottom: 30,
            height: 20,
            width: deviceWidth,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: map<Widget>(
                sliderList,
                (index, url) {
                  return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: _curSlider == index ? 30.0 : 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.primary),
                        borderRadius: BorderRadius.circular(20.0),
                        color: _curSlider == index
                            ? colors.primary
                            : Colors.transparent,
                      ));
                },
              ),
            ),
          ),
          indicatorImage(data),
        ],
      ),
    );
  }

  Widget shareIcn(Product data) {
    return InkWell(
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.share,
              size: 25.0,
              color: colors.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6.0),
                child: Text(
                  getTranslated(context, 'SHARE_APP')!,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                ),
              ),
            )
          ]),
      onTap: () {
        createDynamicLink(data);
      },
    );
  }

  Widget compareIcn(Product data) {
    return InkWell(
        onTap: () {
          if (compareList.isNotEmpty) {
            if (compareList[0].categoryId == data.categoryId) {
              compareSheet(data);
            } else {
              catCompareDailog(data);
            }
          } else {
            compareSheet(data);
          }
        },
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.compare,
                size: 25.0,
                color: colors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6.0),
                  child: Text(
                    getTranslated(context, 'COMPARE_PRO')!,
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]));
  }

  void loadMoreComPro() {
    setState(() {
      context.read<ProductDetailProvider>().setProNotiLoading(true);
      if (context.read<ProductDetailProvider>().offset <
          context.read<ProductDetailProvider>().total) getProduct1();
    });
  }

  void compareSheet(Product data) {
    Product model = data;
    showModalBottomSheet(
        context: context,
        isScrollControlled: false,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
                height: 365,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      height: 300,
                      padding: const EdgeInsetsDirectional.only(
                          top: 20.0, start: 10.0, end: 10.0),
                      child: Selector<ProductDetailProvider, List<Product>>(
                        builder: (context, data, child) {
                          return data.isNotEmpty
                              ? ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: data.length,
                                  itemBuilder: (context, index) {
                                    return ListItemCom(
                                      productList: data[index],
                                      isSelected: (bool value) {
                                        setState(() {
                                          if (value) {
                                            var extPro = compareList
                                                .firstWhereOrNull((cp) =>
                                                    cp.id == data[index].id);
                                            if (extPro == null) {
                                              context
                                                  .read<ProductDetailProvider>()
                                                  .addCompareList(data[index]);
                                            }
                                          } else {
                                            compareList.removeWhere((item) =>
                                                item.id == data[index].id);
                                          }
                                        });
                                      },
                                      key: Key(data[index].id.toString()),
                                      index: index,
                                      len: data.length,
                                      secPos: widget.secPos,
                                    );
                                  },
                                )
                              : shimmerCompare();
                        },
                        selector: (_, productDetailPro) =>
                            productDetailPro.productList,
                      )),
                  Padding(
                      padding: const EdgeInsetsDirectional.only(
                          top: 10.0, bottom: 10.0),
                      child: SimBtn(
                          width: 0.33,
                          height: 35,
                          title: getTranslated(context, 'COMPARE_LBL'),
                          onBtnSelected: () async {
                            var extPro = compareList
                                .firstWhereOrNull((cp) => cp.id == model.id);

                            if (extPro == null) {
                              context
                                  .read<ProductDetailProvider>()
                                  .addComFirstIndex(model);
                            } else {
                              compareList
                                  .removeWhere((item) => item.id == model.id);
                              await context
                                  .read<ProductDetailProvider>()
                                  .addComFirstIndex(model);
                            }

                            setState(() {});
                            if (compareList.length > 1) {
                              await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (BuildContext context) =>
                                          const CompareList()));
                            } else {
                              setSnackbar(
                                  getTranslated(
                                      context, 'PLS_SEL_ONE_MORE_PRO_LBL')!,
                                  context);
                            }
                          }))
                ]));
          });
        });
  }

  catCompareDailog(Product data) async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          content: Text(
            getTranslated(context, 'COMPARETEXTDIG')!,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                  getTranslated(context, 'OPENLIST')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (BuildContext context) =>
                              const CompareList()));
                }),
            TextButton(
                child: Text(
                  getTranslated(context, 'CLEARLIST')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  context.read<ProductDetailProvider>().removeCompareList();
                  Navigator.of(context).pop(false);
                  await getProduct1().whenComplete(() {
                    compareSheet(data);
                  });
                }),
          ],
        );
      });
    }));
  }

  Widget favImg(Product data) {
    Product model = data;
    return Selector<FavoriteProvider, List<String?>>(
      builder: (context, data, child) {
        return InkWell(
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                model.isFavLoading!
                    ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 0.7,
                        ))
                    : Icon(
                        !data.contains(model.id)
                            ? Icons.favorite_border
                            : Icons.favorite,
                        size: 25,
                        color: colors.primary,
                      ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6.0),
                    child: Text(
                      getTranslated(context, 'FAVORITE')!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor),
                    ),
                  ),
                ),
              ]),
          onTap: () {
            if (CUR_USERID != null) {
              !data.contains(model.id)
                  ? _setFav(-1, model)
                  : _removeFav(-1, model);
            } else {
              if (!data.contains(model.id)) {
                model.isFavLoading = true;
                model.isFav = "1";
                context.read<FavoriteProvider>().addFavItem(model);
                db.addAndRemoveFav(model.id!, true);
                model.isFavLoading = false;
              } else {
                model.isFavLoading = true;
                model.isFav = "0";
                context
                    .read<FavoriteProvider>()
                    .removeFavItem(model.prVarientList![0].id!);
                db.addAndRemoveFav(model.id!, false);
                model.isFavLoading = false;
              }
              setState(() {});
            }
          },
        );
      },
      selector: (_, provider) => provider.favIdList,
    );
  }

  indicatorImage(Product data) {
    String? indicator = data.indicator;
    return Positioned.fill(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
          alignment: Alignment.bottomLeft,
          child: indicator == "1"
              ? SvgPicture.asset("assets/images/vag.svg")
              : indicator == "2"
                  ? SvgPicture.asset("assets/images/nonvag.svg")
                  : SizedBox()),
    ));
  }

  _rate(Product data) {
    return data.noOfRating! != "0"
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RatingBarIndicator(
                  rating: double.parse(data.rating!),
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 12.0,
                  direction: Axis.horizontal,
                ),
                Text(
                  " ${data.rating!}",
                  style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                ),
                Text(
                  " | ${data.noOfRating!} ${getTranslated(context, 'RATINGS')}",
                  style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack),
                )
              ],
            ),
          )
        : SizedBox();
  }

  Widget _inclusiveTaxText() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "(${getTranslated(context, 'EXCLU_TAX')})",
        style: Theme.of(context).textTheme.subtitle1!.copyWith(
            color: Theme.of(context).colorScheme.lightBlack2, fontSize: 12),
      ),
    );
  }

  _price(pos, from, Product data) {
    Product model = data;

    double price = double.parse(data.prVarientList![pos].disPrice!);
    if (price == 0) {
      price = double.parse(model.prVarientList![pos].price!);
    }
    return Consumer<FlashSaleProvider>(builder: (context, dataModel, child) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  widget.saleIndex != null
                      ? dataModel.saleList[widget.saleIndex!].status == "1"
                          ? 'DP : ${getPriceFormat(context, double.parse(model.prVarientList![pos].saleFinalPrice!))!}'
                          : '${getPriceFormat(context, price)!} '
                      : model.isSalesOn == "1"
                          ? 'DP : ${getPriceFormat(context, double.parse(model.prVarientList![pos].saleFinalPrice!))!}'
                          : 'DP : ${getPriceFormat(context, price)!} ',
                  style: TextStyle(
                      color: Colors.lightGreen[400],
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              from
                  ? Selector<CartProvider, List<SectionModel>>(
                      builder: (context, data, child) {
                        if (!qtyChange) {
                          SectionModel? tempId = data.firstWhereOrNull((cp) =>
                              cp.id == model.id &&
                              cp.varientId == model.prVarientList![0].id!);
                          if (tempId != null) {
                            qtyController.text = tempId.qty!;
                          } else {
                            String qty = model
                                .prVarientList![model.selVarient!].cartCount!;
                            if (qty == "0") {
                              qtyController.text =
                                  model.minOrderQuntity.toString();
                            } else {
                              qtyController.text = qty;
                            }
                          }
                        }

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 3.0, bottom: 5, top: 3),
                          child: model.availability == "0"
                              ? SizedBox()
                              : Row(
                                  children: <Widget>[
                                    InkWell(
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.remove,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        if (context
                                                    .read<CartProvider>()
                                                    .isProgress ==
                                                false &&
                                            (int.parse(qtyController.text)) >
                                                1) {
                                          addAndRemoveQty(
                                              qtyController.text,
                                              2,
                                              model.itemsCounter!.length *
                                                  int.parse(model.qtyStepSize!),
                                              int.parse(model.qtyStepSize!),
                                              model);
                                        }
                                      },
                                    ),
                                    Container(
                                      width: 37,
                                      height: 20,
                                      color: Colors.transparent,
                                      child: Stack(
                                        children: [
                                          TextField(
                                            textAlign: TextAlign.center,
                                            readOnly: true,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor),
                                            controller: qtyController,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: '',
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              size: 1,
                                            ),
                                            onSelected: (String value) {
                                              if (context
                                                      .read<CartProvider>()
                                                      .isProgress ==
                                                  false) {
                                                addAndRemoveQty(
                                                    value,
                                                    3,
                                                    model.itemsCounter!.length *
                                                        int.parse(
                                                            model.qtyStepSize!),
                                                    int.parse(
                                                        model.qtyStepSize!),
                                                    model);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              return model.itemsCounter!
                                                  .map<PopupMenuItem<String>>(
                                                      (String value) {
                                                return PopupMenuItem(
                                                    value: value,
                                                    child: Text(value,
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor)));
                                              }).toList();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.add,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        if (context
                                                .read<CartProvider>()
                                                .isProgress ==
                                            false) {
                                          addAndRemoveQty(
                                              qtyController.text,
                                              1,
                                              model.itemsCounter!.length *
                                                  int.parse(model.qtyStepSize!),
                                              int.parse(model.qtyStepSize!),
                                              model);
                                        }
                                      },
                                    )
                                  ],
                                ),
                        );
                      },
                      selector: (_, provider) => provider.cartList)
                  : SizedBox(),
            ],
          ));
    });
  }

  removeFromCart(Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (CUR_USERID != null) {
          if (mounted) {
            setState(() {
              context.read<CartProvider>().setProgress(true);
            });
          }

          int qty;

          Product model1 = data;

          qty =
              (int.parse(qtyController.text) - int.parse(model1.qtyStepSize!));

          if (qty < model1.minOrderQuntity!) {
            qty = 0;
          }

          var parameter = {
            PRODUCT_VARIENT_ID: model1.prVarientList![_oldSelVarient].id,
            USER_ID: CUR_USERID,
            QTY: qty.toString()
          };

          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];

              model1.prVarientList![_oldSelVarient].cartCount = qty.toString();
            } else {
              setSnackbar(msg!, context);
            }

            if (mounted) {
              setState(() {
                context.read<CartProvider>().setProgress(false);
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
            setState(() {
              context.read<CartProvider>().setProgress(false);
            });
          });
        } else {
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

  _offPrice(pos, Product data) {
    Product model = data;
    double price = double.parse(model.prVarientList![pos].disPrice!);

    if (price != 0) {
      double off = (double.parse(model.prVarientList![pos].price!) -
              double.parse(model.prVarientList![pos].disPrice!))
          .toDouble();
      off = off * 100 / double.parse(model.prVarientList![pos].price!);

      return Consumer<FlashSaleProvider>(builder: (context, dataModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: <Widget>[
                  Text(
                      'MRP : ${getPriceFormat(context, double.parse(model.prVarientList![pos].price!))!} ',
                      style: TextStyle(
                          color: Colors.lightGreen[400],
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(
                      widget.saleIndex != null
                          ? dataModel.saleList[widget.saleIndex!].status == "1"
/*&& widget.pro!.timeDiff! > 0*/

                              ? "| ${model.saleDis!}% ${getTranslated(context, 'OFF_LBL')}"
                              : "| ${off.toStringAsFixed(2)}% ${getTranslated(context, 'OFF_LBL')}"
                          : model.isSalesOn == "1"
/*&& model.timeDiff! > 0*/

                              ? "| ${model.saleDis!}% ${getTranslated(context, 'OFF_LBL')}"
                              : "| ${off.toStringAsFixed(2)}% ${getTranslated(context, 'OFF_LBL')}",
                      style: Theme.of(context)
                          .textTheme
                          .overline!
                          .copyWith(color: colors.primary, letterSpacing: 0)),
                ],
              ),
              _inclusiveTaxText(),
            ],
          ),
        );
      });
    } else {
      return SizedBox();
    }
  }

  Widget _title(Product data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
        data.name!,
        style: Theme.of(context)
            .textTheme
            .subtitle1!
            .copyWith(color: Theme.of(context).colorScheme.lightBlack),
      ),
    );
  }

  _desc(Product data) {
    return data.desc!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Html(
              data: data.desc,
              onLinkTap: (String? url, RenderContext context,
                  Map<String, String> attributes, dom.Element? element) async {
                if (await canLaunchUrlString(url!)) {
                  await launchUrlString(
                    url,

                    //forceSafariVC: false,
                    // forceWebView: false,
                  );
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          )
        : SizedBox();
  }

  onSelectFun(bool selected, int index, int i, bool available, bool outOfStock,
      int? selectIndex, Product data) async {
    Product model = data;
    if (mounted) {
      setState(() {
        available = false;
        _selectedIndex[index] = selected ? i : null;
        List<int> selectedId = [];
        List<bool> check = [];

        for (int i = 0; i < model.attributeList!.length; i++) {
          List<String> attId = model.attributeList![i].id!.split(',');

          if (_selectedIndex[i] != null) {
            selectedId.add(int.parse(attId[_selectedIndex[i]!]));
          }
        }
        check.clear();
        late List<String> sinId;
        findMatch:
        for (int i = 0; i < model.prVarientList!.length; i++) {
          sinId = model.prVarientList![i].attribute_value_ids!.split(",");

          for (int j = 0; j < selectedId.length; j++) {
            if (sinId.contains(selectedId[j].toString())) {
              check.add(true);

              if (selectedId.length == sinId.length &&
                  check.length == selectedId.length) {
                varSelected = i;
                selectIndex = i;
                break findMatch;
              }
            } else {
              check.clear();
              selectIndex = null;
              break;
            }
          }
        }

        if (selectedId.length == sinId.length &&
            check.length == selectedId.length) {
          if (model.stockType == "0" || model.stockType == "1") {
            if (model.availability == "1") {
              available = true;
              outOfStock = false;
              _oldSelVarient = varSelected!;
            } else {
              available = false;
              outOfStock = true;
              _oldSelVarient = varSelected!;
            }
          } else if (model.stockType == "") {
            available = true;
            outOfStock = false;
            _oldSelVarient = varSelected!;
          } else if (model.stockType == "2") {
            if (model.prVarientList![varSelected!].availability == "1") {
              available = true;
              outOfStock = false;
              _oldSelVarient = varSelected!;
            } else {
              available = false;
              outOfStock = true;
              _oldSelVarient = varSelected!;
            }
          }
        } else {
          available = false;
          outOfStock = false;
        }
        if (model.prVarientList![_oldSelVarient].images!.isNotEmpty) {
          int oldVarTotal = 0;
          if (_oldSelVarient > 0)
            for (int i = 0; i < _oldSelVarient; i++) {
              oldVarTotal =
                  oldVarTotal + model.prVarientList![i].images!.length;
            }
          int p = model.otherImage!.length + 1 + oldVarTotal;

          _pageController.jumpToPage(p);
        }
      });
    }
    model.selVarient = _oldSelVarient;
    if (available) {
      if (CUR_USERID != null) {
        if (model.prVarientList![model.selVarient!].cartCount! != "0") {
          qtyController.text =
              model.prVarientList![model.selVarient!].cartCount!;
          qtyChange = true;
        } else {
          qtyController.text = model.minOrderQuntity.toString();
          qtyChange = true;
        }
      } else {
        String qty = (await db.checkCartItemExists(
            model.id!, model.prVarientList![model.selVarient!].id!))!;
        if (qty == "0") {
          qtyController.text = model.minOrderQuntity.toString();
          qtyChange = true;
        } else {
          model.prVarientList![model.selVarient!].cartCount = qty;
          qtyController.text = qty;
          qtyChange = true;
        }
      }
    }
    setState(() {});
  }

  _getVarient(Product data) {
    Product model = data;
    return MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: Card(
          elevation: 0,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.attributeList!.length,
            itemBuilder: (context, index) {
              List<Widget?> chips = [];
              List<String> att = model.attributeList![index].value!.split(',');
              List<String> attId = model.attributeList![index].id!.split(',');
              List<String> attSType =
                  model.attributeList![index].sType!.split(',');

              List<String> attSValue =
                  model.attributeList![index].sValue!.split(',');

              int? varSelected;

              List<String> wholeAtt = model.attrIds!.split(',');
              for (int i = 0; i < att.length; i++) {
                Widget itemLabel;
                if (attSType[i] == '1') {
                  String clr = (attSValue[i].substring(1));

                  String color = '0xff$clr';

                  itemLabel = Container(
                    width: 25,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Color(int.parse(color))),
                  );
                } else if (attSType[i] == '2') {
                  itemLabel = ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(attSValue[i],
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              erroWidget(80)));
                } else {
                  itemLabel = Text(att[i],
                      style: TextStyle(
                          color: _selectedIndex[index] == (i)
                              ? Theme.of(context).colorScheme.white
                              : Theme.of(context).colorScheme.fontColor));
                }

                if (_selectedIndex[index] != null &&
                    wholeAtt.contains(attId[i])) {
                  choiceChip = ChoiceChip(
                    selected: _selectedIndex.length > index
                        ? _selectedIndex[index] == i
                        : false,
                    label: itemLabel,
                    selectedColor: colors.primary,
                    backgroundColor: Theme.of(context).colorScheme.white,
                    labelPadding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(attSType[i] == '1' ? 100 : 10),
                      side: BorderSide(
                          color: _selectedIndex[index] == (i)
                              ? colors.primary
                              : colors.black12,
                          width: 1.5),
                    ),
                    onSelected: att.length == 1
                        ? null
                        : (bool selected) async {
                            if (selected) {
                              if (mounted) {
                                setState(() {
                                  model.selVarient = _oldSelVarient;

                                  available = false;
                                  _selectedIndex[index] = selected ? i : null;
                                  List<int> selectedId =
                                      []; //list where user choosen item id is stored
                                  List<bool> check = [];
                                  for (int i = 0;
                                      i < model.attributeList!.length;
                                      i++) {
                                    List<String> attId =
                                        model.attributeList![i].id!.split(',');

                                    if (_selectedIndex[i] != null) {
                                      selectedId.add(
                                          int.parse(attId[_selectedIndex[i]!]));
                                    }
                                  }
                                  check.clear();
                                  late List<String> sinId;
                                  findMatch:
                                  for (int i = 0;
                                      i < model.prVarientList!.length;
                                      i++) {
                                    sinId = model
                                        .prVarientList![i].attribute_value_ids!
                                        .split(',');

                                    for (int j = 0;
                                        j < selectedId.length;
                                        j++) {
                                      if (sinId
                                          .contains(selectedId[j].toString())) {
                                        check.add(true);

                                        if (selectedId.length == sinId.length &&
                                            check.length == selectedId.length) {
                                          varSelected = i;
                                          selectIndex = i;
                                          break findMatch;
                                        }
                                      } else {
                                        check.clear();
                                        selectIndex = null;
                                        break;
                                      }
                                    }
                                  }

                                  if (selectedId.length == sinId.length &&
                                      check.length == selectedId.length) {
                                    if (model.stockType == '0' ||
                                        model.stockType == '1') {
                                      if (model.availability == '1') {
                                        available = true;
                                        outOfStock = false;
                                        _oldSelVarient = varSelected!;
                                      } else {
                                        available = false;
                                        outOfStock = true;
                                      }
                                    } else if (model.stockType == '') {
                                      available = true;
                                      outOfStock = false;
                                      _oldSelVarient = varSelected!;
                                    } else if (model.stockType == '2') {
                                      if (model.prVarientList![varSelected!]
                                              .availability ==
                                          '1') {
                                        available = true;
                                        outOfStock = false;
                                        _oldSelVarient = varSelected!;
                                      } else {
                                        available = false;
                                        outOfStock = true;
                                      }
                                    }
                                  } else {
                                    available = false;
                                    outOfStock = false;
                                  }
                                  if (model.prVarientList![_oldSelVarient]
                                      .images!.isNotEmpty) {
                                    int oldVarTotal = 0;
                                    if (_oldSelVarient > 0) {
                                      for (int i = 0; i < _oldSelVarient; i++) {
                                        oldVarTotal = oldVarTotal +
                                            model.prVarientList![i].images!
                                                .length;
                                      }
                                    }
                                    int p = model.otherImage!.length +
                                        1 +
                                        oldVarTotal;

                                    _pageController.jumpToPage(p);
                                  }
                                });
                              } else {}
                            } else {
                              null;
                            }
                            if (available!) {
                              if (CUR_USERID != null) {
                                if (model.prVarientList![_oldSelVarient]
                                        .cartCount! !=
                                    "0") {
                                  qtyController.text = model
                                      .prVarientList![_oldSelVarient]
                                      .cartCount!;
                                  qtyChange = true;
                                } else {
                                  qtyController.text =
                                      model.minOrderQuntity.toString();
                                  qtyChange = true;
                                }
                              } else {
                                String qty = (await db.checkCartItemExists(
                                    model.id!,
                                    model.prVarientList![_oldSelVarient].id!))!;
                                if (qty == "0") {
                                  qtyController.text =
                                      model.minOrderQuntity.toString();
                                  qtyChange = true;
                                } else {
                                  model.prVarientList![_oldSelVarient]
                                      .cartCount = qty;
                                  qtyController.text = qty;
                                  qtyChange = true;
                                }
                              }
                            }
                          },
                  );

                  chips.add(choiceChip);
                }
              }

              String value = _selectedIndex[index] != null &&
                      _selectedIndex[index]! <= att.length
                  ? att[_selectedIndex[index]!]
                  : getTranslated(context, 'VAR_SEL')!
                      .substring(2, getTranslated(context, 'VAR_SEL')!.length);
              return chips.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Text(
                                "${model.attributeList![index].name!} : ",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold),
                              ),
                              Text(
                                value,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                    ),
                              ),
                            ],
                          ),
                          Wrap(
                            children: chips.map<Widget>((Widget? chip) {
                              return Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: chip,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    )
                  : SizedBox();
            },
          ),
        ));
  }

  void _pincodeCheck(Product data) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 30),
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
                                  if (value != null) curPin = value;
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
                                child: SimBtn(
                                    width: 1.0,
                                    height: 35,
                                    title: getTranslated(context, 'APPLY'),
                                    onBtnSelected: () async {
                                      if (validateAndSave()) {
                                        if (IS_SHIPROCKET_ON == "1") {
                                          validatePinFromShipRocket(
                                              curPin, true, data);
                                        } else {
                                          validatePin(curPin, false, data);
                                        }
                                      }
                                    }),
                              ),
                            ],
                          )),
                    ))
              ]),
            );
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

  addAndRemoveQty(
      String qty, int from, int totalLen, int itemCounter, Product data) {
    Product model1 = data;

    if (CUR_USERID != null || CUR_USERID != "") {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          qtyChange = true;
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + (itemCounter)).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model1.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    } else {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + (itemCounter)).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model1.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    }
  }

  Future<void> addToCart(
      String qty, bool intent, bool from, Product product) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        Product model1 = product;
        setState(() {
          qtyChange = true;
        });
        if (CUR_USERID != null) {
          try {
            if (mounted) {
              setState(() {
                context.read<CartProvider>().setProgress(true);
              });
            }

            if (int.parse(qty) < model1.minOrderQuntity!) {
              qty = model1.minOrderQuntity.toString();
              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
            }

            var parameter = {
              USER_ID: CUR_USERID,
              PRODUCT_VARIENT_ID: model1.prVarientList![_oldSelVarient].id,
              QTY: qty,
            };
            apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
              bool error = getdata["error"];
              String? msg = getdata["message"];
              if (!error) {
                var data = getdata["data"];

                model1.prVarientList![_oldSelVarient].cartCount =
                    qty.toString();
                if (from) {
                  context.read<UserProvider>().setCartCount(data['cart_count']);
                  var cart = getdata["cart"];
                  List<SectionModel> cartList = [];
                  cartList = (cart as List)
                      .map((cart) => SectionModel.fromCart(cart))
                      .toList();

                  context.read<CartProvider>().setCartlist(cartList);
                  if (intent) {
                    cartTotalClear();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const Cart(
                          fromBottom: false,
                        ),
                      ),
                    );
                  }
                }
              } else {
                setSnackbar(msg!, context);
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
            if (mounted) {
              setState(() {
                context.read<CartProvider>().setProgress(false);
              });
            }
          }
        } else {
          int cartCount = await db.getTotalCartCount(context);
          if (int.parse(MAX_ITEMS!) > cartCount) {
            List<Product>? prList = [];
            prList.add(model1);
            context.read<CartProvider>().addCartItem(SectionModel(
                  qty: qty,
                  productList: prList,
                  varientId: model1.prVarientList![_oldSelVarient].id!,
                  id: model1.id,
                ));
            db.insertCart(model1.id!, model1.prVarientList![_oldSelVarient].id!,
                qty, context);
            Future.delayed(const Duration(milliseconds: 100)).then((_) async {
              if (from && intent) {
                cartTotalClear();
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const Cart(
                      fromBottom: false,
                    ),
                  ),
                );
              }
            });
          } else {
            setSnackbar(
                "In Cart maximum ${int.parse(MAX_ITEMS!)} product allowed",
                context);
          }
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

  Future<void> getReview() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            PRODUCT_ID: context.read<ProductDetailProvider>().productData.id,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          apiBaseHelper.postAPICall(getRatingApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              total = int.parse(getdata["total"]);

              star1 = getdata["star_1"];
              star2 = getdata["star_2"];
              star3 = getdata["star_3"];
              star4 = getdata["star_4"];
              star5 = getdata["star_5"];
              if ((offset) < total) {
                var data = getdata["data"];
                reviewList =
                    (data as List).map((data) => User.forReview(data)).toList();

                offset = offset + perPage;
              }
            } else {
              if (msg != "No ratings found !") setSnackbar(msg!, context);
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
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

  _setFav(int index, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              index == -1
                  ? data.isFavLoading = true
                  : productList[index].isFavLoading = true;
            });
          }

          var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: data.id};
          apiBaseHelper.postAPICall(setFavoriteApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              index == -1 ? data.isFav = "1" : productList[index].isFav = "1";

              context.read<FavoriteProvider>().addFavItem(data);
            } else {
              setSnackbar(msg!, context);
            }

            if (mounted) {
              setState(() {
                index == -1
                    ? data.isFavLoading = false
                    : productList[index].isFavLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
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

  _removeFav(int index, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(() {
              index == -1
                  ? data.isFavLoading = true
                  : productList[index].isFavLoading = true;
            });
          }

          var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: data.id};
          apiBaseHelper.postAPICall(removeFavApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              index == -1 ? data.isFav = "0" : productList[index].isFav = "0";
              context
                  .read<FavoriteProvider>()
                  .removeFavItem(data.prVarientList![0].id!);
            } else {
              setSnackbar(msg!, context);
            }

            if (mounted) {
              setState(() {
                index == -1
                    ? data.isFavLoading = false
                    : productList[index].isFavLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
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

  _showContent() {
    return Consumer<ProductDetailProvider>(
      builder: (context, product, child) {
        Product data = product.productData;

        return isLoadedAll
            ? Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Expanded(
                    child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: <Widget>[
                      SliverAppBar(
                        expandedHeight:
                            MediaQuery.of(context).size.height * .43,
                        floating: false,
                        pinned: true,
                        backgroundColor: Theme.of(context).colorScheme.white,
                        stretch: true,
                        leading: Builder(builder: (BuildContext context) {
                          return Container(
                            margin: const EdgeInsets.all(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => Navigator.of(context).pop(),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          );
                        }),
                        actions: [
                          IconButton(
                              icon: SvgPicture.asset(
                                "${imagePath}search.svg",
                                height: 20,
                                color: colors.primary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const Search(),
                                    ));
                              }),
                          IconButton(
                              icon: SvgPicture.asset(
                                "${imagePath}desel_fav.svg",
                                height: 20,
                                color: colors.primary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const Favorite(),
                                    ));
                              }),
                          Selector<UserProvider, String>(
                            builder: (context, data, child) {
                              return IconButton(
                                icon: Stack(
                                  children: [
                                    Center(
                                        child: SvgPicture.asset(
                                      "${imagePath}appbarCart.svg",
                                      color: colors.primary,
                                    )),
                                    (data != "" &&
                                            data.isNotEmpty &&
                                            data != "0")
                                        ? Positioned(
                                            bottom: 20,
                                            right: 0,
                                            child: Container(
                                                decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: colors.primary),
                                                child: Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: Text(
                                                      data,
                                                      style: TextStyle(
                                                          fontSize: 7,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .white),
                                                    ),
                                                  ),
                                                )),
                                          )
                                        : SizedBox()
                                  ],
                                ),
                                onPressed: () {
                                  cartTotalClear();
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const Cart(
                                        fromBottom: false,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            selector: (_, homeProvider) =>
                                homeProvider.curCartCount,
                          )
                        ],
                        title: Text(
                          data.name ?? '',
                          maxLines: 1,
                          style: const TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.normal),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: _slider(data),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              showBtn(data),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Container(
                                  //   padding: EdgeInsets.symmetric(
                                  //       horizontal: 15, vertical: 10),
                                  //   margin: EdgeInsets.symmetric(vertical: 10),
                                  //   child: Column(
                                  //     children: [
                                  //       Row(
                                  //         mainAxisAlignment:
                                  //             MainAxisAlignment.spaceBetween,
                                  //         children: [],
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                  Card(
                                    elevation: 0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            top: 10,
                                            bottom: 5,
                                          ),
                                          child: Row(
                                            // mainAxisAlignment:
                                            //     MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  color: Colors.green[400],
                                                ),
                                                child: Text(
                                                  '9.72 PV',
                                                  style: TextStyle(
                                                      color: Color(0xfff0f0f0)),
                                                ),
                                              ),
                                              Icon(
                                                Icons.star,
                                                color: Colors.yellow[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                        _title(data),
                                        // Container(
                                        //   padding: EdgeInsets.symmetric(
                                        //       horizontal: 10),
                                        //   child: Column(
                                        //     crossAxisAlignment:
                                        //         CrossAxisAlignment.start,
                                        //     children: [
                                        //            Text('Item Code: 26014A', style: TextStyle(color: Colors.lightGreen[400])),
                                        //         Text('Net Content: 100 ml x 3', style: TextStyle(color: Colors.lightGreen[400])),
                                        //       Text(
                                        //           'MRP : ₹402.00 (incl. of all taxes)',
                                        //           style: TextStyle(
                                        //               color: Colors
                                        //                   .lightGreen[400])),
                                        //       Text(
                                        //           'DP : ₹350.00 (incl. of all taxes)',
                                        //           style: TextStyle(
                                        //               color: Colors
                                        //                   .lightGreen[400])),
                                        //     ],
                                        //   ),
                                        // ),
                                        _rate(data),
                                        _price(_oldSelVarient, true, data),
                                        _offPrice(_oldSelVarient, data),
                                        _brandName(data),
                                        _shortDesc(data),
                                      ],
                                    ),
                                  ),
                                  _getVarient(data),
                                  _specification(data),
                                  _speciExtraBtnDetails(data),
                                  _flashSaleWidget(data),
                                  _deliverPincode(data),
                                ],
                              ),
                              reviewList.isNotEmpty
                                  ? Card(
                                      elevation: 0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _reviewTitle(data),
                                          _reviewStar(data),
                                          _reviewImg(data),
                                          _review(),
                                        ],
                                      ),
                                    )
                                  : SizedBox(),
                              faqsQuesAndAns(data),
                              productList.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        getTranslated(context, 'MORE_PRODUCT')!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor),
                                      ),
                                    )
                                  : SizedBox(),
                              productList.isNotEmpty
                                  ? Container(
                                      height: 230,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: NotificationListener<
                                              ScrollNotification>(
                                          onNotification:
                                              (ScrollNotification scrollInfo) {
                                            if (scrollInfo.metrics.pixels ==
                                                scrollInfo
                                                    .metrics.maxScrollExtent) {
                                              getProduct();
                                            }
                                            return true;
                                          },
                                          child: ListView.builder(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemCount: (notificationoffset <
                                                    totalProduct)
                                                ? productList.length + 1
                                                : productList.length,
                                            itemBuilder: (context, index) {
                                              return (index ==
                                                          productList.length &&
                                                      !notificationisloadmore)
                                                  ? simmerSingle()
                                                  : productItemView(
                                                      index,
                                                      productList,
                                                      context,
                                                      detailHero);
                                            },
                                          )))
                                  : Container(
                                      height: 0,
                                    ),
                              _mostFav()
                            ],
                          )
                        ]),
                      )
                    ])),
                data.attributeList!.isEmpty
                    ? data.availability != "0"
                        ? Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Theme.of(context).colorScheme.black26,
                                    blurRadius: 10)
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                    child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.white,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      String qty;

                                      qty = qtyController.text;

                                      addToCart(qty, false, true, data);
                                    },
                                    child: Center(
                                        child: Text(
                                      getTranslated(context, 'ADD_CART')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .button!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary),
                                    )),
                                  ),
                                )),
                                Expanded(
                                    child: SimBtn(
                                        width: 0.8,
                                        height: 55,
                                        title: getTranslated(context, 'BUYNOW'),
                                        onBtnSelected: () async {
                                          String qty;

                                          qty = qtyController.text;

                                          addToCart(qty, true, true, data);
                                        })),
                              ],
                            ),
                          )
                        : Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Theme.of(context).colorScheme.black26,
                                    blurRadius: 10)
                              ],
                            ),
                            child: Center(
                                child: Text(
                              getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .button!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                            )),
                          )
                    : available!
                        ? Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Theme.of(context).colorScheme.black26,
                                    blurRadius: 10)
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                    child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.white,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      String qty;

                                      qty = qtyController.text;

                                      addToCart(qty, false, true, data);
                                    },
                                    child: Center(
                                        child: Text(
                                      getTranslated(context, 'ADD_CART')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .button!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary),
                                    )),
                                  ),
                                )),
                                Expanded(
                                    child: SimBtn(
                                        width: 0.8,
                                        height: 55,
                                        title: getTranslated(context, 'BUYNOW'),
                                        onBtnSelected: () async {
                                          String qty;

                                          qty = qtyController.text;

                                          addToCart(qty, true, true, data);
                                        })),
                              ],
                            ),
                          )
                        : available == false || outOfStock == true
                            ? outOfStock == true
                                ? Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .black26,
                                            blurRadius: 10)
                                      ],
                                    ),
                                    child: Center(
                                        child: Text(
                                      getTranslated(
                                          context, 'OUT_OF_STOCK_LBL')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .button!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red),
                                    )),
                                  )
                                : Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .black26,
                                            blurRadius: 10)
                                      ],
                                    ),
                                    child: Center(
                                        child: Text(
                                      getTranslated(
                                          context, 'VAR_NT_AVAIL_LBL')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .button!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red),
                                    )),
                                  )
                            : SizedBox()
              ])
            : detailshimmer();
      },
      /* selector: (_, sale) => sale.productData,*/
    );
  }

  postQues(Product data) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(getTranslated(context, 'HAVE_DOUBTS_REG_THIS_PRO_LBL')!,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.fontColor)),
          Padding(
              padding: EdgeInsetsDirectional.only(top: 10, bottom: 5),
              child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    openPostQueBottomSheet(data);
                  },
                  child: Container(
                      width: double.maxFinite,
                      height: 38.5,
                      alignment: FractionalOffset.center,
                      decoration: BoxDecoration(
                        //color: colors.primary,
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .lightBlack
                                .withOpacity(0.4)),
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                      child: Text(getTranslated(context, 'POST_YR_QUE_LBL')!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold,
                              )))))
        ],
      ),
    );
  }

  void openPostQueBottomSheet(Product data) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return Form(
              key: faqsKey,
              child: Wrap(
                children: [
                  bottomSheetHandle(context),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        topRight: Radius.circular(40.0),
                      ),
                      color: Theme.of(context).colorScheme.white,
                    ),
                    padding: EdgeInsetsDirectional.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.only(top: 30.0, bottom: 20),
                            child: Text(
                              getTranslated(context, 'WRITE_QUE_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(top: 10.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: 20, end: 20),
                                    child: Container(
                                      // padding: EdgeInsetsDirectional.only(start: 10,end: 10),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.25,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightWhite),
                                      child: TextFormField(
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.w400,
                                            fontStyle: FontStyle.normal,
                                            fontSize: 14.0),
                                        onChanged: (value) {},
                                        onSaved: ((String? val) {}),
                                        maxLines: null,
                                        validator: (val) {
                                          if (val!.isEmpty) {
                                            return getTranslated(context,
                                                'PLS_PRO_MORE_DET_LBL');
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          hintText: getTranslated(
                                              context, 'TYPE_YR_QUE_LBL'),
                                          contentPadding:
                                              const EdgeInsetsDirectional.all(
                                                  25.0),
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .lightWhite,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              borderSide: const BorderSide(
                                                  width: 0.0,
                                                  style: BorderStyle.none)),
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        controller: edtFaqs,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.all(20),
                                    child: SimBtn(
                                      title:
                                          getTranslated(context, 'SUBMIT_LBL'),
                                      height: 45,
                                      width: deviceWidth,
                                      onBtnSelected: () {
                                        final form = faqsKey.currentState!;

                                        form.save();
                                        if (form.validate()) {
                                          context
                                              .read<CartProvider>()
                                              .setProgress(true);
                                          setFaqsQue(data);
                                        }
                                      },
                                    ),
                                  )
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  faqsQuesAndAns(Product data) {
    return Card(
      elevation: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _faqsQue(),
          CUR_USERID != "" && CUR_USERID != null ? postQues(data) : SizedBox(),
          if (faqsProductList.isNotEmpty) _allQuesBtn(data)
        ],
      ),
    );
  }

  _allQuesBtn(Product data) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => FaqsProduct(data.id)),
            );
          },
          child: Row(
            children: [
              Text(
                getTranslated(context, 'ALL_QUE_LBL')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Icon(
                Icons.keyboard_arrow_right,
                color:
                    Theme.of(context).colorScheme.lightBlack.withOpacity(0.7),
              )
            ],
          )
/*ListTile(
            dense: true,

            title: Text(
              "All Questions",
              style: TextStyle(color: Theme.of(context).colorScheme.fontColor,fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.keyboard_arrow_right),
          ),*/

          ),
    );
  }

  showBtn(Product data) {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 5.0),
        child: Card(
            elevation: 0,
            child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 5, end: 5, top: 5.0, bottom: 5.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: favImg(data),
                    ),
                    Expanded(
                      flex: 2,
                      child: shareIcn(data),
                    ),
                    Expanded(
                      flex: 3,
                      child: compareIcn(data),
                    ),
                  ],
                ))));
  }

  simmerSingle() {
    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.simmerBase,
          highlightColor: Theme.of(context).colorScheme.simmerHigh,
          child: Container(
            width: deviceWidth! * 0.45,
            height: 250,
            color: Theme.of(context).colorScheme.white,
          ),
        ));
  }

  shimmerCompare() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.gray,
      highlightColor: Theme.of(context).colorScheme.gray,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => Padding(
            padding: const EdgeInsetsDirectional.only(start: 8.0),
            child: Container(
              width: deviceWidth! * 0.45,
              height: 255,
              color: Theme.of(context).colorScheme.white,
            )),
        itemCount: 10,
      ),
    );
  }

  _madeIn(Product data) {
    String? madeIn = data.madein;

    return madeIn != "" && madeIn!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(madeIn),
              dense: true,
              title: Text(
                getTranslated(context, 'MADE_IN')!,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : SizedBox();
  }

/* Widget productItem(int index, int from) {
    if (index < productList.length) {
      String? offPer;
      double price =
          double.parse(productList[index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(productList[index].prVarientList![0].price!);
      } else {
        double off =
            double.parse(productList[index].prVarientList![0].price!) - price;
        offPer = ((off * 100) /
                double.parse(productList[index].prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.45;

      return SizedBox(
          height: 255,
          width: width,
          child: Card(
            elevation: 0.2,
            margin: const EdgeInsetsDirectional.only(bottom: 5, end: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  from == 1
                      ? Container(
                          alignment: Alignment.topRight,
                          padding: const EdgeInsetsDirectional.only(
                              end: 5.0, top: 5.0),
                          child: const Icon(
                            Icons.circle,
                            size: 30,
                          ))
                      : SizedBox(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                            padding: const EdgeInsetsDirectional.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5)),
                              child: Hero(
                                tag: "$index${productList[index].id}",
                                child: FadeInImage(
                                  image:
                                      CachedNetworkImageProvider(productList[index].image!),
                                  height: double.maxFinite,
                                  width: double.maxFinite,
                                  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          erroWidget(
                                    double.maxFinite,
                                  ),
                                  placeholder: (context,url) {return placeHolder(
                                    double.maxFinite,
                                  ),
                                ),
                              ),
                            )),
                        offPer != null
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: colors.red,
                                      borderRadius: BorderRadius.circular(10)),
                                  margin: const EdgeInsets.all(5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "$offPer%",
                                      style: const TextStyle(
                                          color: colors.whiteTemp,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(),
                        const Divider(
                          height: 1,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 5.0,
                      top: 5,
                    ),
                    child: Row(
                      children: [
                        RatingBarIndicator(
                          rating: double.parse(productList[index].rating!),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star_rate_rounded,
                            color: Colors.amber,
                          ),
                          unratedColor: Colors.grey.withOpacity(0.5),
                          itemCount: 5,
                          itemSize: 12.0,
                          direction: Axis.horizontal,
                          itemPadding: const EdgeInsets.all(0),
                        ),
                        Text(
                          " (${productList[index].noOfRating!})",
                          style: Theme.of(context).textTheme.overline,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 5.0, top: 5, bottom: 5),
                    child: Text(
                      productList[index].name!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text('${getPriceFormat(context, price)!} ',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold)),
                      Text(
                        double.parse(productList[index]
                                    .prVarientList![0]
                                    .disPrice!) !=
                                0
                            ? getPriceFormat(
                                context,
                                double.parse(productList[index]
                                    .prVarientList![0]
                                    .price!))!
                            : "",
                        style: Theme.of(context).textTheme.overline!.copyWith(
                            decoration: TextDecoration.lineThrough,
                            letterSpacing: 0),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                Product model = productList[index];
                notificationoffset = 0;
                Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductDetail(
                          model: model,
                          secPos: widget.secPos,
                          index: index,
                          list: true)),
                );
              },
            ),
          ));
    } else {
      return SizedBox();
    }
  }*/

  Widget _faqsQue() {
    return _isFaqsLoading
        ? const Center(child: CircularProgressIndicator())
        : faqsProductList.isNotEmpty
            ? Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 20, end: 20, top: 12, bottom: 10),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getTranslated(context, 'QUE_ANS_LBL')!,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold)),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(

/* horizontal: 20,*/

                                vertical: 5),
                            itemCount: faqsProductList.length >= 5
                                ? 5
                                : faqsProductList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(),
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${getTranslated(context, 'Q_LBL')}: ${faqsProductList[index].question!}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontSize: 12.5),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "${getTranslated(context, 'A_LBL')}: ${faqsProductList[index].answer!}",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack,
                                            fontSize: 11),
                                      )),
                                  Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      faqsProductList[index].uname!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack2,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 3.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack
                                              .withOpacity(0.8),
                                        ),
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              start: 3.0),
                                          child: Text(
                                            faqsProductList[index].ansBy!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack
                                                    .withOpacity(0.5),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }),
                      )
                    ]),
              )
            : const SizedBox();
  }

  Widget _review() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            itemCount: reviewList.length >= 2 ? 2 : reviewList.length,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (context, index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reviewList[index].username!,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                      const Spacer(),
                      Text(
                        reviewList[index].date!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontSize: 11),
                      )
                    ],
                  ),
                  RatingBarIndicator(
                    rating: double.parse(reviewList[index].rating!),
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: colors.primary,
                    ),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                  ),
                  reviewList[index].comment != "" &&
                          reviewList[index].comment!.isNotEmpty
                      ? Text(
                          reviewList[index].comment ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : SizedBox(),
                  reviewImage(index),
                ],
              );
            });
  }

  Future<void> getProductFaqs() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            PRODUCT_ID: context.read<ProductDetailProvider>().productData.id,
            LIMIT: perPage.toString(),
            OFFSET: faqsOffset.toString(),
          };

          apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
              (getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              faqsTotal = int.parse(getdata["total"]);

              if ((faqsOffset) < faqsTotal) {
                var data = getdata["data"];
                faqsProductList = (data as List)
                    .map((data) => FaqsModel.fromJson(data))
                    .toList();

                faqsOffset = faqsOffset + perPage;
              }
            } else {
              if (msg == "FAQs does not exist") {
                //setSnackbar(msg!, context);
              }
            }
            if (mounted) {
              setState(() {
                _isFaqsLoading = false;
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              _isFaqsLoading = false;
            });
          }
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

/* Future getProductFaqs() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (faqsIsLoadMore) {
            if (mounted) {
              setState(() {
                faqsIsLoadMore = false;
                faqsIsGettingData = true;
                if (faqsOffset == 0) {
                  faqsProductList = [];
                }
              });
            }

            var parameter = {
              PRODUCT_ID: model.id,
              LIMIT: perPage.toString(),
              OFFSET: faqsOffset.toString(),
            };

            if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

            apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
                (getdata) {
              bool error = getdata["error"];

              faqsIsGettingData = false;
              if (faqsOffset == 0) faqsIsNoData = error;

              if (!error) {
                totalFaqs = int.parse(getdata["total"]);
                if (mounted) {
                  Future.delayed(
                      Duration.zero,
                      () => setState(() {
                            List mainlist = getdata['data'];

                            if (mainlist.isNotEmpty) {
                              List<FaqsModel> items = [];
                              List<FaqsModel> allitems = [];

                              items.addAll(mainlist
                                  .map((data) => FaqsModel.fromJson(data))
                                  .toList());

                              allitems.addAll(items);
                              for (FaqsModel item in items) {
                                faqsProductList
                                    .where((i) => i.id == item.id)
                                    .map((obj) {
                                  allitems.remove(item);
                                  return obj;
                                }).toList();
                              }
                              faqsProductList.addAll(allitems);
                              faqsIsLoadMore = true;

                              faqsOffset = faqsOffset + perPage;
                            } else {
                              faqsIsLoadMore = false;
                            }
                          }));
                }
              } else {
                faqsIsLoadMore = false;
                if (mounted) if (mounted) setState(() {});
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              faqsIsLoadMore = false;
            });
          }
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
  }*/

  Future getProduct() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (notificationisloadmore) {
            if (mounted) {
              setState(() {
                notificationisloadmore = false;
                notificationisgettingdata = true;
                if (notificationoffset == 0) {
                  productList = [];
                }
              });
            }

            var parameter = {
              CATID:
                  context.read<ProductDetailProvider>().productData.categoryId,
              LIMIT: perPage.toString(),
              OFFSET: notificationoffset.toString(),
              ID: context.read<ProductDetailProvider>().productData.id,
              IS_SIMILAR: "1"
            };

            if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

            apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
              bool error = getdata["error"];

              notificationisgettingdata = false;
              if (notificationoffset == 0) notificationisnodata = error;

              if (!error) {
                totalProduct = int.parse(getdata["total"]);
                if (mounted) {
                  Future.delayed(
                      Duration.zero,
                      () => setState(() {
                            List mainlist = getdata['data'];

                            if (mainlist.isNotEmpty) {
                              List<Product> items = [];
                              List<Product> allitems = [];

                              items.addAll(mainlist
                                  .map((data) => Product.fromJson(data))
                                  .toList());

                              allitems.addAll(items);
                              for (Product item in items) {
                                productList
                                    .where((i) => i.id == item.id)
                                    .map((obj) {
                                  allitems.remove(item);
                                  return obj;
                                }).toList();
                              }
                              productList.addAll(allitems);
                              notificationisloadmore = true;

                              notificationoffset = notificationoffset + perPage;
                            } else {
                              notificationisloadmore = false;
                            }
                          }));
                }
              } else {
                notificationisloadmore = false;
                if (mounted) if (mounted) setState(() {});
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              notificationisloadmore = false;
            });
          }
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

  Future<void> getProductDetails() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          "product_ids": widget.id,
        };

        if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;

        apiBaseHelper.postAPICall(getProductApi, parameter).then(
            (getdata) async {
          bool error = getdata["error"];

          if (!error) {
            List mainlist = getdata['data'];

            if (mainlist.isNotEmpty) {
              List<Product> items = [];

              items.addAll(
                  mainlist.map((data) => Product.fromJson(data)).toList());
              context.read<ProductDetailProvider>().setProductData(items[0]);
              /*context
                  .read<ProductDetailProvider>()
                  .setDiffTime(isSaleOn: items[0].isSalesOn!,);*/

              await allApiAndFun();
            }
          } else {
            if (mounted) {
              setState(() {
                context.read<ProductDetailProvider>().setProNotiLoading(false);
              });
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            context.read<ProductDetailProvider>().setProNotiLoading(false);
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> getProduct1() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          CATID: context.read<ProductDetailProvider>().productData.categoryId,
          ID: context.read<ProductDetailProvider>().productData.id,
          IS_SIMILAR: "1"
        };

        if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

        apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
          bool error = getdata["error"];

          if (!error) {
            context
                .read<ProductDetailProvider>()
                .setProTotal(int.parse(getdata["total"]));

            List mainlist = getdata['data'];

            if (mainlist.isNotEmpty) {
              List<Product> items = [];
              List<Product> allitems = [];
              productList1 = [];

              items.addAll(
                  mainlist.map((data) => Product.fromJson(data)).toList());

              allitems.addAll(items);

              for (Product item in items) {
                productList1.where((i) => i.id == item.id).map((obj) {
                  allitems.remove(item);
                  return obj;
                }).toList();
              }
              productList1.addAll(allitems);

              context
                  .read<ProductDetailProvider>()
                  .setProductList(productList1);

              context.read<ProductDetailProvider>().setProOffset(
                  context.read<ProductDetailProvider>().offset + perPage);
            }
          } else {
            if (mounted) {
              setState(() {
                context.read<ProductDetailProvider>().setProNotiLoading(false);
              });
            }
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(() {
            context.read<ProductDetailProvider>().setProNotiLoading(false);
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _specification(Product data) {
    Product model = data;
    return model.desc!.isNotEmpty ||
            model.attributeList!.isNotEmpty ||
            model.madein != "" && model.madein!.isNotEmpty
        ? Card(
            elevation: 0,
            child: InkWell(
              child: Column(children: [
                ListTile(
                  dense: true,
                  title: Text(
                    getTranslated(context, 'SPECIFICATION')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack),
                  ),
                  trailing: InkWell(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        !seeView ? Icons.add : Icons.remove,
                        size: 10,
                        color: colors.primary,
                      ),
                      Padding(
                          padding: const EdgeInsetsDirectional.only(start: 2.0),
                          child: Text(
                              !seeView
                                  ? getTranslated(context, 'MORE_LBL')!
                                  : getTranslated(context, 'LESS_LBL')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .copyWith(color: colors.primary)))
                    ]),
                    onTap: () {
                      setState(() {
                        seeView = !seeView;
                      });
                    },
                  ),
                ),
                !seeView
                    ? SizedBox(
                        height: 70,
                        width: deviceWidth! - 10,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _desc(data),
                                model.desc!.isNotEmpty
                                    ? const Divider(
                                        height: 3.0,
                                      )
                                    : SizedBox(),
                                _attr(data),
                                model.madein != "" && model.madein!.isNotEmpty
                                    ? const Divider()
                                    : SizedBox(),
                                _madeIn(data),
                              ]),
                        ))
                    : Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _desc(data),
                              model.desc!.isNotEmpty
                                  ? const Divider(
                                      height: 3.0,
                                    )
                                  : SizedBox(),
                              _attr(data),
                              model.madein != "" && model.madein!.isNotEmpty
                                  ? const Divider()
                                  : SizedBox(),
                              _madeIn(data),
                            ]),
                      )
              ]),
            ),
          )
        : SizedBox();
  }

  void setupChannel() {
    streamController = StreamController<int>.broadcast();
  }

  _flashSaleWidget(Product data) {
    Product model = data;

    return widget.saleIndex != null
        ? Consumer<FlashSaleProvider>(builder: (context, dataModel, child) {
            return dataModel.saleList[widget.saleIndex!].status == "1" ||
                    dataModel.saleList[widget.saleIndex!].status == "2"
                ? MultipleTimer(
                    startDateModel:
                        dataModel.saleList[widget.saleIndex!].startDate!,
                    endDateModel:
                        dataModel.saleList[widget.saleIndex!].endDate!,
                    serverDateModel:
                        dataModel.saleList[widget.saleIndex!].serverTime!,
                    id: dataModel.saleList[widget.saleIndex!].id!,
                    newtimeDiff:
                        dataModel.saleList[widget.saleIndex!].timeDiff!,
                    from: 2,
                  )
                : SizedBox();
          })
        : model.isSalesOn == "1" || model.isSalesOn == "2"
            ? MultipleTimer(
                startDateModel: model.saleStartDate!,
                endDateModel: model.saleEndDate!,
                serverDateModel: model.serverTime!,
                id: "0",
                newtimeDiff: model.timeDiff!,
                from: 2,
                inDetails: true,
              )
            : SizedBox();
  }

  _deliverPincode(Product data) {
    String pin = context.read<UserProvider>().curPincode;
    return Card(
      elevation: 0,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _pincodeCheck(data);
            },
            child: ListTile(
              dense: true,
              title: Text(
                pin == ''
                    ? getTranslated(context, 'SELOC')!
                    : getTranslated(context, 'DELIVERTO')! + pin,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.lightBlack),
              ),
              trailing: const Icon(Icons.keyboard_arrow_right),
            ),
          ),
          if (deliveryDate == '')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Text(deliveryMsg,
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (deliveryDate != '') Divider(),
          if (deliveryDate != '')
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              child: Row(
                children: [
                  Text("${getTranslated(context, 'DELIVERY_DAY_LBL')}: ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                      )),
                  Text(
                    deliveryDate,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  )
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: Row(
              children: [
                if (codDeliveryCharges != '')
                  Row(
                    children: [
                      Text("${getTranslated(context, 'COD_CHARGE_LBL')}: ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                          )),
                      Text(
                          "${getPriceFormat(context, double.parse(codDeliveryCharges))}"),
                      SizedBox(width: 25),
                    ],
                  ),
                if (prePaymentDeliveryCharges != '')
                  Row(
                    children: [
                      Text('${getTranslated(context, 'ONLINE_PAY_LBL')}: ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.lightBlack2,
                          )),
                      Text(
                          '${getPriceFormat(context, double.parse(prePaymentDeliveryCharges))}'),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  _speciExtraBtnDetails(Product data) {
    Product model = data;
    String? cod = model.codAllowed;
    if (cod == "1") {
      cod = "Cash On Delivery";
    } else {
      cod = "No-Cash On Delivery";
    }

    String? cancleable = model.isCancelable;
    if (cancleable == "1") {
      cancleable = "Cancellable Till ${model.cancleTill!}";
    } else {
      cancleable = "No Cancellable";
    }

    String? returnable = model.isReturnable;
    if (returnable == "1") {
      returnable = "${RETURN_DAYS!} Days Returnable";
    } else {
      returnable = "No Returnable";
    }

    String? gaurantee = model.gurantee;
    String? warranty = model.warranty;

    return Card(
        elevation: 0,
        child: Container(
            height: 100,
            padding: const EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
            width: deviceWidth,
            child: Row(
              children: [
                model.codAllowed == "1"
                    ? Expanded(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(bottom: 5.0),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  'assets/images/cod.svg',
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                )),
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: 72,
                            child: Text(
                              cod,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ))
                    : Container(
                        width: 0,
                      ),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 7.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  model.isCancelable == "1"
                                      ? "assets/images/cancelable.svg"
                                      : "assets/images/notcancelable.svg",
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 72,
                              child: Text(
                                cancleable,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 7.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: SvgPicture.asset(
                                  model.isReturnable == "1"
                                      ? "assets/images/returnable.svg"
                                      : "assets/images/notreturnable.svg",
                                  height: 45.0,
                                  width: 45.0,
                                  fit: BoxFit.cover,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 72,
                              child: Text(
                                returnable,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ))),
                gaurantee != "" && gaurantee!.isNotEmpty
                    ? Expanded(
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 7.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 5.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: SvgPicture.asset(
                                      "assets/images/guarantee.svg",
                                      height: 45.0,
                                      width: 45.0,
                                      fit: BoxFit.cover,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 72,
                                  child: Text(
                                    "$gaurantee ${getTranslated(context, 'GUARANTY_LBL')}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            )))
                    : Container(
                        width: 0,
                      ),
                warranty != "" && warranty!.isNotEmpty
                    ? Expanded(
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 7.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      bottom: 5.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: SvgPicture.asset(
                                      "assets/images/warranty.svg",
                                      height: 45.0,
                                      width: 45.0,
                                      fit: BoxFit.cover,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 72,
                                  child: Text(
                                    "$warranty ${getTranslated(context, 'WARRENTY')}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            )))
                    : Container(
                        width: 0,
                      )
              ],
            )));
  }

  _reviewTitle(Product data) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children: [
            Text(
              getTranslated(context, 'CUSTOMER_REVIEW_LBL')!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  getTranslated(context, 'VIEW_ALL')!,
                  style: const TextStyle(color: colors.primary),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => ReviewList(data.id, data)),
                );
              },
            )
          ],
        ));
  }

  reviewImage(int i) {
    return SizedBox(
      height: reviewList[i].imgList!.isNotEmpty ? 50 : 0,
      child: ListView.builder(
        itemCount: reviewList[i].imgList!.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 10, bottom: 5.0, top: 5),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: widget.secPos,
                        index: widget.index,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                        // screenSize: MediaQuery.of(context).size,
                      ),
                    ));
              },
              child: Hero(
                tag: "$index${reviewList[i].id}${widget.secPos}",
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: networkImageCommon(
                        reviewList[i].imgList![index], 50, false,
                        height: 50, width: 50)
                    /*CachedNetworkImage(
                    imageUrl: reviewList[i].imgList![index],
                    height: 50.0,
                    width: 50.0,
                    placeholder: (context, url) {
                      return placeHolder(50);
                    },
                    errorWidget: (context, error, stackTrace) => erroWidget(50),
                  ),*/
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  _shortDesc(Product data) {
    Product model = data;
    return model.shortDescription != "" && model.shortDescription!.isNotEmpty
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5),
            child: Text(
              model.shortDescription!,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          )
        : SizedBox();
  }

  _brandName(Product data) {
    Product model = data;
    return model.brand != ""
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 8, end: 8, top: 8, bottom: 5),
            child: Row(
              children: [
                Text(
                  "${getTranslated(context, 'BRAND_LBL')!} : ",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  model.brand!,
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ],
            ),
          )
        : SizedBox();
  }

  _attr(Product data) {
    Product model = data;
    return model.attributeList!.isNotEmpty
        ? ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.attributeList!.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 25.0,
                    top: 10.0,
                    bottom: model.madein != "" && model.madein!.isNotEmpty
                        ? 0.0
                        : 7.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        model.attributeList![i].name!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7)),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 5.0),
                            child: Text(
                              model.attributeList![i].value!,
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            ))),
                  ],
                ),
              );
            },
          )
        : SizedBox();
  }

  Future<void> getShare() async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: deepLinkUrlPrefix,
      link: Uri.parse(
          'https://$deepLinkName/?index=${widget.index}&secPos=${widget.secPos}&list=${widget.list}&id=${context.read<ProductDetailProvider>().productData.id}'),
      androidParameters: const AndroidParameters(
        packageName: packageName,
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: iosPackage,
        minimumVersion: '1',
        appStoreId: appStoreId,
      ),
    );

    shortenedLink =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);

    Future.delayed(Duration.zero, () {
      shareLink =
          "\n$appName\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n${getTranslated(context, 'IOSLBL')}\n$iosLink";
    });
  }

  playIcon(Product data) {
    Product model = data;
    return Align(
        alignment: Alignment.center,
        child: (model.videType != "" &&
                model.video!.isNotEmpty &&
                model.video != "")
            ? const Icon(
                Icons.play_circle_fill_outlined,
                color: colors.primary,
                size: 35,
              )
            : SizedBox());
  }

  _reviewImg(Product data) {
    Product model = data;
    return revImgList.isNotEmpty
        ? SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: revImgList.length > 5 ? 5 : revImgList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: InkWell(
                    onTap: () async {
                      if (index == 4) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) =>
                                    ReviewGallary(productModel: model)));
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      productModel: model,
                                    )));
                      }
                    },
                    child: Stack(
                      children: [
                        networkImageCommon(revImgList[index].img!, 80, false,
                            height: 100, width: 80),

                        /*CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          imageUrl: revImgList[index].img!,
                          height: 100.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                          placeholder: (context, url) {
                            return placeHolder(80);
                          },
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(80),
                        ),*/
                        index == 4
                            ? Container(
                                height: 100.0,
                                width: 80.0,
                                color: colors.black54,
                                child: Center(
                                    child: Text(
                                  "+${revImgList.length - 5}",
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold),
                                )),
                              )
                            : SizedBox()
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : SizedBox();
  }

  Future<void> validatePinFromShipRocket(
      String pin, bool wantsToPop, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);
          var parameter = {
            DEL_PINCODE: pin,
            PRODUCT_VARIENT_ID: data.prVarientList![_oldSelVarient].id,
          };
          apiBaseHelper
              .postAPICall(checkShipRocketChargesOnProduct, parameter)
              .then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];

            if (error) {
              context.read<UserProvider>().setPincode(pin);
              curPin = '';

              deliveryDate = '';
              codDeliveryCharges = '';
              prePaymentDeliveryCharges = '';
              setSnackbar(msg!, context);
            } else {
              if (getdata['data'] != null) {
                //
                deliveryMsg = msg!;

                deliveryDate = getdata['data']['estimate_date'] ?? '';
                codDeliveryCharges =
                    getdata['data']['delivery_charge_with_cod'].toString();
                prePaymentDeliveryCharges =
                    getdata['data']['delivery_charge_without_cod'].toString();
                //

              } else {
                deliveryDate = '';
                codDeliveryCharges = '';
                prePaymentDeliveryCharges = '';
                deliveryMsg = msg!;
              }
              context.read<UserProvider>().setPincode(pin);
              setSnackbar(msg, context);
              setState(() {});
            }
            context.read<CartProvider>().setProgress(false);
            if (wantsToPop) {
              Navigator.pop(context);
            }

            //setSnackbar(msg!, context);
          }, onError: (error) {
            context.read<CartProvider>().setProgress(false);
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          context.read<CartProvider>().setProgress(false);
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
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

  Future<void> validatePin(String pin, bool first, Product data) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            ZIPCODE: pin,
            PRODUCT_ID: data.id,
          };
          apiBaseHelper.postAPICall(checkDeliverableApi, parameter).then(
              (getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];

            if (error) {
              curPin = '';
            } else {
              if (pin != context.read<UserProvider>().curPincode) {
                context.read<HomeProvider>().setSecLoading(true);
                getSection();
              }
              deliveryMsg = msg!;
              context.read<UserProvider>().setPincode(pin);
            }
            if (!first) {
              Navigator.pop(context);
              setSnackbar(msg!, context);
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
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
          setSnackbar(
            msg!,
            context,
          );
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

  Future<void> getDeliverable(Product data) async {
    String pin = context.read<UserProvider>().curPincode;
    if (pin != '') {
      if (IS_SHIPROCKET_ON == "1") {
        validatePinFromShipRocket(pin, false, data);
      } else {
        validatePin(pin, true, data);
      }
    }
  }

  _reviewStar(Product data) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                data.rating ?? "",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              Text(
                  "${reviewList.length}  ${getTranslated(context, "RATINGS")!}")
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                getRatingBarIndicator(5.0, 5),
                getRatingBarIndicator(4.0, 4),
                getRatingBarIndicator(3.0, 3),
                getRatingBarIndicator(2.0, 2),
                getRatingBarIndicator(1.0, 1),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getRatingIndicator(int.parse(star5)),
                getRatingIndicator(int.parse(star4)),
                getRatingIndicator(int.parse(star3)),
                getRatingIndicator(int.parse(star2)),
                getRatingIndicator(int.parse(star1)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getTotalStarRating(star5),
              getTotalStarRating(star4),
              getTotalStarRating(star3),
              getTotalStarRating(star2),
              getTotalStarRating(star1),
            ],
          ),
        ),
      ],
    );
  }

  getRatingIndicator(var totalStar) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Stack(
        children: [
          Container(
            height: 10,
            width: MediaQuery.of(context).size.width / 3,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3.0),
                border: Border.all(
                  width: 0.5,
                  color: colors.primary,
                )),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: colors.primary,
            ),
            width: (totalStar / reviewList.length) *
                MediaQuery.of(context).size.width /
                3,
            height: 10,
          ),
        ],
      ),
    );
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        textDirection: TextDirection.rtl,
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_rate_rounded,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }

  getTotalStarRating(var totalStar) {
    return SizedBox(
        width: 20,
        height: 20,
        child: Text(
          totalStar,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ));
  }

  Widget detailshimmer() {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * .47,
                width: double.infinity,
                color: Theme.of(context).colorScheme.white,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 35,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.white,
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 9.0),
                  child: simmerSingle()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setFaqsQue(Product data) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_ID: data.id,
          QUESTION: edtFaqs.text.trim()
        };
        apiBaseHelper.postAPICall(setProductFaqsApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setSnackbar(msg!, context);
            edtFaqs.clear();
            Navigator.pop(context);
          } else {
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  final Animation<double> animation;

  const AnimatedProgressBar({Key? key, required this.animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5.0,
      width: animation.value,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.black),
    );
  }
}
