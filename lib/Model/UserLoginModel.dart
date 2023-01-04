// To parse this JSON data, do
//
//     final userLoginData = userLoginDataFromJson(jsonString);

import 'dart:convert';

UserLoginData userLoginDataFromJson(String str) =>
    UserLoginData.fromJson(json.decode(str));

String userLoginDataToJson(UserLoginData data) => json.encode(data.toJson());

class UserLoginData {
  UserLoginData({
    required this.status,
    required this.distributorId,
    required this.currentPreviousCpv,
    required this.currentExclusivePv,
    required this.currentSelfPv,
    required this.currentGroupPv,
    required this.currentCpv,
    required this.totalPv,
    required this.actualPv,
    required this.nextLevel,
    required this.shortPoints,
    required this.previousExclusivePv,
    required this.previousSelfPv,
    required this.previousTotlaPv,
    required this.lastMonthLevel,
    required this.previousActualPv,
  });

  String status;
  String distributorId;
  String currentPreviousCpv;
  int currentExclusivePv;
  String currentSelfPv;
  String currentGroupPv;
  String currentCpv;
  String totalPv;
  int actualPv;
  String nextLevel;
  int shortPoints;
  int previousExclusivePv;
  String previousSelfPv;
  String previousTotlaPv;
  String lastMonthLevel;
  int previousActualPv;

  factory UserLoginData.fromJson(Map<String, dynamic> json) => UserLoginData(
        status: json["status"],
        distributorId: json["distributor_id"],
        currentPreviousCpv: json["current_previous_cpv"],
        currentExclusivePv: json["current_exclusive_pv"],
        currentSelfPv: json["current_self_pv"],
        currentGroupPv: json["current_group_pv"],
        currentCpv: json["current_cpv"],
        totalPv: json["total_pv"],
        actualPv: json["actual_pv"],
        nextLevel: json["next_level"],
        shortPoints: json["short_points"],
        previousExclusivePv: json["previous_exclusive_pv"],
        previousSelfPv: json["previous_self_pv"],
        previousTotlaPv: json["previous_totla_pv"],
        lastMonthLevel: json["last_month_level"],
        previousActualPv: json["previous_actual_pv"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "distributor_id": distributorId,
        "current_previous_cpv": currentPreviousCpv,
        "current_exclusive_pv": currentExclusivePv,
        "current_self_pv": currentSelfPv,
        "current_group_pv": currentGroupPv,
        "current_cpv": currentCpv,
        "total_pv": totalPv,
        "actual_pv": actualPv,
        "next_level": nextLevel,
        "short_points": shortPoints,
        "previous_exclusive_pv": previousExclusivePv,
        "previous_self_pv": previousSelfPv,
        "previous_totla_pv": previousTotlaPv,
        "last_month_level": lastMonthLevel,
        "previous_actual_pv": previousActualPv,
      };
}
