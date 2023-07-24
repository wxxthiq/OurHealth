import 'dart:convert';
import 'autocomplete_prediction.dart';

class locationAutocompleteResponse {
  final String? status;
  final List<AutocompletePrediction>? predictions;

  locationAutocompleteResponse({this.status, this.predictions});

  factory locationAutocompleteResponse.fromJson(Map<String, dynamic> json){
    return locationAutocompleteResponse(
      status: json['status'] as String?,
      predictions: json['predictions'] != null ? json['predictions']
          .map<AutocompletePrediction>((json) => AutocompletePrediction.fromJson(json)).toList() : null,
    );
  }

  static locationAutocompleteResponse parseAutocompleteResult(String responseBody){
    final parsed = json.decode(responseBody).cast<String, dynamic>();

    return locationAutocompleteResponse.fromJson(parsed);
  }




}