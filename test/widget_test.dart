import 'package:flutter_test/flutter_test.dart';

import 'package:unican/models/verification_case.dart';

void main() {
  test('buildUntracedRemarks includes address and reason', () {
    final c = VerificationCase(address: '123 Test Street')
      ..reasonOfUntraced = 'Address is incomplete'
      ..requireToTrace = 'Required landmark'
      ..callingResponse = 'Number was not reachable'
      ..lastLocation = 'Unknown';

    final remarks = c.buildUntracedRemarks();

    expect(remarks.contains('123 Test Street'), isTrue);
    expect(remarks.contains('Address is incomplete'), isTrue);
  });

  test('buildConfirmedRemarks includes neighbor confirmation', () {
    final c = VerificationCase(address: '123 Test Street')
      ..neighbor1 = 'Neighbor A'
      ..neighbor2 = 'Neighbor B'
      ..metPersonName = 'Met Person'
      ..relationWithApplicant = 'Self'
      ..residenceConfirmation = 'Residing here'
      ..tenureOfResidence = '2 years'
      ..ownershipOfResidence = 'Owned'
      ..buildingDescription = 'Flat'
      ..totalFloors = 'Ground to 2nd'
      ..applicantFloor = '1st'
      ..landArea = '100'
      ..localityOfAddress = 'Middle class'
      ..documentShown = 'Aadhar card'
      ..totalFamilyMembers = '4'
      ..numberOfEarners = '2';

    final remarks = c.buildConfirmedRemarks();

    expect(remarks.contains('Neighbor A'), isTrue);
    expect(remarks.contains('Neighbor B'), isTrue);
  });
}
