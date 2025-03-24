/// A Student is a member of NTU and can use the library
class Student {
  final String uuid;
  final String account; // Student id
  final String name; // Full Name, sometimes redacted

  Student({required this.uuid, required this.account, required this.name});

  factory Student.fromJson(Map<String, dynamic> jsonObj) {
    return Student(
      uuid: jsonObj["uuid"],
      account: jsonObj["studentId"],
      name: jsonObj["name"],
    );
  }
  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'studentId': account,
    'name': name,
  };
}
