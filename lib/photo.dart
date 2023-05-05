import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable(explicitToJson: true)
class Photo {
  final int id;
  final String url;
  String? portrait;
  @JsonKey(includeToJson: false)
  final Src? src;

  Photo({required this.id, required this.url, required this.src});

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'url': url,
        'portrait': src?.portrait,
      };
}

@JsonSerializable()
class Src {
  final String original;
  final String large;
  final String medium;
  final String small;
  final String portrait;

  Src({
    required this.original,
    required this.large,
    required this.medium,
    required this.small,
    required this.portrait,
  });

  factory Src.fromJson(Map<String, dynamic> json) => _$SrcFromJson(json);

  Map<String, dynamic> toJson() => _$SrcToJson(this);
}
