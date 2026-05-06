class UserData {
  String? name;
  String? email;
  String? password;
  bool? isAdmin;
  UserData.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    email = json["email"];
    password = json["password"];
    isAdmin = json["isAdmin"];
  }
}
