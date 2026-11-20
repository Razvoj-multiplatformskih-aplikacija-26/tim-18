import 'package:contract/contract.dart';
import 'package:domain/domain.dart';

StandingDto standingToDto(RiderStanding standing, {required bool longLap}) =>
    StandingDto(riderId: standing.riderId.value, points: standing.points, longLap: longLap);

RiderStanding standingFromDto(StandingDto dto) => RiderStanding(riderId: RiderId(dto.riderId), points: dto.points);
