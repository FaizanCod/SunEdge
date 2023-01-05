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
    this.distributorId = "",
    this.currentPreviousCpv = "",
    this.currentExclusivePv = 0,
    this.currentSelfPv = "",
    this.currentGroupPv = "",
    this.currentCpv = "",
    this.totalPv = "",
    this.actualPv = 0,
    this.nextLevel = "",
    this.shortPoints = 0,
    this.previousExclusivePv = 0,
    this.previousSelfPv = "",
    this.previousTotlaPv = "",
    this.lastMonthLevel = "",
    this.previousActualPv = 0,
  });

  final String status;
  final String? distributorId;
  final String? currentPreviousCpv;
  final int? currentExclusivePv;
  final String? currentSelfPv;
  final String? currentGroupPv;
  final String? currentCpv;
  final String? totalPv;
  final int? actualPv;
  final String? nextLevel;
  final int? shortPoints;
  final int? previousExclusivePv;
  final String? previousSelfPv;
  final String? previousTotlaPv;
  final String? lastMonthLevel;
  final int? previousActualPv;

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
