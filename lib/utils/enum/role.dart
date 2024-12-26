// ignore_for_file: constant_identifier_names

enum Role {
  GUEST,
  ADMIN,
  OPERATOR,
  NONE,
}

List<Role> featureA = [Role.ADMIN];
List<Role> featureB = [Role.ADMIN, Role.OPERATOR];
List<Role> featureC = [Role.ADMIN, Role.OPERATOR, Role.GUEST];
List<Role> featureD = [Role.ADMIN, Role.OPERATOR, Role.GUEST, Role.NONE];
