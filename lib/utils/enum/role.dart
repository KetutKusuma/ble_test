// ignore_for_file: constant_identifier_names

enum Role {
  GUEST,
  ADMIN,
  OPERATOR,
  NONE,
  FORGETPASSWORD,
}

/// admin
List<Role> featureA = [Role.ADMIN];

/// admin dan operator
List<Role> featureB = [Role.ADMIN, Role.OPERATOR];

/// admin, operator, guest
List<Role> featureC = [Role.ADMIN, Role.OPERATOR, Role.GUEST];

/// admin, operator, guest, none
List<Role> featureD = [Role.ADMIN, Role.OPERATOR, Role.GUEST, Role.NONE];
