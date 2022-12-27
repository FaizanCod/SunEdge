import '../Helper/String.dart';
import 'Section_Model.dart';

class SliderImages {
  String? id;
  String? style;
  String? offerIds;
  String? dateAdded;
  List<OfferImages>? offerImages;

  SliderImages(
      {this.id, this.style, this.offerIds, this.dateAdded, this.offerImages});

  factory SliderImages.fromJson(Map<String, dynamic> parsedJson) {
    List<OfferImages> offerList = (parsedJson[OFFER_IMAGES] as List)
        .map((data) => OfferImages.fromJson(data))
        .toList();

    return SliderImages(
        id: parsedJson[ID],
        style: parsedJson[STYLE],
        offerIds: parsedJson[OFFER_IDS],
        dateAdded: parsedJson[DATE_ADDED],
        offerImages: offerList);
  }
}

class OfferImages {
  String? id;
  String? type;
  String? typeId;
  String? minDiscount;
  String? maxDiscount;
  String? image;
  String? dateAdded;
  String? brandName;
  var data;

  OfferImages(
      {this.id,
      this.type,
      this.typeId,
      this.minDiscount,
      this.maxDiscount,
      this.image,
      this.dateAdded,
      this.data,
      this.brandName});

  factory OfferImages.fromJson(Map<String, dynamic> parsedJson) {

    var listContent = parsedJson["data"];

    if (listContent == null) {
      listContent = [];
    } else {
      if (parsedJson[TYPE] == "categories") {
        listContent = listContent[0];

        listContent = Product.fromCat(listContent);
      } else {
        listContent = listContent.map((data) => Data.fromJson(data)).toList();
      }
    }

    return OfferImages(
        id: parsedJson[ID],
        type: parsedJson[TYPE],
        typeId: parsedJson[TYPE_ID],
        minDiscount: parsedJson[MIN_DISC],
        maxDiscount: parsedJson[MAX_DISC],
        image: parsedJson[IMAGE],
        dateAdded: parsedJson[DATE_ADDED],
        brandName: parsedJson[DATE_ADDED],
        data:
            listContent
        );
  }
}

class Data {
  String? id;
  String? image;
  String? banner;
  String? name;


  Data({this.id, this.image, this.banner, this.name

      });

  factory Data.fromJson(Map<String, dynamic> parsedJson) {
    return Data(
      id: parsedJson[ID],
      image: parsedJson[IMAGE],
      name: parsedJson[NAME],
      banner: parsedJson[
          BANNER],
    );
  }


}


