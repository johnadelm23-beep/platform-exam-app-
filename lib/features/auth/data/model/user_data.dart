class UserData {
  String? name;
  String? email;
  bool? isAdmin;
  String? password;
  bool? isBlock;

  UserData.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    email = json["email"];
    isAdmin = json["isAdmin"];
    password = json["password"];
    isBlock = json["isBlocked"];
  }
}
