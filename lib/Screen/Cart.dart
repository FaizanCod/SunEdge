import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/SqliteData.dart';

import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/PromoCode.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:paytm/paytm.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../Helper/ApiBaseHelper.dart';
import '../ui/widgets/AppBtn.dart';
import '../Helper/Color.dart';
import '../ui/widgets/SimBtn.dart';
import '../Helper/String.dart';
import '../ui/widgets/Stripe_Service.dart';
import '../Model/Model.dart';
import '../Model/Section_Model.dart';
import '../Model/User.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/DiscountLabel.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'Add_Address.dart';
import 'HomePage.dart';
import 'Login.dart';
import 'Manage_Address.dart';
import 'Order_Success.dart';
import 'Payment.dart';
import 'PaypalWebviewActivity.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:collection/src/iterable_extensions.dart';

import 'midtransWebView.dart';

class Cart extends StatefulWidget {
  final bool fromBottom;

  const Cart({Key? key, required this.fromBottom}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateCart();
}

List<User> addressList = [];
List<Promo> promoList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode;
bool? isTimeSlot,
    isPromoValid = false,
    isUseWallet = false,
    isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;
bool isPromoLen = false;

double promoAmt = 0;
double remWalBal = 0, usedBal = 0;
List<File> prescriptionImages = [];

String? midtransPaymentMode,
    midtransPaymentMethod,
    midtrashClientKey,
    midTranshMerchandId,
    midtransServerKey;

String? razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId,
    paytmMerKey;
bool payTesting = true;
List<SectionModel> saveLaterList = [];
String isStorePickUp = "false";
double codDeliverChargesOfShipRocket = 0.0,
    prePaidDeliverChargesOfShipRocket = 0.0;
bool? isLocalDelCharge;

String shipRocketDeliverableDate = '';

class StateCart extends State<Cart> with TickerProviderStateMixin {
  List<Model> deliverableList = [];
  bool _isCartLoad = true, _placeOrder = true, _isSaveLoad = true;

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  TextEditingController promoC = TextEditingController();
  final List<TextEditingController> _controller = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String? msg;
  bool _isLoading = true;
  Razorpay? _razorpay;

  TextEditingController noteC = TextEditingController();
  StateSetter? checkoutState;
  final paystackPlugin = PaystackPlugin();
  bool deliverable = false;
  bool saveLater = false, addCart = false;
  final ScrollController _scrollControllerOnCartItems = ScrollController();
  final ScrollController _scrollControllerOnSaveForLaterItems =
      ScrollController();
  List<String> proIds = [];
  List<String> proVarIds = [];
  var db = DatabaseHelper();

  bool isAvailable = true;
  bool confDia = true;

  //rozarpay
  String razorpayOrderId = '';
  String? rozorpayMsg;

  @override
  void initState() {
    super.initState();
    prescriptionImages.clear();
    callApi();

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

  callApi() async {
    if (mounted) {
      context.read<CartProvider>().setProgress(false);
    }
    if (CUR_USERID != null) {
      _getCart("0");
      _getSaveLater("1");
    } else {
      proIds = (await db.getCart())!;
      _getOffCart();
      proVarIds = (await db.getSaveForLater())!;
      _getOffSaveLater();
    }
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isCartLoad = true;
        _isSaveLoad = true;
      });
    }
    isAvailable = true;
    if (CUR_USERID != null) {
      clearAll();

      _getCart("0");
      return _getSaveLater("1");
    } else {
      oriPrice = 0;
      saveLaterList.clear();
      proIds = (await db.getCart())!;
      await _getOffCart();
      proVarIds = (await db.getSaveForLater())!;
      await _getOffSaveLater();
    }
  }

  clearAll() {
    totalPrice = 0;
    oriPrice = 0;

    taxPer = 0;
    delCharge = 0;
    addressList.clear();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CartProvider>().setCartlist([]);
      context.read<CartProvider>().setProgress(false);
    });

    promoAmt = 0;
    remWalBal = 0;
    usedBal = 0;
    payMethod = '';
    isPromoValid = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
    codDeliverChargesOfShipRocket = 0.0;
    prePaidDeliverChargesOfShipRocket = 0.0;
    isLocalDelCharge = null;
    shipRocketDeliverableDate = '';
  }

  @override
  void dispose() {
    buttonController!.dispose();
    promoC.dispose();
    _scrollControllerOnCartItems.removeListener(() {});
    _scrollControllerOnSaveForLaterItems.removeListener(() {});

    for (int i = 0; i < _controller.length; i++) {
      _controller[i].dispose();
    }

    if (_razorpay != null) _razorpay!.clear();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
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

  updatePromo(String promo) {
    setState(() {
      isPromoLen = false;
      promoC.text = promo;
    });
  }

  Future<void> getShipRocketDeliveryCharge(String shipRocket, int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (addressList.isNotEmpty) {
        try {
          context.read<CartProvider>().setProgress(true);

          var parameter = {
            USER_ID: CUR_USERID,
            ADD_ID: addressList[selectedAddress!].id,
            "only_delivery_charge": shipRocket, //true
            SUB_TOTAL: oriPrice.toString()
          };

          apiBaseHelper.postAPICall(getCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            var data = getdata["data"];
            context.read<CartProvider>().setProgress(false);

            if (error) {
              setSnackbar(msg.toString(), context);
              deliverable = false;
            } else {
              if (shipRocket == "1") {
                codDeliverChargesOfShipRocket =
                    double.parse(data['delivery_charge_with_cod'].toString());

                prePaidDeliverChargesOfShipRocket = double.parse(
                    data['delivery_charge_without_cod'].toString());
                if (codDeliverChargesOfShipRocket > 0 &&
                    prePaidDeliverChargesOfShipRocket > 0) {
                  isLocalDelCharge = false;
                } else {
                  isLocalDelCharge = true;
                }

                shipRocketDeliverableDate = data['estimate_date'] ?? "";
                if (payMethod == '') {
                  delCharge = codDeliverChargesOfShipRocket;
                } else {
                  if (payMethod == getTranslated(context, 'COD_LBL')) {
                    delCharge = codDeliverChargesOfShipRocket;
                  } else {
                    delCharge = prePaidDeliverChargesOfShipRocket;
                  }
                }
              } else {
                isLocalDelCharge = true;
                delCharge = double.parse(getdata[DEL_CHARGE]);
              }
              deliverable = true;
            }
            context.read<CartProvider>().setProgress(false);
            setState(() {});
            if (mounted) {
              if (checkoutState != null) {
                checkoutState!(() {});
              }
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
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

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    hideAppbarAndBottomBarOnScroll(_scrollControllerOnCartItems, context);
    hideAppbarAndBottomBarOnScroll(
        _scrollControllerOnSaveForLaterItems, context);
    return Scaffold(
        appBar: widget.fromBottom
            ? null
            : getSimpleAppBar(getTranslated(context, 'CART')!, context),
        body: _isNetworkAvail
            ? CUR_USERID != null
                ? Stack(
                    children: <Widget>[
                      _showContent(context),
                      Selector<CartProvider, bool>(
                        builder: (context, data, child) {
                          return showCircularProgress(data, colors.primary);
                        },
                        selector: (_, provider) => provider.isProgress,
                      ),
                    ],
                  )
                : Stack(
                    children: <Widget>[
                      _showContent1(context),
                      Selector<CartProvider, bool>(
                        builder: (context, data, child) {
                          return showCircularProgress(data, colors.primary);
                        },
                        selector: (_, provider) => provider.isProgress,
                      ),
                    ],
                  )
            : noInternet(context));
  }

  addAndRemoveQty(
      String qty,
      int from,
      int totalLen,
      int index,
      double price,
      int selectedPos,
      double total,
      List<SectionModel> cartList,
      int itemCounter) async {
    if (from == 1) {
      if (int.parse(qty) >= totalLen) {
        setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
      } else {
        db.updateCart(
            cartList[index].id!,
            cartList[index].productList![0].prVarientList![selectedPos].id!,
            (int.parse(qty) + itemCounter).toString());
        context.read<CartProvider>().updateCartItem(
            cartList[index].productList![0].id!,
            (int.parse(qty) + itemCounter).toString(),
            selectedPos,
            cartList[index].productList![0].prVarientList![selectedPos].id!);

        oriPrice = (oriPrice + price);

        setState(() {});
      }
    } else if (from == 2) {
      if (int.parse(qty) <= cartList[index].productList![0].minOrderQuntity!) {
        db.updateCart(
            cartList[index].id!,
            cartList[index].productList![0].prVarientList![selectedPos].id!,
            itemCounter.toString());
        context.read<CartProvider>().updateCartItem(
            cartList[index].productList![0].id!,
            itemCounter.toString(),
            selectedPos,
            cartList[index].productList![0].prVarientList![selectedPos].id!);
        setState(() {});
      } else {
        db.updateCart(
            cartList[index].id!,
            cartList[index].productList![0].prVarientList![selectedPos].id!,
            (int.parse(qty) - itemCounter).toString());
        context.read<CartProvider>().updateCartItem(
            cartList[index].productList![0].id!,
            (int.parse(qty) - itemCounter).toString(),
            selectedPos,
            cartList[index].productList![0].prVarientList![selectedPos].id!);
        oriPrice = (oriPrice - price);
        setState(() {});
      }
    } else {
      db.updateCart(cartList[index].id!,
          cartList[index].productList![0].prVarientList![selectedPos].id!, qty);
      context.read<CartProvider>().updateCartItem(
          cartList[index].productList![0].id!,
          qty,
          selectedPos,
          cartList[index].productList![0].prVarientList![selectedPos].id!);
      oriPrice = (oriPrice - total + (int.parse(qty) * price));

      setState(() {});
    }
  }

  Widget listItem(int index, List<SectionModel> cartList) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }
    String? offPer;

    double price = double.parse(
        cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
    if (price == 0) {
      price = double.parse(
          cartList[index].productList![0].prVarientList![selectedPos].price!);
    } else {
      double off = (double.parse(cartList[index]
              .productList![0]
              .prVarientList![selectedPos]
              .price!)) -
          price;
      offPer = (off *
              100 /
              double.parse(cartList[index]
                  .productList![0]
                  .prVarientList![selectedPos]
                  .price!))
          .toStringAsFixed(2);
    }

    cartList[index].perItemPrice = price.toString();

    if (_controller.length < index + 1) {
      _controller.add(TextEditingController());
    }
    if (cartList[index].productList![0].availability != "0") {
      cartList[index].perItemTotal =
          ((cartList[index].productList![0].isSalesOn == "1"
                      ? double.parse(cartList[index]
                          .productList![0]
                          .prVarientList![selectedPos]
                          .saleFinalPrice!)
                      : price) *
                  double.parse(cartList[index].qty!))
              .toString();
      _controller[index].text = cartList[index].qty!;
    }
    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        "") {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }

    if (cartList[index].productList![0].attributeList!.isEmpty) {
      if (cartList[index].productList![0].availability == "0") {
        isAvailable = false;
      }
    } else {
      if (cartList[index]
              .productList![0]
              .prVarientList![selectedPos]
              .availability ==
          "0") {
        isAvailable = false;
      }
    }

    double total = ((cartList[index].productList![0].isSalesOn == "1"
            ? double.parse(cartList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .saleFinalPrice!)
            : price) *
        double.parse(cartList[index]
            .productList![0]
            .prVarientList![selectedPos]
            .cartCount!));
    return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 1.0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Card(
              elevation: 0.1,
              child: Row(
                children: <Widget>[
                  Hero(
                      tag:
                          "$cartHero$index${cartList[index].productList![0].id}",
                      child: Stack(
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: Stack(children: [
                                networkImageCommon(
                                    cartList[index].productList![0].type ==
                                                "variable_product" &&
                                            cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .images!
                                                .isNotEmpty
                                        ? cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .images![0]
                                        : cartList[index]
                                            .productList![0]
                                            .image!,
                                    100,
                                    false,
                                    height: 100,
                                    width: 100),
                                /*CachedNetworkImage(
                                    imageUrl:
                                        cartList[index].productList![0].type ==
                                                    "variable_product" &&
                                                cartList[index]
                                                    .productList![0]
                                                    .prVarientList![selectedPos]
                                                    .images!
                                                    .isNotEmpty
                                            ? cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .images![0]
                                            : cartList[index]
                                                .productList![0]
                                                .image!,
                                    height: 100.0,
                                    width: 100.0,
                                    fit: extendImg
                                        ? BoxFit.fill
                                        : BoxFit.contain,
                                    errorWidget: (context, error, stackTrace) =>
                                        erroWidget(125),
                                    placeholder: (context, url) {
                                      return placeHolder(125);
                                    })*/
                                Positioned.fill(
                                    child: cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .availability ==
                                            "0"
                                        ? Container(
                                            height: 55,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white70,
                                            padding: const EdgeInsets.all(2),
                                            child: Center(
                                              child: Text(
                                                getTranslated(context,
                                                    'OUT_OF_STOCK_LBL')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption!
                                                    .copyWith(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : Container()),
                              ])),
                          offPer != null
                              ? getDiscountLabel(
                                  cartList[index].productList![0].isSalesOn ==
                                          "1"
                                      ? double.parse(cartList[index]
                                              .productList![0]
                                              .saleDis!)
                                          .toStringAsFixed(2)
                                      : offPer)
                              : Container()
                        ],
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    cartList[index].productList![0].name!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              InkWell(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 8.0, end: 8, bottom: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                  ),
                                ),
                                onTap: () async {
                                  if (context.read<CartProvider>().isProgress ==
                                      false) {
                                    if (CUR_USERID != null) {
                                      removeFromCart(index, true, cartList,
                                          false, selectedPos);
                                    } else {
                                      db.removeCart(
                                          cartList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .id!,
                                          cartList[index].id!,
                                          context);
                                      cartList.removeWhere((item) =>
                                          item.varientId ==
                                          cartList[index].varientId);
                                      oriPrice = oriPrice - total;
                                      proIds = (await db.getCart())!;

                                      setState(() {});
                                    }
                                  }
                                },
                              )
                            ],
                          ),
                          cartList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .attr_name !=
                                      null &&
                                  cartList[index]
                                      .productList![0]
                                      .prVarientList![selectedPos]
                                      .attr_name!
                                      .isNotEmpty
                              ? ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: att.length,
                                  itemBuilder: (context, index) {
                                    return Row(children: [
                                      Flexible(
                                        child: Text(
                                          att[index].trim() + ":",
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 5.0),
                                        child: Text(
                                          val[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack,
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ]);
                                  })
                              : SizedBox(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                double.parse(cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .disPrice!) !=
                                        0
                                    ? getPriceFormat(
                                        context,
                                        double.parse(cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .price!))!
                                    : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .overline!
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0.7),
                              ),
                              Text(
                                cartList[index].productList![0].isSalesOn == "1"
                                    ? getPriceFormat(
                                        context,
                                        double.parse(cartList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .saleFinalPrice!))!
                                    : ' ${getPriceFormat(context, price)!} ',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          cartList[index].productList![0].availability == "1" ||
                                  cartList[index].productList![0].stockType ==
                                      ""
                              ? Row(
                                  children: <Widget>[
                                    Row(
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
                                                false) {
                                              if (CUR_USERID != null) {
                                                removeFromCart(
                                                    index,
                                                    false,
                                                    cartList,
                                                    false,
                                                    selectedPos);
                                              } else {
                                                if ((int.parse(cartList[index]
                                                        .productList![0]
                                                        .prVarientList![
                                                            selectedPos]
                                                        .cartCount!)) >
                                                    1) {
                                                  setState(() {
                                                    addAndRemoveQty(
                                                        cartList[index]
                                                            .productList![0]
                                                            .prVarientList![
                                                                selectedPos]
                                                            .cartCount!,
                                                        2,
                                                        cartList[index]
                                                                .productList![0]
                                                                .itemsCounter!
                                                                .length *
                                                            int.parse(cartList[
                                                                    index]
                                                                .productList![0]
                                                                .qtyStepSize!),
                                                        index,
                                                        cartList[index]
                                                                    .productList![
                                                                        0]
                                                                    .isSalesOn ==
                                                                "1"
                                                            ? double.parse(cartList[
                                                                    index]
                                                                .productList![0]
                                                                .prVarientList![
                                                                    selectedPos]
                                                                .saleFinalPrice!)
                                                            : price,
                                                        selectedPos,
                                                        total,
                                                        cartList,
                                                        int.parse(
                                                            cartList[index]
                                                                .productList![0]
                                                                .qtyStepSize!));
                                                  });
                                                }
                                              }
                                            }
                                          },
                                        ),
                                        SizedBox(
                                          width: 37,
                                          height: 20,
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
                                                controller: _controller[index],
                                                decoration:
                                                    const InputDecoration(
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
                                                    if (CUR_USERID != null) {
                                                      addToCart(index, value,
                                                          cartList);
                                                    } else {
                                                      addAndRemoveQty(
                                                          value,
                                                          3,
                                                          cartList[index]
                                                                  .productList![
                                                                      0]
                                                                  .itemsCounter!
                                                                  .length *
                                                              int.parse(cartList[
                                                                      index]
                                                                  .productList![
                                                                      0]
                                                                  .qtyStepSize!),
                                                          index,
                                                          cartList[index]
                                                                      .productList![
                                                                          0]
                                                                      .isSalesOn ==
                                                                  "1"
                                                              ? double.parse(cartList[
                                                                      index]
                                                                  .productList![
                                                                      0]
                                                                  .prVarientList![
                                                                      selectedPos]
                                                                  .saleFinalPrice!)
                                                              : price,
                                                          selectedPos,
                                                          total,
                                                          cartList,
                                                          int.parse(cartList[
                                                                  index]
                                                              .productList![0]
                                                              .qtyStepSize!));
                                                    }
                                                  }
                                                },
                                                itemBuilder:
                                                    (BuildContext context) {
                                                  return cartList[index]
                                                      .productList![0]
                                                      .itemsCounter!
                                                      .map<
                                                              PopupMenuItem<
                                                                  String>>(
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
                                              if (CUR_USERID != null) {
                                                addToCart(
                                                    index,
                                                    (int.parse(cartList[index]
                                                                .qty!) +
                                                            int.parse(cartList[
                                                                    index]
                                                                .productList![0]
                                                                .qtyStepSize!))
                                                        .toString(),
                                                    cartList);
                                              } else {
                                                addAndRemoveQty(
                                                    cartList[index]
                                                        .productList![0]
                                                        .prVarientList![
                                                            selectedPos]
                                                        .cartCount!,
                                                    1,
                                                    cartList[index]
                                                            .productList![0]
                                                            .itemsCounter!
                                                            .length *
                                                        int.parse(
                                                            cartList[index]
                                                                .productList![0]
                                                                .qtyStepSize!),
                                                    index,
                                                    cartList[index]
                                                                .productList![0]
                                                                .isSalesOn ==
                                                            "1"
                                                        ? double.parse(cartList[
                                                                index]
                                                            .productList![0]
                                                            .prVarientList![
                                                                selectedPos]
                                                            .saleFinalPrice!)
                                                        : price,
                                                    selectedPos,
                                                    total,
                                                    cartList,
                                                    int.parse(cartList[index]
                                                        .productList![0]
                                                        .qtyStepSize!));
                                              }
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Positioned.directional(
                textDirection: Directionality.of(context),
                end: 5,
                bottom: 12,
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: InkWell(
                    onTap: !saveLater &&
                            !context.read<CartProvider>().isProgress
                        ? () {
                            if (CUR_USERID != null) {
                              setState(() {
                                saveLater = true;
                              });
                              saveForLater(
                                  cartList[index]
                                              .productList![0]
                                              .availability ==
                                          "0"
                                      ? cartList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .id!
                                      : cartList[index].varientId,
                                  "1",
                                  cartList[index]
                                              .productList![0]
                                              .availability ==
                                          "0"
                                      ? "1"
                                      : cartList[index].qty,
                                  double.parse(cartList[index].perItemTotal!),
                                  cartList[index],
                                  false,
                                  selectedPos);
                            } else {
                              if (int.parse(cartList[index]
                                      .productList![0]
                                      .prVarientList![selectedPos]
                                      .cartCount!) >
                                  0) {
                                setState(() async {
                                  saveLater = true;
                                  context
                                      .read<CartProvider>()
                                      .setProgress(true);
                                  await saveForLaterFun(
                                      index, selectedPos, total, cartList);
                                });
                              } else {
                                context.read<CartProvider>().setProgress(true);
                              }
                            }
                          }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.archive_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ))
          ],
        ));
  }

  Widget cartItem(int index, List<SectionModel> cartList) {
    int selectedPos = 0;
    for (int i = 0;
        i < cartList[index].productList![0].prVarientList!.length;
        i++) {
      if (cartList[index].varientId ==
          cartList[index].productList![0].prVarientList![i].id) selectedPos = i;
    }

    double price = double.parse(
        cartList[index].productList![0].prVarientList![selectedPos].disPrice!);
    if (price == 0) {
      price = double.parse(
          cartList[index].productList![0].prVarientList![selectedPos].price!);
    }

    cartList[index].perItemPrice = price.toString();
    cartList[index].perItemTotal =
        ((cartList[index].productList![0].isSalesOn == "1"
                    ? double.parse(cartList[index]
                        .productList![0]
                        .prVarientList![selectedPos]
                        .saleFinalPrice!)
                    : price) *
                double.parse(cartList[index].qty!))
            .toString();

    _controller[index].text = cartList[index].qty!;

    List att = [], val = [];
    if (cartList[index].productList![0].prVarientList![selectedPos].attr_name !=
        "") {
      att = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .attr_name!
          .split(',');
      val = cartList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .varient_value!
          .split(',');
    }

    String? id, varId;
    bool? avail = false;
    String deliveryMsg = '';
    if (deliverableList.isNotEmpty) {
      id = cartList[index].id;
      varId = cartList[index].productList![0].prVarientList![selectedPos].id;

      for (int i = 0; i < deliverableList.length; i++) {
        if (id == deliverableList[i].prodId &&
            varId == deliverableList[i].varId) {
          avail = deliverableList[i].isDel;
          if (deliverableList[i].msg != null) {
            deliveryMsg = deliverableList[i].msg!;
          }

          break;
        }
      }
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Hero(
                    tag: "$cartHero$index${cartList[index].productList![0].id}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: networkImageCommon(
                          cartList[index].productList![0].type ==
                                      "variable_product" &&
                                  cartList[index]
                                      .productList![0]
                                      .prVarientList![selectedPos]
                                      .images!
                                      .isNotEmpty
                              ? cartList[index]
                                  .productList![0]
                                  .prVarientList![selectedPos]
                                  .images![0]
                              : cartList[index].productList![0].image!,
                          100,
                          false,
                          height: 100,
                          width: 100),
                      /*CachedNetworkImage(
                            imageUrl: cartList[index].productList![0].type ==
                                        "variable_product" &&
                                    cartList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .images!
                                        .isNotEmpty
                                ? cartList[index]
                                    .productList![0]
                                    .prVarientList![selectedPos]
                                    .images![0]
                                : cartList[index].productList![0].image!,
                            height: 100.0,
                            width: 100.0,
                            fit: extendImg ? BoxFit.fill : BoxFit.contain,
                            errorWidget: (context, error, stackTrace) =>
                                erroWidget(80),
                            placeholder: (context, url) {
                              return placeHolder(80);
                            })*/
                    )),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  cartList[index].productList![0].name!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 8.0, end: 8, bottom: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                ),
                              ),
                              onTap: () {
                                if (context.read<CartProvider>().isProgress ==
                                    false) {
                                  removeFromCartCheckout(index, true, cartList);
                                }
                              },
                            )
                          ],
                        ),
                        cartList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .attr_name !=
                                    "" &&
                                cartList[index]
                                    .productList![0]
                                    .prVarientList![selectedPos]
                                    .attr_name!
                                    .isNotEmpty
                            ? ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(children: [
                                    Flexible(
                                      child: Text(
                                        att[index].trim() + ":",
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 5.0),
                                      child: Text(
                                        val[index],
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack,
                                                fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ]);
                                })
                            : Container(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      double.parse(cartList[index]
                                                  .productList![0]
                                                  .prVarientList![selectedPos]
                                                  .disPrice!) !=
                                              0
                                          ? getPriceFormat(
                                              context,
                                              double.parse(cartList[index]
                                                  .productList![0]
                                                  .prVarientList![selectedPos]
                                                  .price!))!
                                          : "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .overline!
                                          .copyWith(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              letterSpacing: 0.7),
                                    ),
                                  ),
                                  Text(
                                    cartList[index].productList![0].isSalesOn ==
                                            "1"
                                        ? getPriceFormat(
                                            context,
                                            double.parse(cartList[index]
                                                .productList![0]
                                                .prVarientList![selectedPos]
                                                .saleFinalPrice!))!
                                        : '${getPriceFormat(context, price)!} ',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            cartList[index].productList![0].availability ==
                                        "1" ||
                                    cartList[index].productList![0].stockType ==
                                        ""
                                ? Row(
                                    children: <Widget>[
                                      Row(
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
                                                  false) {
                                                removeFromCartCheckout(
                                                    index, false, cartList);
                                              }
                                            },
                                          ),
                                          SizedBox(
                                            width: 37,
                                            height: 20,
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
                                                  controller:
                                                      _controller[index],
                                                  decoration:
                                                      const InputDecoration(
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
                                                    addToCartCheckout(
                                                        index, value, cartList);
                                                  },
                                                  itemBuilder:
                                                      (BuildContext context) {
                                                    return cartList[index]
                                                        .productList![0]
                                                        .itemsCounter!
                                                        .map<
                                                                PopupMenuItem<
                                                                    String>>(
                                                            (String value) {
                                                      return PopupMenuItem(
                                                          value: value,
                                                          child: Text(
                                                            value,
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .fontColor),
                                                          ));
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
                                                  addToCartCheckout(
                                                      index,
                                                      (int.parse(cartList[index]
                                                                  .qty!) +
                                                              int.parse(cartList[
                                                                      index]
                                                                  .productList![
                                                                      0]
                                                                  .qtyStepSize!))
                                                          .toString(),
                                                      cartList);
                                                }
                                              })
                                        ],
                                      ),
                                    ],
                                  )
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  getTranslated(context, 'NET_AMOUNT')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  ' ${getPriceFormat(context, (double.parse(cartList[index].netAmt!)))} x ${cartList[index].qty}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  ' ${getPriceFormat(context, (double.parse(cartList[index].netAmt!)) * int.parse(cartList[index].qty!))!}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'TAXPER')!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  '${cartList[index].taxPercentage!}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  ' ${getPriceFormat(context, double.parse(cartList[index].taxAmt!) * (int.parse(cartList[index].qty!)))}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, 'TOTAL_LBL')!,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  getPriceFormat(
                      context, double.parse(cartList[index].perItemTotal!))!,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.fontColor),
                )
              ],
            ),
            if (IS_LOCAL_PICKUP != "1" || isStorePickUp != "true")
              !avail! && deliverableList.isNotEmpty && deliveryMsg != ''
                  ? Text(deliveryMsg,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: colors.red,
                          ))
                  : Container(),
          ],
        ),
      ),
    );
  }

  Widget saveLaterItem(int index) {
    int selectedPos = 0;
    for (int i = 0;
        i < saveLaterList[index].productList![0].prVarientList!.length;
        i++) {
      if (saveLaterList[index].varientId ==
          saveLaterList[index].productList![0].prVarientList![i].id) {
        selectedPos = i;
      }
    }

    double price = double.parse(saveLaterList[index]
        .productList![0]
        .prVarientList![selectedPos]
        .disPrice!);
    if (price == 0) {
      price = double.parse(saveLaterList[index]
          .productList![0]
          .prVarientList![selectedPos]
          .price!);
    }

    double off = (double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .price!) -
            double.parse(saveLaterList[index]
                .productList![0]
                .prVarientList![selectedPos]
                .disPrice!))
        .toDouble();
    off = off *
        100 /
        double.parse(saveLaterList[index]
            .productList![0]
            .prVarientList![selectedPos]
            .price!);

    saveLaterList[index].perItemPrice = price.toString();
    if (saveLaterList[index].productList![0].availability != "0") {
      saveLaterList[index].perItemTotal =
          ((saveLaterList[index].productList![0].isSalesOn == "1"
                      ? double.parse(saveLaterList[index]
                          .productList![0]
                          .prVarientList![selectedPos]
                          .saleFinalPrice!)
                      : price) *
                  double.parse(saveLaterList[index].qty!))
              .toString();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 0.1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Hero(
                    tag:
                        "$cartHero$index${saveLaterList[index].productList![0].id}",
                    child: Stack(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(7.0),
                            child: Stack(children: [
                              networkImageCommon(
                                  saveLaterList[index].productList![0].type ==
                                              "variable_product" &&
                                          saveLaterList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .images!
                                              .isNotEmpty
                                      ? saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .images![0]
                                      : saveLaterList[index]
                                          .productList![0]
                                          .image!,
                                  100,
                                  false,
                                  height: 100,
                                  width: 100),
                              /*CachedNetworkImage(
                                  imageUrl: saveLaterList[index]
                                                  .productList![0]
                                                  .type ==
                                              "variable_product" &&
                                          saveLaterList[index]
                                              .productList![0]
                                              .prVarientList![selectedPos]
                                              .images!
                                              .isNotEmpty
                                      ? saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .images![0]
                                      : saveLaterList[index]
                                          .productList![0]
                                          .image!,
                                  height: 100.0,
                                  width: 100.0,
                                  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                  errorWidget: (context, error, stackTrace) =>
                                      erroWidget(100),
                                  placeholder: (context, url) {
                                    return placeHolder(100);
                                  }),*/
                              Positioned.fill(
                                  child: saveLaterList[index]
                                              .productList![selectedPos]
                                              .availability ==
                                          "0"
                                      ? Container(
                                          height: 55,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white70,
                                          padding: const EdgeInsets.all(2),
                                          child: Center(
                                            child: Text(
                                              getTranslated(
                                                  context, 'OUT_OF_STOCK_LBL')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .copyWith(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : Container()),
                            ])),
                        off != 0 &&
                                saveLaterList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .disPrice! !=
                                    "0"
                            ? saveLaterList[index].productList![0].isSalesOn ==
                                    "1"
                                ? getDiscountLabel(double.parse(
                                        saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .saleFinalPrice!)
                                    .toStringAsFixed(2))
                                : getDiscountLabel(off.toStringAsFixed(2))
                            : Container()
                      ],
                    )),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  saveLaterList[index].productList![0].name!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 8.0, end: 8, bottom: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                ),
                              ),
                              onTap: () async {
                                if (context.read<CartProvider>().isProgress ==
                                    false) {
                                  if (CUR_USERID != null) {
                                    removeFromCart(index, true, saveLaterList,
                                        true, selectedPos);
                                  } else {
                                    db.removeSaveForLater(
                                        saveLaterList[index]
                                            .productList![0]
                                            .prVarientList![selectedPos]
                                            .id!,
                                        saveLaterList[index]
                                            .productList![0]
                                            .id!);
                                    proVarIds.remove(saveLaterList[index]
                                        .productList![0]
                                        .prVarientList![selectedPos]
                                        .id!);

                                    saveLaterList.removeAt(index);
                                    setState(() {});
                                  }
                                }
                              },
                            )
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Text(
                              double.parse(saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .disPrice!) !=
                                      0
                                  ? getPriceFormat(
                                      context,
                                      double.parse(saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .price!))!
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .overline!
                                  .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      letterSpacing: 0.7),
                            ),
                            Text(
                              saveLaterList[index].productList![0].isSalesOn ==
                                      "1"
                                  ? getPriceFormat(
                                      context,
                                      double.parse(saveLaterList[index]
                                          .productList![0]
                                          .prVarientList![selectedPos]
                                          .saleFinalPrice!))!
                                  : ' ${getPriceFormat(context, price)!} ',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        saveLaterList[index].productList![0].availability == "1" ||
                saveLaterList[index].productList![0].stockType == ""
            ? Positioned.directional(
                textDirection: Directionality.of(context),
                bottom: 12,
                end: 5,
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: InkWell(
                    onTap: !addCart && !context.read<CartProvider>().isProgress
                        ? () {
                            if (CUR_USERID != null) {
                              setState(() {
                                addCart = true;
                              });
                              saveForLater(
                                  saveLaterList[index].varientId,
                                  "0",
                                  saveLaterList[index].qty,
                                  double.parse(
                                      saveLaterList[index].perItemTotal!),
                                  saveLaterList[index],
                                  true,
                                  selectedPos);
                            } else {
                              setState(() async {
                                addCart = true;
                                context.read<CartProvider>().setProgress(true);
                                await cartFun(
                                    index,
                                    selectedPos,
                                    double.parse(
                                        saveLaterList[index].perItemTotal!));
                              });
                            }
                          }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.shopping_cart,
                        size: 20,
                      ),
                    ),
                  ),
                ))
            : Container()
      ],
    );
  }

  Future<void> _getCart(String save) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
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

            oriPrice = double.parse(getdata[SUB_TOTAL]);

            taxPer = double.parse(getdata[TAX_PER]);

            totalPrice = oriPrice;

            List<SectionModel> cartList = (data as List)
                .map((data) => SectionModel.fromCart(data))
                .toList();

            context.read<CartProvider>().setCartlist(cartList);

            if (getdata.containsKey(PROMO_CODES)) {
              var promo = getdata[PROMO_CODES];
              promoList =
                  (promo as List).map((e) => Promo.fromJson(e)).toList();
            }

            for (int i = 0; i < cartList.length; i++) {
              _controller.add(TextEditingController());
            }
          } else {
            if (msg != 'Cart Is Empty !') setSnackbar(msg!, context);
          }
          if (mounted) {
            setState(() {
              _isCartLoad = false;
            });
          }

          _getAddress();
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
  }

  Future<void> _getOffCart() async {
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
              setState(() {
                context.read<CartProvider>().setCartlist([]);

                oriPrice = 0;
              });

              List<Product> cartList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              for (int i = 0; i < cartList.length; i++) {
                for (int j = 0; j < cartList[i].prVarientList!.length; j++) {
                  if (proIds.contains(cartList[i].prVarientList![j].id)) {
                    String qty = (await db.checkCartItemExists(
                        cartList[i].id!, cartList[i].prVarientList![j].id!))!;

                    List<Product>? prList = [];
                    cartList[i].prVarientList![j].cartCount = qty;
                    prList.add(cartList[i]);

                    context.read<CartProvider>().addCartItem(SectionModel(
                          id: cartList[i].id,
                          varientId: cartList[i].prVarientList![j].id,
                          qty: qty,
                          productList: prList,
                        ));

                    double price =
                        double.parse(cartList[i].prVarientList![j].disPrice!);
                    if (price == 0) {
                      price =
                          double.parse(cartList[i].prVarientList![j].price!);
                    }

                    double total = (price * int.parse(qty));
                    setState(() {
                      oriPrice = oriPrice + total;
                    });
                  }
                }
              }

              setState(() {});
            }
            if (mounted) {
              setState(() {
                _isCartLoad = false;
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
    } else {
      context.read<CartProvider>().setCartlist([]);
      setState(() {
        _isCartLoad = false;
      });
    }
  }

  Future<void> _getOffSaveLater() async {
    if (proVarIds.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        try {
          var parameter = {"product_variant_ids": proVarIds.join(',')};
          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];
              saveLaterList.clear();
              List<Product> cartList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              for (int i = 0; i < cartList.length; i++) {
                for (int j = 0; j < cartList[i].prVarientList!.length; j++) {
                  if (proVarIds.contains(cartList[i].prVarientList![j].id)) {
                    String qty = (await db.checkSaveForLaterExists(
                        cartList[i].id!, cartList[i].prVarientList![j].id!))!;
                    List<Product>? prList = [];
                    prList.add(cartList[i]);
                    saveLaterList.add(SectionModel(
                      id: cartList[i].id,
                      varientId: cartList[i].prVarientList![j].id,
                      qty: qty,
                      productList: prList,
                    ));
                  }
                }
              }

              setState(() {});
            }
            if (mounted) {
              setState(() {
                _isSaveLoad = false;
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
    } else {
      setState(() {
        _isSaveLoad = false;
      });
      saveLaterList = [];
    }
  }

  Future<void> _getSaveLater(String save) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
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

            saveLaterList = (data as List)
                .map((data) => SectionModel.fromCart(data))
                .toList();

            List<SectionModel> cartList = context.read<CartProvider>().cartList;
            for (int i = 0; i < cartList.length; i++) {
              _controller.add(TextEditingController());
            }
          } else {
            if (msg != 'Cart Is Empty !') setSnackbar(msg!, context);
          }
          if (mounted) setState(() {});
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

    return;
  }

  Future<void> addToCart(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            cartList[index].qty = qty;

            oriPrice = double.parse(data['sub_total']);

            _controller[index].text = qty;
            totalPrice = 0;

            var cart = getdata["cart"];
            List<SectionModel> uptcartList = (cart as List)
                .map((cart) => SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(uptcartList);

            if (IS_SHIPROCKET_ON == "0") {
              if (!ISFLAT_DEL) {
                if (addressList.isEmpty) {
                  delCharge = 0;
                } else {
                  if ((oriPrice) <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }
              } else {
                if (oriPrice < double.parse(MIN_AMT!)) {
                  delCharge = double.parse(CUR_DEL_CHR!);
                } else {
                  delCharge = 0;
                }
              }
            }

            totalPrice = oriPrice;

            if (isPromoValid!) {
              validatePromo(false);
            } else if (isUseWallet!) {
              context.read<CartProvider>().setProgress(false);
              if (mounted) {
                setState(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;

                  selectedMethod = null;
                });
              }
            } else {
              setState(() {});
              context.read<CartProvider>().setProgress(false);
            }
          } else {
            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
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
        });
      }
    }
  }

  Future<void> addToCartCheckout(
      int index, String qty, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        if (int.parse(qty) < cartList[index].productList![0].minOrderQuntity!) {
          qty = cartList[index].productList![0].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          PRODUCT_VARIENT_ID: cartList[index].varientId,
          USER_ID: CUR_USERID,
          QTY: qty,
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            cartList[index].qty = qty;

            oriPrice = double.parse(data['sub_total']);
            _controller[index].text = qty;
            totalPrice = 0;

            if (IS_SHIPROCKET_ON == "0") {
              if (!ISFLAT_DEL) {
                if ((oriPrice) <
                    double.parse(addressList[selectedAddress!].freeAmt!)) {
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                } else {
                  delCharge = 0;
                }
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!)) {
                  delCharge = double.parse(CUR_DEL_CHR!);
                } else {
                  delCharge = 0;
                }
              }
            }

            totalPrice = oriPrice;

            if (isPromoValid!) {
              validatePromo(true);
            } else if (isUseWallet!) {
              if (mounted) {
                checkoutState!(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;

                  selectedMethod = null;
                });
              }
              setState(() {});
            } else {
              context.read<CartProvider>().setProgress(false);
              setState(() {});
              checkoutState!(() {});
            }
          } else {
            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
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
        checkoutState!(() {
          _isNetworkAvail = false;
        });
      }
      setState(() {});
    }
  }

  saveForLaterFun(int index, int selectedPos, double total,
      List<SectionModel> cartList) async {
    db.moveToCartOrSaveLater(
        "cart",
        cartList[index].productList![0].prVarientList![selectedPos].id!,
        cartList[index].id!,
        context);

    proVarIds
        .add(cartList[index].productList![0].prVarientList![selectedPos].id!);
    proIds.remove(
        cartList[index].productList![0].prVarientList![selectedPos].id!);
    oriPrice = oriPrice - total;
    saveLaterList.add(context.read<CartProvider>().cartList[index]);
    context.read<CartProvider>().removeCartItem(
        cartList[index].productList![0].prVarientList![selectedPos].id!);

    saveLater = false;
    context.read<CartProvider>().setProgress(false);
    setState(() {});
  }

  cartFun(int index, int selectedPos, double total) async {
    int cartCount = await db.getTotalCartCount(context);
    if (int.parse(MAX_ITEMS!) > cartCount) {
      db.moveToCartOrSaveLater(
          "save",
          saveLaterList[index].productList![0].prVarientList![selectedPos].id!,
          saveLaterList[index].id!,
          context);

      proIds.add(
          saveLaterList[index].productList![0].prVarientList![selectedPos].id!);
      proVarIds.remove(
          saveLaterList[index].productList![0].prVarientList![selectedPos].id!);
      oriPrice = oriPrice + total;

      List<SectionModel> cartList = context.read<CartProvider>().cartList;

      if (cartList.isNotEmpty) {
        SectionModel? tempId = cartList.firstWhereOrNull((cp) =>
            cp.id == saveLaterList[index].productList![0].id &&
            cp.varientId ==
                saveLaterList[index]
                    .productList![0]
                    .prVarientList![selectedPos]
                    .id!);

        if (tempId != null) {
          context.read<CartProvider>().updateCartItem(
              saveLaterList[index].productList![0].id,
              (int.parse(tempId.qty!) +
                      int.parse(
                          saveLaterList[index].productList![0].qtyStepSize!))
                  .toString(),
              selectedPos,
              saveLaterList[index]
                  .productList![0]
                  .prVarientList![selectedPos]
                  .id!);
          saveLaterList.removeAt(index);
        } else {
          context.read<CartProvider>().addCartItem(saveLaterList[index]);
          saveLaterList.removeAt(index);
        }
      } else {
        context.read<CartProvider>().addCartItem(saveLaterList[index]);
        saveLaterList.removeAt(index);
      }

      addCart = false;
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    } else {
      setSnackbar(
          "In Cart maximum ${int.parse(MAX_ITEMS!)} product allowed", context);
    }
  }

  saveForLater(String? id, String save, String? qty, double price,
      SectionModel curItem, bool fromSave, int selectedPos) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          PRODUCT_VARIENT_ID: id,
          USER_ID: CUR_USERID,
          QTY: qty,
          SAVE_LATER: save
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            if (save == "1") {
              saveLaterList.add(curItem);

              context.read<CartProvider>().removeCartItem(id!);
              setState(() {
                saveLater = false;
              });
              oriPrice = oriPrice - price;
            } else {
              List<SectionModel> cartList =
                  context.read<CartProvider>().cartList;

              if (cartList.isNotEmpty) {
                SectionModel? tempId = cartList.firstWhereOrNull(
                    (cp) => cp.id == curItem.id && cp.varientId == id);

                if (tempId != null) {
                  context.read<CartProvider>().updateCartItem(
                      curItem.id,
                      (int.parse(tempId.qty!) +
                              int.parse(curItem.productList![0].qtyStepSize!))
                          .toString(),
                      selectedPos,
                      id!);
                  saveLaterList.removeWhere((item) => item.varientId == id);
                } else {
                  context.read<CartProvider>().addCartItem(curItem);
                  saveLaterList.removeWhere((item) => item.varientId == id);
                }
              } else {
                context.read<CartProvider>().addCartItem(curItem);
                saveLaterList.removeWhere((item) => item.varientId == id);
              }

              setState(() {
                addCart = false;
              });
              oriPrice = oriPrice + price;
            }

            totalPrice = 0;
            if (IS_SHIPROCKET_ON == "0") {
              if (!ISFLAT_DEL) {
                if (addressList.isNotEmpty &&
                    (oriPrice) <
                        double.parse(addressList[selectedAddress!].freeAmt!)) {
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                } else {
                  delCharge = 0;
                }
              } else {
                if ((oriPrice) < double.parse(MIN_AMT!)) {
                  delCharge = double.parse(CUR_DEL_CHR!);
                } else {
                  delCharge = 0;
                }
              }
            }

            totalPrice = oriPrice;

            if (isPromoValid!) {
              validatePromo(false);
            } else if (isUseWallet!) {
              context.read<CartProvider>().setProgress(false);
              if (mounted) {
                setState(() {
                  remWalBal = 0;
                  payMethod = null;
                  usedBal = 0;
                  isUseWallet = false;
                  isPayLayShow = true;
                });
              }
            } else {
              context.read<CartProvider>().setProgress(false);
              setState(() {});
            }
          } else {
            setSnackbar(msg!, context);
          }

          context.read<CartProvider>().setProgress(false);
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
        });
      }
    }
  }

  removeFromCartCheckout(
      int index, bool remove, List<SectionModel> cartList) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          context);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int? qty;
          if (remove) {
            qty = 0;
          } else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
            }
          }

          var parameter = {
            PRODUCT_VARIENT_ID: cartList[index].varientId,
            USER_ID: CUR_USERID,
            QTY: qty.toString()
          };
          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];

              context.read<UserProvider>().setCartCount(data['cart_count']);
              if (qty == "0") remove = true;

              if (remove) {
                context
                    .read<CartProvider>()
                    .removeCartItem(cartList[index].varientId!);
              } else {
                cartList[index].qty = qty.toString();
              }

              oriPrice = double.parse(data[SUB_TOTAL]);
              if (IS_SHIPROCKET_ON == "0") {
                if (!ISFLAT_DEL) {
                  if ((oriPrice) <
                      double.parse(addressList[selectedAddress!].freeAmt!)) {
                    delCharge = double.parse(
                        addressList[selectedAddress!].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                } else {
                  if ((oriPrice) < double.parse(MIN_AMT!)) {
                    delCharge = double.parse(CUR_DEL_CHR!);
                  } else {
                    delCharge = 0;
                  }
                }
              }

              totalPrice = 0;

              totalPrice = oriPrice;

              if (isPromoValid!) {
                validatePromo(true);
              } else if (isUseWallet!) {
                if (mounted) {
                  checkoutState!(() {
                    remWalBal = 0;
                    payMethod = null;
                    usedBal = 0;
                    isPayLayShow = true;
                    isUseWallet = false;
                  });
                }
                context.read<CartProvider>().setProgress(false);
                setState(() {});
              } else {
                context.read<CartProvider>().setProgress(false);

                checkoutState!(() {});
                setState(() {});
              }
            } else {
              setSnackbar(msg!, context);
              context.read<CartProvider>().setProgress(false);
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
          checkoutState!(() {
            _isNetworkAvail = false;
          });
        }
        setState(() {});
      }
    }
  }

  removeFromCart(int index, bool remove, List<SectionModel> cartList, bool move,
      int selPos) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (!remove &&
        int.parse(cartList[index].qty!) ==
            cartList[index].productList![0].minOrderQuntity) {
      setSnackbar("${getTranslated(context, 'MIN_MSG')}${cartList[index].qty}",
          context);
    } else {
      if (_isNetworkAvail) {
        try {
          context.read<CartProvider>().setProgress(true);

          int? qty;
          if (remove) {
            qty = 0;
          } else {
            qty = (int.parse(cartList[index].qty!) -
                int.parse(cartList[index].productList![0].qtyStepSize!));

            if (qty < cartList[index].productList![0].minOrderQuntity!) {
              qty = cartList[index].productList![0].minOrderQuntity;

              setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
            }
          }
          String varId;
          if (cartList[index].productList![0].availability == "0") {
            varId = cartList[index].productList![0].prVarientList![selPos].id!;
          } else {
            varId = cartList[index].varientId!;
          }

          var parameter = {
            PRODUCT_VARIENT_ID: varId,
            USER_ID: CUR_USERID,
            QTY: qty.toString()
          };
          apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              var data = getdata["data"];

              String? qty = data['total_quantity'];

              context.read<UserProvider>().setCartCount(data['cart_count']);
              if (move == false) {
                if (qty == "0") remove = true;

                if (remove) {
                  cartList.removeWhere(
                      (item) => item.varientId == cartList[index].varientId);
                } else {
                  cartList[index].qty = qty.toString();
                }

                oriPrice = double.parse(data[SUB_TOTAL]);
                if (IS_SHIPROCKET_ON == "0") {
                  if (!ISFLAT_DEL) {
                    if (addressList.isNotEmpty &&
                        (oriPrice) <
                            double.parse(
                                addressList[selectedAddress!].freeAmt!)) {
                      delCharge = double.parse(
                          addressList[selectedAddress!].deliveryCharge!);
                    } else {
                      delCharge = 0;
                    }
                  } else {
                    if ((oriPrice) < double.parse(MIN_AMT!)) {
                      delCharge = double.parse(CUR_DEL_CHR!);
                    } else {
                      delCharge = 0;
                    }
                  }
                }

                totalPrice = 0;

                totalPrice = oriPrice;

                if (isPromoValid!) {
                  validatePromo(false);
                } else if (isUseWallet!) {
                  context.read<CartProvider>().setProgress(false);
                  if (mounted) {
                    setState(() {
                      remWalBal = 0;
                      payMethod = null;
                      usedBal = 0;
                      isPayLayShow = true;
                      isUseWallet = false;
                    });
                  }
                } else {
                  context.read<CartProvider>().setProgress(false);
                  setState(() {});
                }
              } else {
                if (qty == "0") remove = true;

                if (remove) {
                  cartList.removeWhere(
                      (item) => item.varientId == cartList[index].varientId);
                }
              }
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) setState(() {});
            context.read<CartProvider>().setProgress(false);
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
          });
        }
      }
    }
  }

  _showContent1(BuildContext context) {
    List<SectionModel> cartList = context.read<CartProvider>().cartList;

    return _isCartLoad || _isSaveLoad
        ? shimmer(context)
        : cartList.isEmpty && saveLaterList.isEmpty
            ? cartEmpty()
            : Container(
                color: Theme.of(context).colorScheme.lightWhite,
                padding:
                    const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: RefreshIndicator(
                              color: colors.primary,
                              key: _refreshIndicatorKey,
                              onRefresh: _refresh,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                controller: _scrollControllerOnCartItems,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: cartList.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return listItem(index, cartList);
                                      },
                                    ),
                                    saveLaterList.isNotEmpty &&
                                            proVarIds.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              getTranslated(
                                                  context, 'SAVEFORLATER_BTN')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle1!
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor),
                                            ),
                                          )
                                        : Container(height: 0),
                                    if (saveLaterList.isNotEmpty &&
                                        proVarIds.isNotEmpty)
                                      ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: saveLaterList.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return saveLaterItem(index);
                                        },
                                      ),
                                    Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          context
                                                      .read<CartProvider>()
                                                      .cartList
                                                      .length !=
                                                  0
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .white,
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                  ),
                                                  margin: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 5,
                                                      vertical: 8),
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 10,
                                                      horizontal: 5),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(getTranslated(
                                                              context,
                                                              'TOTAL_PRICE')!),
                                                          Text(
                                                            '${getPriceFormat(context, oriPrice)!} ',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle1!
                                                                .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .fontColor),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ))
                                              : Container(
                                                  height: 0,
                                                ),
                                        ]),
                                  ],
                                ),
                              ))),
                    ),
                    cartList.isNotEmpty
                        ? Center(
                            child: SimBtn(
                                width: 0.9,
                                height: 35,
                                title:
                                    getTranslated(context, 'PROCEED_CHECKOUT'),
                                onBtnSelected: () async {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => const Login()),
                                  );
                                }),
                          )
                        : Container(
                            height: 0,
                          ),
                  ],
                ),
              );
  }

  _showContent(BuildContext context) {
    List<SectionModel> cartList = context.read<CartProvider>().cartList;
    return _isCartLoad
        ? shimmer(context)
        : cartList.isEmpty && saveLaterList.isEmpty
            ? cartEmpty()
            : Container(
                padding:
                    const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                color: Theme.of(context).colorScheme.lightWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: RefreshIndicator(
                          color: colors.primary,
                          key: _refreshIndicatorKey,
                          onRefresh: _refresh,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            controller: _scrollControllerOnCartItems,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cartList.isNotEmpty)
                                  ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: cartList.length,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return listItem(index, cartList);
                                    },
                                  ),
                                if (saveLaterList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      getTranslated(
                                          context, 'SAVEFORLATER_BTN')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor),
                                    ),
                                  ),
                                if (saveLaterList.isNotEmpty)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: saveLaterList.length,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return saveLaterItem(index);
                                    },
                                  ),
                                Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      if (promoList.isNotEmpty && oriPrice > 0)
                                        Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Stack(
                                            alignment: Alignment.centerRight,
                                            children: [
                                              Container(
                                                  margin:
                                                      const EdgeInsetsDirectional
                                                          .only(end: 20),
                                                  decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .white,
                                                      borderRadius:
                                                          BorderRadiusDirectional
                                                              .circular(5)),
                                                  child: TextField(
                                                    textDirection:
                                                        Directionality.of(
                                                            context),
                                                    controller: promoC,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle2,
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets
                                                                  .symmetric(
                                                              horizontal: 10),
                                                      border: InputBorder.none,
                                                      hintText: getTranslated(
                                                              context,
                                                              'PROMOCODE_LBL') ??
                                                          '',
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        if (val.isEmpty) {
                                                          isPromoLen = false;

                                                          isPromoValid = false;
                                                          promoEmpty()
                                                              .then((value) {
                                                            promoAmt = 0;
                                                          });
                                                        } else {
                                                          //promoAmt = 0;
                                                          isPromoLen = true;
                                                          isPromoValid = false;
                                                        }
                                                      });
                                                    },
                                                  )),
                                              Positioned.directional(
                                                textDirection:
                                                    Directionality.of(context),
                                                end: 0,
                                                child: InkWell(
                                                  onTap: () {
                                                    if (promoC.text.isEmpty) {
                                                      Navigator.push(
                                                          context,
                                                          CupertinoPageRoute(
                                                            builder: (context) =>
                                                                PromoCode(
                                                                    from:
                                                                        "cart",
                                                                    updateParent:
                                                                        updatePromo),
                                                          ));
                                                    }
                                                  },
                                                  child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              11),
                                                      decoration:
                                                          const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: colors.primary,
                                                      ),
                                                      child: Icon(
                                                        Icons.arrow_forward,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .white,
                                                      )),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(5),
                                            ),
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 8),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 5),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isPromoValid!)
                                                if (!isPromoLen)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        getTranslated(context,
                                                            'PROMO_CODE_DIS_LBL')!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .caption!
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .lightBlack2),
                                                      ),
                                                      Text(
                                                        '${getPriceFormat(context, promoAmt)!} ',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .caption!
                                                            .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .lightBlack2),
                                                      )
                                                    ],
                                                  ),
                                              Row(
                                                //  mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(getTranslated(
                                                      context, 'TOTAL_PRICE')!),
                                                  Text(
                                                    '${getPriceFormat(context, oriPrice)!} ',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subtitle1!
                                                        .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )),
                                    ]),
                              ],
                            ),
                          )),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (IS_LOCAL_PICKUP == "1")
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Radio(
                                      fillColor: MaterialStateColor.resolveWith(
                                          (states) {
                                        return colors.primary;
                                      }),
                                      groupValue: isStorePickUp,
                                      value: "false",
                                      onChanged: (val) {
                                        setState(() {
                                          isStorePickUp = val.toString();
                                          if (selAddress == "" ||
                                              selAddress!.isEmpty) {}
                                        });
                                      },
                                    ),
                                    Text(
                                      getTranslated(
                                          context, 'DOOR_STEP_DEL_LBL')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                    Radio(
                                      fillColor: MaterialStateColor.resolveWith(
                                          (states) {
                                        return colors.primary;
                                      }),
                                      hoverColor: colors.primary,
                                      groupValue: isStorePickUp,
                                      value: "true",
                                      onChanged: (val) {
                                        setState(() {
                                          isStorePickUp = val.toString();
                                        });
                                      },
                                    ),
                                    Text(
                                        getTranslated(
                                            context, 'PICKUP_STORE_LBL')!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor))
                                  ])),
                            ],
                          ),
                        Center(
                          child: SimBtn(
                              width: 0.9,
                              height: 35,
                              title: isPromoLen
                                  ? getTranslated(context, 'VALI_PRO_CODE')
                                  : getTranslated(context, 'PROCEED_CHECKOUT'),
                              onBtnSelected: () async {
                                if (isPromoLen == false) {
                                  if (oriPrice > 0) {
                                    FocusScope.of(context).unfocus();
                                    if (isAvailable) {
                                      if (totalPrice != 0) {
                                        checkout(cartList);
                                      }
                                    } else {
                                      setSnackbar(
                                          getTranslated(context,
                                              'CART_OUT_OF_STOCK_MSG')!,
                                          context);
                                    }
                                    if (mounted) setState(() {});
                                  } else {
                                    setSnackbar(
                                        getTranslated(context, 'ADD_ITEM')!,
                                        context);
                                  }
                                } else {
                                  validatePromo(false).then((value) {
                                    FocusScope.of(context).unfocus();
                                  });
                                }
                              }),
                        ),
                      ],
                    )
                  ],
                ),
              );
  }

  Future<void> promoEmpty() async {
    setState(() {
      totalPrice = totalPrice + promoAmt;
    });
  }

  cartEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noCartImage(context),
          noCartText(context),
          noCartDec(context),
          shopNow()
        ]),
      ),
    );
  }

  getAllPromo() {}

  noCartImage(BuildContext context) {
    return Image.asset(
      'assets/images/Empty_cart.png',
      fit: BoxFit.contain,
    );
  }

  noCartText(BuildContext context) {
    return Text(getTranslated(context, 'NO_CART')!,
        style: Theme.of(context)
            .textTheme
            .headline5!
            .copyWith(color: colors.primary, fontWeight: FontWeight.normal));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding:
          const EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC')!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack2,
                fontWeight: FontWeight.normal,
              )),
    );
  }

  shopNow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28.0),
      child: CupertinoButton(
        child: Container(
            width: deviceWidth! * 0.7,
            height: 45,
            alignment: FractionalOffset.center,
            decoration: const BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
            ),
            child: Text(getTranslated(context, 'SHOP_NOW')!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Theme.of(context).colorScheme.white,
                    fontWeight: FontWeight.normal))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  checkout(List<SectionModel> cartList) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    if (isStorePickUp == "false" && addressList.isNotEmpty && !deliverable) {
      checkDeliverable(2);
    }

    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            checkoutState = setState;
            return Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: _isNetworkAvail
                      ? cartList.isEmpty
                          ? cartEmpty()
                          : _isLoading
                              ? shimmer(context)
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: <Widget>[
                                          SingleChildScrollView(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (IS_LOCAL_PICKUP != "1" ||
                                                      isStorePickUp != "true")
                                                    address(),
                                                  attachPrescriptionImages(
                                                      cartList),
                                                  payment(),
                                                  cartItems(cartList),
                                                  orderSummary(cartList),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Selector<CartProvider, bool>(
                                            builder: (context, data, child) {
                                              return showCircularProgress(
                                                  data, colors.primary);
                                            },
                                            selector: (_, provider) =>
                                                provider.isProgress,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      child: Row(children: <Widget>[
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(start: 15.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  usedBal > 0
                                                      ? getPriceFormat(
                                                          context, totalPrice)!
                                                      : isStorePickUp == "false"
                                                          ? '${getPriceFormat(context, (totalPrice + delCharge))!} '
                                                          : getPriceFormat(
                                                              context,
                                                              totalPrice)!,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                    "${cartList.length} Items"),
                                              ],
                                            )),
                                        const Spacer(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10.0),
                                          child: SimBtn(
                                              height: 35,
                                              width: 0.4,
                                              title: getTranslated(
                                                  context, 'PLACE_ORDER'),
                                              onBtnSelected: /*_placeOrder
                                                  ?*/
                                                  () {
                                                checkoutState!(() {
                                                  _placeOrder = false;
                                                });

                                                if (isStorePickUp == "false" &&
                                                    (selAddress == "" ||
                                                        selAddress!.isEmpty)) {
                                                  msg = getTranslated(context,
                                                      'addressWarning');
                                                  Navigator.pushReplacement(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            ManageAddress(
                                                          home: false,
                                                          update:
                                                              updateCheckout,
                                                          updateProgress:
                                                              updateProgress,
                                                        ),
                                                      ));
                                                  checkoutState!(() {
                                                    _placeOrder = true;
                                                  });
                                                } else if (payMethod == null ||
                                                    payMethod!.isEmpty) {
                                                  msg = getTranslated(
                                                      context, 'payWarning');
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (BuildContext
                                                                  context) =>
                                                              Payment(
                                                                  updateCheckout,
                                                                  msg)));
                                                  checkoutState!(() {
                                                    _placeOrder = true;
                                                  });
                                                } else if (isTimeSlot! &&
                                                    (isLocalDelCharge == null ||
                                                        isLocalDelCharge!) &&
                                                    int.parse(allowDay!) > 0 &&
                                                    (selDate == null ||
                                                        selDate!.isEmpty) &&
                                                    IS_LOCAL_ON != '0') {
                                                  msg = getTranslated(
                                                      context, 'dateWarning');
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (BuildContext
                                                                  context) =>
                                                              Payment(
                                                                  updateCheckout,
                                                                  msg)));
                                                  checkoutState!(() {
                                                    _placeOrder = true;
                                                  });
                                                } else if (isTimeSlot! &&
                                                    (isLocalDelCharge == null ||
                                                        isLocalDelCharge!) &&
                                                    timeSlotList.isNotEmpty &&
                                                    (selTime == null ||
                                                        selTime!.isEmpty) &&
                                                    IS_LOCAL_ON != '0') {
                                                  msg = getTranslated(
                                                      context, 'timeWarning');
                                                  Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                          builder: (BuildContext
                                                                  context) =>
                                                              Payment(
                                                                  updateCheckout,
                                                                  msg)));
                                                  checkoutState!(() {
                                                    _placeOrder = true;
                                                  });
                                                } else if (double.parse(
                                                        MIN_ALLOW_CART_AMT!) >
                                                    oriPrice) {
                                                  setSnackbar(
                                                      getTranslated(context,
                                                          'MIN_CART_AMT')!,
                                                      context);
                                                } else if (isStorePickUp ==
                                                        "false" &&
                                                    !deliverable) {
                                                  checkDeliverable(1);
                                                } else {
                                                  if (confDia) {
                                                    setState(() {
                                                      confDia = false;
                                                    });
                                                    if (!context
                                                        .read<CartProvider>()
                                                        .isProgress) {
                                                      confirmDialog();
                                                    }
                                                  }
                                                }
                                              } /*: null*/),
                                        )
                                      ]),
                                    ),
                                  ],
                                )
                      : noInternet(context),
                ));
          });
        });
  }

  Future<void> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };

        apiBaseHelper.postAPICall(getAddressApi, parameter).then((getdata) {
          bool error = getdata["error"];

          if (!error) {
            var data = getdata["data"];

            addressList =
                (data as List).map((data) => User.fromAddress(data)).toList();

            if (addressList.length == 1) {
              selectedAddress = 0;
              selAddress = addressList[0].id;
              if (!ISFLAT_DEL) {
                if (totalPrice < double.parse(addressList[0].freeAmt!)) {
                  delCharge = double.parse(addressList[0].deliveryCharge!);
                } else {
                  delCharge = 0;
                }
              }
            } else {
              for (int i = 0; i < addressList.length; i++) {
                if (addressList[i].isDefault == "1") {
                  selectedAddress = i;
                  selAddress = addressList[i].id;
                  if (!ISFLAT_DEL) {
                    if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                      delCharge = double.parse(addressList[i].deliveryCharge!);
                    } else {
                      delCharge = 0;
                    }
                  }
                }
              }
            }

            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!)) {
                delCharge = double.parse(CUR_DEL_CHR!);
              } else {
                delCharge = 0;
              }
            }
          } else {
            if (ISFLAT_DEL) {
              if ((oriPrice) < double.parse(MIN_AMT!)) {
                delCharge = double.parse(CUR_DEL_CHR!);
              } else {
                delCharge = 0;
              }
            }
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          if (mounted) if (checkoutState != null) checkoutState!(() {});
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {}
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Map<String, dynamic> result =
        await updateOrderStatus(orderID: razorpayOrderId, status: PLACED);

    if (!result['error']) {
      await addTransaction(
          response.paymentId, razorpayOrderId, SUCCESS, rozorpayMsg, true);
    } else {
      setSnackbar('${result['message']}', context);
    }
    if (mounted) {
      context.read<CartProvider>().setProgress(false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    var getdata = json.decode(response.message!);
    String errorMsg = getdata['error']['description'];
    setSnackbar(errorMsg, context);
    deleteOrders(razorpayOrderId);
    if (mounted) {
      checkoutState!(() {
        _placeOrder = true;
      });
    }
    context.read<CartProvider>().setProgress(false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    //deleteOrders(razorpayOrderId);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      {required String status, required String orderID}) async {
    var parameter = {ORDER_ID: orderID, STATUS: status};
    var result = await ApiBaseHelper().postAPICall(updateOrderApi, parameter);
    return {'error': result['error'], 'message': result['message']};
  }

  updateCheckout() {
    if (mounted) checkoutState!(() {});
  }

  updateProgress(bool progress) {
    if (mounted) {
      checkoutState!(() {
        context.read<CartProvider>().setProgress(progress);
      });
    }
  }

  razorpayPayment(String orderID, String? msg) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    String? contact = settingsProvider.mobile;
    String? email = settingsProvider.email;

    String amt = ((usedBal > 0
                ? totalPrice
                : isStorePickUp == "false"
                    ? (totalPrice + delCharge)
                    : totalPrice) *
            100)
        .toStringAsFixed(2);

    if (contact != '' && email != '') {
      context.read<CartProvider>().setProgress(true);
      checkoutState!(() {});
      try {
        //create a razorpayOrder for capture payment automatically

        var response = await ApiBaseHelper()
            .postAPICall(createRazorpayOrder, {'order_id': orderID});
        var razorpayOrderID = response['data']['id'];

        var options = {
          KEY: razorpayId,
          AMOUNT: amt,
          NAME: settingsProvider.userName,
          'prefill': {CONTACT: contact, EMAIL: email},
          'order_id': razorpayOrderID,
        };

        razorpayOrderId = orderID;
        rozorpayMsg = msg;
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
        _razorpay!.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      if (email == '') {
        setSnackbar(getTranslated(context, 'emailWarning')!, context);
      } else if (contact == '') {
        setSnackbar(getTranslated(context, 'phoneWarning')!, context);
      }
    }
  }

  void paytmPayment(String? tranId, String orderID, String? status, String? msg,
      bool redirect) async {
    String? paymentResponse;
    context.read<CartProvider>().setProgress(true);

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl =
        '${payTesting ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in'}/theia/paytmCallback?ORDER_ID=$orderId';

    var parameter = {
      AMOUNT: usedBal > 0
          ? totalPrice.toString()
          : isStorePickUp == "false"
              ? (totalPrice + delCharge).toString()
              : totalPrice.toString(),
      USER_ID: CUR_USERID,
      ORDER_ID: orderId
    };

    try {
      apiBaseHelper.postAPICall(getPytmChecsumkApi, parameter).then((getdata) {
        bool error = getdata["error"];

        if (!error) {
          String txnToken = getdata["txn_token"];
          setState(() {
            paymentResponse = txnToken;
          });

          var paytmResponse = Paytm.payWithPaytm(
              callBackUrl: callBackUrl,
              mId: paytmMerId!,
              orderId: orderId,
              txnToken: txnToken,
              txnAmount: usedBal > 0
                  ? totalPrice.toString()
                  : isStorePickUp == "false"
                      ? (totalPrice + delCharge).toString()
                      : totalPrice.toString(),
              staging: payTesting);
          paytmResponse.then((value) {
            context.read<CartProvider>().setProgress(false);

            _placeOrder = true;
            setState(() {});
            checkoutState!(() async {
              if (value['error']) {
                paymentResponse = value['errorMessage'];

                if (value['response'] != "") {
                  // await updateOrderStatus(orderID: orderID,status: PLACED);
                  addTransaction(
                      value['response']['TXNID'],
                      orderID,
                      value['response']['STATUS'] ?? '',
                      paymentResponse,
                      false);
                }
              } else {
                if (value['response'] != "") {
                  paymentResponse = value['response']['STATUS'];
                  if (paymentResponse == "TXN_SUCCESS") {
                    //placeOrder(value['response']['TXNID']);
                    await updateOrderStatus(orderID: orderID, status: PLACED);
                    addTransaction(value['response']['TXNID'], orderID, SUCCESS,
                        msg, true);
                  } else {
                    deleteOrders(orderID);
                  }
                }
              }

              setSnackbar(paymentResponse!, context);
            });
          });
        } else {
          checkoutState!(() {
            _placeOrder = true;
          });

          context.read<CartProvider>().setProgress(false);

          setSnackbar(getdata["message"], context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> placeOrder(String? tranId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      context.read<CartProvider>().setProgress(true);

      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);

      String? mob = settingsProvider.mobile;

      String? varientId, quantity;

      List<SectionModel> cartList = context.read<CartProvider>().cartList;
      for (SectionModel sec in cartList) {
        varientId =
            varientId != null ? "$varientId,${sec.varientId!}" : sec.varientId;
        quantity = quantity != null ? "$quantity,${sec.qty!}" : sec.qty;
      }
      String? payVia;
      if (payMethod == getTranslated(context, 'COD_LBL')) {
        payVia = "COD";
      } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
        payVia = "PayPal";
      } else if (payMethod == getTranslated(context, 'PAYUMONEY_LBL')) {
        payVia = "PayUMoney";
      } else if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
        payVia = "RazorPay";
      } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
        payVia = "Paystack";
      } else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL')) {
        payVia = "Flutterwave";
      } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
        payVia = "Stripe";
      } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
        payVia = "Paytm";
      } else if (payMethod == "Wallet") {
        payVia = "Wallet";
      } else if (payMethod == getTranslated(context, 'BANKTRAN')) {
        payVia = "bank_transfer";
      } else if (payMethod == getTranslated(context, 'MIDTRANS_LBL')) {
        payVia = 'MidTrans';
      }

      var request = http.MultipartRequest("POST", placeOrderApi);
      request.headers.addAll(headers);

      try {
        request.fields[USER_ID] = CUR_USERID!;
        request.fields[MOBILE] = mob;
        request.fields[PRODUCT_VARIENT_ID] = varientId!;
        request.fields[QUANTITY] = quantity!;
        request.fields[TOTAL] = oriPrice.toString();
        request.fields[FINAL_TOTAL] = usedBal > 0
            ? totalPrice.toString()
            : isStorePickUp == "false"
                ? (totalPrice + delCharge).toString()
                : totalPrice.toString();

        request.fields[TAX_PER] = taxPer.toString();
        request.fields[PAYMENT_METHOD] = payVia!;

        request.fields[ISWALLETBALUSED] = isUseWallet! ? "1" : "0";
        request.fields[WALLET_BAL_USED] = usedBal.toString();
        request.fields[ORDER_NOTE] = noteC.text;

        if (IS_LOCAL_PICKUP != "1" || isStorePickUp != "true") {
          request.fields[ADD_ID] = selAddress!;
          request.fields[DEL_CHARGE] = delCharge.toString();
        }
        if (isTimeSlot!) {
          request.fields[DELIVERY_TIME] = selTime ?? 'Anytime';
          request.fields[DELIVERY_DATE] = selDate ?? '';
        }
        if (isPromoValid!) {
          request.fields[PROMOCODE] = promocode!;
          request.fields[PROMO_DIS] = promoAmt.toString();
        }

        if (IS_LOCAL_PICKUP == "1") {
          request.fields[LOCAL_PICKUP] = isStorePickUp == "true" ? "1" : "0";
        }

        if (payMethod == getTranslated(context, 'COD_LBL')) {
          request.fields[ACTIVE_STATUS] = PLACED;
        } else {
          request.fields[ACTIVE_STATUS] = WAITING;
        }
        print("request field***${request.fields}");
        if (prescriptionImages.isNotEmpty) {
          for (var i = 0; i < prescriptionImages.length; i++) {
            final mimeType = lookupMimeType(prescriptionImages[i].path);

            var extension = mimeType!.split("/");

            var pic = await http.MultipartFile.fromPath(
              DOCUMENT,
              prescriptionImages[i].path,
              contentType: MediaType('image', extension[1]),
            );

            request.files.add(pic);
          }
        }

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);

        _placeOrder = true;
        print("response status code ***${response.statusCode}");
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            String orderId = getdata["order_id"].toString();
            if (payMethod == getTranslated(context, 'RAZORPAY_LBL')) {
              razorpayPayment(orderId, msg);
              //addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYPAL_LBL')) {
              paypalPayment(orderId);
            } else if (payMethod == getTranslated(context, 'STRIPE_LBL')) {
              stripePayment(stripePayId, orderId,
                  tranId == 'succeeded' ? PLACED : WAITING, msg, true);
              // addTransaction(stripePayId, orderId,
              //  tranId == "succeeded" ? PLACED : WAITING, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYSTACK_LBL')) {
              paystackPayment(context, tranId, orderId, SUCCESS, msg, true);
              // addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'PAYTM_LBL')) {
              paytmPayment(tranId, orderId, SUCCESS, msg, true);
              //addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'FLUTTERWAVE_LBL')) {
              flutterwavePayment(tranId, orderId, SUCCESS, msg, true);
              // addTransaction(tranId, orderId, SUCCESS, msg, true);
            } else if (payMethod == getTranslated(context, 'MIDTRANS_LBL')) {
              midTrasPayment(
                  orderId, tranId == 'succeeded' ? PLACED : WAITING, msg, true);
            } else {
              context.read<UserProvider>().setCartCount("0");

              clearAll();

              Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(
                      builder: (BuildContext context) => const OrderSuccess()),
                  ModalRoute.withName('/home'));
            }
          } else {
            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        if (mounted) {
          checkoutState!(() {
            _placeOrder = true;
          });
        }
        context.read<CartProvider>().setProgress(false);
      }
    } else {
      if (mounted) {
        checkoutState!(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderId,
        AMOUNT: usedBal > 0
            ? totalPrice.toString()
            : isStorePickUp == "false"
                ? (totalPrice + delCharge).toString()
                : totalPrice.toString()
      };
      apiBaseHelper.postAPICall(paypalTransactionApi, parameter).then(
          (getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          String? data = getdata["data"];
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (BuildContext context) => PaypalWebview(
                        url: data,
                        from: "order",
                        orderId: orderId,
                      )));
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
  }

  Future<void> addTransaction(String? tranId, String orderID, String? status,
      String? msg, bool redirect) async {
    try {
      var parameter = {
        USER_ID: CUR_USERID,
        ORDER_ID: orderID,
        TYPE: payMethod,
        TXNID: tranId,
        AMOUNT: usedBal > 0
            ? totalPrice.toString()
            : isStorePickUp == "false"
                ? (totalPrice + delCharge).toString()
                : totalPrice.toString(),
        STATUS: status,
        MSG: msg
      };
      apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg1 = getdata["message"];
        if (!error) {
          if (redirect) {
            context.read<UserProvider>().setCartCount("0");
            clearAll();

            Navigator.pushAndRemoveUntil(
                context,
                CupertinoPageRoute(
                    builder: (BuildContext context) => const OrderSuccess()),
                ModalRoute.withName('/home'));
          }
        } else {
          setSnackbar(msg1!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  Future<void> deleteOrders(String orderId) async {
    try {
      var parameter = {
        ORDER_ID: orderId,
      };

      apiBaseHelper.postAPICall(deleteOrderApi, parameter).then((getdata) {
        if (mounted) {
          setState(() {});
        }

        Navigator.of(context).pop();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);

      setState(() {});
    }
  }

  paystackPayment(
    BuildContext context,
    String? tranId,
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    context.read<CartProvider>().setProgress(true);
    await paystackPlugin.initialize(publicKey: paystackId!);
    String? email = context.read<SettingProvider>().email;

    Charge charge = Charge()
      ..amount = totalPrice.toInt()
      ..reference = _getReference()
      ..putMetaData('order_id', orderID)
      ..email = email;

    try {
      CheckoutResponse response = await paystackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );
      if (response.status) {
        // placeOrder(response.reference);
        Map<String, dynamic> result =
            await updateOrderStatus(orderID: orderID, status: PLACED);
        addTransaction(response.reference, orderID, SUCCESS, msg, true);
      } else {
        deleteOrders(orderID);
        setSnackbar(response.message, context);
        if (mounted) {
          setState(() {
            _placeOrder = true;
          });
        }
        context.read<CartProvider>().setProgress(false);
      }
    } catch (e) {
      context.read<CartProvider>().setProgress(false);
      rethrow;
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  midTrasPayment(
    String orderID,
    String? status,
    String? msg,
    bool redirect,
  ) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        var parameter = {
          AMOUNT: ((usedBal > 0
                          ? totalPrice
                          : isStorePickUp == "false"
                              ? (totalPrice + delCharge)
                              : totalPrice)
                      .toInt() *
                  100)
              .toString(),
          USER_ID: CUR_USERID,
          ORDER_ID: orderID
        };
        apiBaseHelper.postAPICall(createMidtransTransactionApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['data'];
              String token = data['token'];
              String redirectUrl = data['redirect_url'];
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (BuildContext context) => MidTrashWebview(
                    url: redirectUrl,
                    from: 'order',
                    orderId: orderID,
                  ),
                ),
              ).then(
                (value) async {
                  _isNetworkAvail = await isNetworkAvailable();
                  if (_isNetworkAvail) {
                    try {
                      context.read<CartProvider>().setProgress(true);
                      var parameter = {
                        ORDER_ID: orderID,
                      };
                      apiBaseHelper
                          .postAPICall(
                              getMidtransTransactionStatusApi, parameter)
                          .then(
                        (getdata) async {
                          bool error = getdata['error'];
                          String? msg = getdata['message'];
                          var data = getdata['data'];
                          if (!error) {
                            String statuscode = data['status_code'];

                            if (statuscode == '404') {
                              deleteOrders(orderID);
                              if (mounted) {
                                setState(
                                  () {
                                    _placeOrder = true;
                                  },
                                );
                              }
                              context.read<CartProvider>().setProgress(false);
                            }

                            if (statuscode == '200') {
                              String transactionStatus =
                                  data['transaction_status'];
                              String transactionId = data['transaction_id'];
                              if (transactionStatus == 'capture') {
                                Map<String, dynamic> result =
                                    await updateOrderStatus(
                                        orderID: orderID, status: PLACED);
                                if (!result['error']) {
                                  await addTransaction(
                                    transactionId,
                                    orderID,
                                    SUCCESS,
                                    msg,
                                    true,
                                  );
                                } else {
                                  setSnackbar('${result['message']}', context);
                                }
                                if (mounted) {
                                  context
                                      .read<CartProvider>()
                                      .setProgress(false);
                                }
                              } else {
                                deleteOrders(orderID);
                                if (mounted) {
                                  setState(() {
                                    _placeOrder = true;
                                  });
                                }
                                context.read<CartProvider>().setProgress(false);
                              }
                            }
                          } else {
                            setSnackbar(msg!, context);
                          }

                          context.read<CartProvider>().setProgress(false);
                        },
                        onError: (error) {
                          setSnackbar(error.toString(), context);
                        },
                      );
                    } on TimeoutException catch (_) {
                      context.read<CartProvider>().setProgress(false);
                      setSnackbar(
                          getTranslated(context, 'somethingMSg')!, context);
                    }
                  } else {
                    if (mounted) {
                      setState(() {
                        _isNetworkAvail = false;
                      });
                    }
                  }
                  if (value == 'true') {
                    setState(
                      () {
                        _placeOrder = true;
                      },
                    );
                  } else {}
                },
              );
            } else {
              setSnackbar(msg!, context);
            }
            context.read<CartProvider>().setProgress(false);
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
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
  }

  stripePayment(String? tranId, String orderID, String? status, String? msg,
      bool redirect) async {
    context.read<CartProvider>().setProgress(true);

    var response = await StripeService.payWithPaymentSheet(
        amount: ((usedBal > 0
                        ? totalPrice
                        : isStorePickUp == "false"
                            ? (totalPrice + delCharge)
                            : totalPrice)
                    .toInt() *
                100)
            .toString(),
        currency: stripeCurCode,
        from: "order",
        context: context,
        awaitedOrderId: orderID);

    if (response.message == "Transaction successful") {
      // placeOrder(response.status);
      await updateOrderStatus(orderID: orderID, status: PLACED);
      addTransaction(stripePayId, orderID,
          tranId == 'succeeded' ? PLACED : WAITING, msg, true);
    } else if (response.status == 'pending' || response.status == "captured") {
      //deleteOrders(orderID);
      //placeOrder(response.status);
      await updateOrderStatus(orderID: orderID, status: WAITING);
      addTransaction(stripePayId, orderID,
          tranId == 'succeeded' ? PLACED : WAITING, msg, true);
    } else {
      deleteOrders(orderID);
      if (mounted) {
        setState(() {
          _placeOrder = true;
        });
      }

      context.read<CartProvider>().setProgress(false);
    }
    setSnackbar(response.message!, context);
  }

  address() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      getTranslated(context, 'SHIPPING_DETAIL') ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.fontColor),
                    )),
              ],
            ),
            const Divider(),
            addressList.isNotEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child:
                                    Text(addressList[selectedAddress!].name!)),
                            InkWell(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  getTranslated(context, 'CHANGE')!,
                                  style: const TextStyle(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                await Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (BuildContext context) =>
                                                ManageAddress(
                                                    home: false,
                                                    update: updateCheckout,
                                                    updateProgress:
                                                        updateProgress)))
                                    .then((value) {
                                  checkoutState!(() {
                                    deliverable = false;
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                        Text(
                          "${addressList[selectedAddress!].address!}, ${addressList[selectedAddress!].area!}, ${addressList[selectedAddress!].city!}, ${addressList[selectedAddress!].state!}, ${addressList[selectedAddress!].country!}, ${addressList[selectedAddress!].pincode!}",
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              color: Theme.of(context).colorScheme.lightBlack),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            children: [
                              Text(
                                addressList[selectedAddress!].mobile!,
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: InkWell(
                      child: Text(
                        getTranslated(context, 'ADDADDRESS')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
                      onTap: () async {
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => AddAddress(
                                    update: false,
                                    index: addressList.length,
                                  )),
                        ).then((value) async {
                          //await getShipRocketDeliveryCharge();
                        });
                        if (mounted) setState(() {});
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  payment() {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () async {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          msg = '';
          await Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (BuildContext context) =>
                      Payment(updateCheckout, msg)));
          if (mounted) checkoutState!(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.payment),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Text(
                      getTranslated(context, 'SELECT_PAYMENT')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              payMethod != null && payMethod != ''
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [const Divider(), Text(payMethod!)],
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  cartItems(List<SectionModel> cartList) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: cartList.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return cartItem(index, cartList);
      },
    );
  }

  orderSummary(List<SectionModel> cartList) {
    return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${getTranslated(context, 'ORDER_SUMMARY')!} (${cartList.length} items)",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    '${getPriceFormat(context, oriPrice)!} ',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              if (isStorePickUp == "false")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, 'DELIVERY_CHARGE')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      '${getPriceFormat(context, delCharge)!} ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              if (IS_SHIPROCKET_ON == "1" &&
                  isStorePickUp == "false" &&
                  shipRocketDeliverableDate != "" &&
                  !isLocalDelCharge!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, 'DELIVERY_DAY_LBL')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      shipRocketDeliverableDate,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              isPromoValid!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'PROMO_CODE_DIS_LBL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          '${getPriceFormat(context, promoAmt)!} ',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  : Container(),
              isUseWallet!
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, 'WALLET_BAL')!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2),
                        ),
                        Text(
                          '${getPriceFormat(context, usedBal)!} ',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  : Container(),
            ],
          ),
        ));
  }

  Future<void> validatePromo(bool check) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        if (check) {
          if (mounted && checkoutState != null) checkoutState!(() {});
        }
        setState(() {});
        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: oriPrice.toString()
        };
        apiBaseHelper.postAPICall(validatePromoApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];

            totalPrice = double.parse(data["final_total"]);

            promoAmt = double.parse(data["final_discount"]);

            promocode = data["promo_code"];

            isPromoValid = true;
            isPromoLen = false;
            setSnackbar(getTranslated(context, 'PROMO_SUCCESS')!, context);
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;
            promoC.clear();
            isPromoLen = false;
            var data = getdata["data"];

            totalPrice = double.parse(data["final_total"]);

            setSnackbar(msg!, context);
          }
          if (isUseWallet!) {
            remWalBal = 0;
            payMethod = null;
            usedBal = 0;
            isUseWallet = false;
            isPayLayShow = true;

            selectedMethod = null;
            context.read<CartProvider>().setProgress(false);
            if (mounted && check) checkoutState!(() {});
            setState(() {});
          } else {
            if (mounted && check) checkoutState!(() {});
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        if (mounted && check) checkoutState!(() {});
        setState(() {});
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      _isNetworkAvail = false;
      if (mounted && check) checkoutState!(() {});
      setState(() {});
    }
  }

  Future<void> flutterwavePayment(String? tranId, String orderID,
      String? status, String? msg, bool redirect) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          AMOUNT: usedBal > 0
              ? totalPrice.toString()
              : isStorePickUp == "false"
                  ? (totalPrice + delCharge).toString()
                  : totalPrice.toString(),
          USER_ID: CUR_USERID,
          ORDER_ID: orderID
        };
        apiBaseHelper.postAPICall(flutterwaveApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];

            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (BuildContext context) => PaypalWebview(
                          url: data,
                          from: "order",
                          orderId: orderID,
                        ))).then(
              (value) {
                if (value == 'true') {
                  //     addTransaction(tranId, orderID, SUCCESS, msg, true);

                  checkoutState!(
                    () {
                      _placeOrder = true;
                    },
                  );
                  //   setState(() {});
                } else {
                  deleteOrders(orderID);
                }
              },
            );
          } else {
            setSnackbar(msg!, context);
          }

          context.read<CartProvider>().setProgress(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        checkoutState!(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void confirmDialog() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  elevation: 2.0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                            child: Text(
                              getTranslated(context, 'CONFIRM_ORDER')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, 'SUBTOTAL')!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack2),
                                  ),
                                  Text(
                                    getPriceFormat(context, oriPrice)!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              if (isStorePickUp == "false")
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, 'DELIVERY_CHARGE')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack2),
                                    ),
                                    Text(
                                      getPriceFormat(context, delCharge)!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                              isPromoValid!
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(
                                              context, 'PROMO_CODE_DIS_LBL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack2),
                                        ),
                                        Text(
                                          getPriceFormat(context, promoAmt)!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : Container(),
                              isUseWallet!
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, 'WALLET_BAL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .lightBlack2),
                                        ),
                                        Text(
                                          getPriceFormat(context, usedBal)!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : Container(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, 'TOTAL_PRICE')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack2),
                                    ),
                                    Text(
                                      usedBal > 0
                                          ? getPriceFormat(context, totalPrice)!
                                          : isStorePickUp == "false"
                                              ? '${getPriceFormat(context, (totalPrice + delCharge))!} '
                                              : getPriceFormat(
                                                  context, totalPrice)!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: TextField(
                                    controller: noteC,
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10),
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor:
                                          colors.primary.withOpacity(0.1),
                                      hintText: getTranslated(context, 'NOTE'),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ]),
                  actions: <Widget>[
                    TextButton(
                        child: Text(getTranslated(context, 'CANCEL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          checkoutState!(() {
                            _placeOrder = true;
                            isPromoValid = false;
                          });
                          Navigator.pop(context);
                        }),
                    TextButton(
                        child: Text(getTranslated(context, 'DONE')!,
                            style: const TextStyle(
                                color: colors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);

                          if (payMethod == getTranslated(context, 'BANKTRAN')) {
                            bankTransfer();
                          } else {
                            placeOrder('');
                          }
                        })
                  ],
                )),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        }).then((value) => setState(() {
          confDia = true;
        }));
  }

  void bankTransfer() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Transform.scale(
            scale: a1.value,
            child: Opacity(
                opacity: a1.value,
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(0),
                  elevation: 2.0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                            child: Text(
                              getTranslated(context, 'BANKTRAN')!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )),
                        Divider(
                            color: Theme.of(context).colorScheme.lightBlack),
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: Text(getTranslated(context, 'BANK_INS')!,
                                style: Theme.of(context).textTheme.caption)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10),
                          child: Text(
                            getTranslated(context, 'ACC_DETAIL')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            "${getTranslated(context, 'ACCNAME')!} : ${acName!}",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            "${getTranslated(context, 'ACCNO')!} : ${acNo!}",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            "${getTranslated(context, 'BANKNAME')!} : ${bankName!}",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            "${getTranslated(context, 'BANKCODE')!} : ${bankNo!}",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Text(
                            "${getTranslated(context, 'EXTRADETAIL')!} : ${exDetails!}",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        )
                      ]),
                  actions: <Widget>[
                    TextButton(
                        child: Text(getTranslated(context, 'CANCEL')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          checkoutState!(() {
                            _placeOrder = true;
                          });
                          Navigator.pop(context);
                        }),
                    TextButton(
                        child: Text(getTranslated(context, 'DONE')!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);

                          context.read<CartProvider>().setProgress(true);

                          placeOrder('');
                        })
                  ],
                )),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        });
  }

  Future<void> checkDeliverable(int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          USER_ID: CUR_USERID,
          ADD_ID: selAddress,
        };
        apiBaseHelper.postAPICall(checkCartDelApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          var data = getdata["data"];
          context.read<CartProvider>().setProgress(false);

          if (error) {
            deliverableList = (data as List)
                .map((data) => Model.checkDeliverable(data))
                .toList();

            checkoutState!(() {
              deliverable = false;
              _placeOrder = true;
            });

            setSnackbar(msg!, context);
            context.read<CartProvider>().setProgress(false);
          } else {
            deliverableList = (data as List)
                .map((data) => Model.checkDeliverable(data))
                .toList();

            bool isDeliverible = false;
            bool? isShipRocket;
            for (int i = 0; i < deliverableList.length; i++) {
              if (deliverableList[i].isDel == false) {
                isDeliverible = false;
                break;
              } else {
                isDeliverible = true;
                if (deliverableList[i].delBy == "standard_shipping") {
                  isShipRocket = true;
                }
              }
            }

            if (isDeliverible) {
              getShipRocketDeliveryCharge(
                  isShipRocket != null && isShipRocket ? "1" : "0", from);
            }
            context.read<CartProvider>().setProgress(false);
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
  }

  attachPrescriptionImages(List<SectionModel> cartList) {
    bool isAttachReq = false;
    for (int i = 0; i < cartList.length; i++) {
      if (cartList[i].productList![0].is_attch_req == "1") {
        isAttachReq = true;
      }
    }
    return ALLOW_ATT_MEDIA == "1" && isAttachReq
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'ADD_ATT_REQ')!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack),
                      ),
                      SizedBox(
                        height: 30,
                        child: IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              color: colors.primary,
                              size: 20.0,
                            ),
                            onPressed: () {
                              _imgFromGallery();
                            }),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                        start: 20.0, end: 20.0, top: 5),
                    height: prescriptionImages.isNotEmpty ? 180 : 0,
                    child: Row(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: prescriptionImages.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            return InkWell(
                              child: Stack(
                                alignment: AlignmentDirectional.topEnd,
                                children: [
                                  Image.file(
                                    prescriptionImages[i],
                                    width: 180,
                                    height: 180,
                                  ),
                                  Container(
                                      color:
                                          Theme.of(context).colorScheme.black26,
                                      child: const Icon(
                                        Icons.clear,
                                        size: 15,
                                      ))
                                ],
                              ),
                              onTap: () {
                                checkoutState!(() {
                                  prescriptionImages.removeAt(i);
                                });
                              },
                            );
                          },
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  _imgFromGallery() async {
    var result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);
    if (result != null) {
      checkoutState!(() {
        prescriptionImages = result.paths.map((path) => File(path!)).toList();
      });
    } else {
      // User canceled the picker
    }
  }
}
