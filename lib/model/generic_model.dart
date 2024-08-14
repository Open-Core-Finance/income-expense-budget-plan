abstract class GenericModel<T extends dynamic> {
  T? id;

  GenericModel({required this.id});

  String displayText();

  String idFieldName();

  Map<String, Object?> toMap();
}
