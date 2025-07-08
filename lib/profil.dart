class ProfileModel {
  int? id;
  String? name;
  String? image64bit;

  ProfileModel({this.id, this.name, this.image64bit});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {"name": name, "image64bit": image64bit};

    if (id != null) {
      map["id"] = id;
    }

    return map;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
      id: map["id"], name: map["name"], image64bit: map["image64bit"]);
}
