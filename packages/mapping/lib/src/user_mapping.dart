import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

import 'mapping_exception.dart';

UserDto userToDto(User user) => UserDto(id: user.id.value, username: user.username, role: user.role.name);

User userFromDto(UserDto dto) =>
    User(id: UserId(dto.id), username: dto.username, role: enumByName(Role.values, dto.role, 'role'));

RiderDto riderToDto(Rider rider) => RiderDto(id: rider.id.value, number: rider.number, name: rider.name);

Rider riderFromDto(RiderDto dto) => Rider(id: RiderId(dto.id), number: dto.number, name: dto.name);

/// An enum value by its wire name, or a [MappingException].
T enumByName<T extends Enum>(List<T> values, String name, String what) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw MappingException('Nepoznata vrednost "$name" za $what.');
}
