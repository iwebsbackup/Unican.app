/// Holds all data collected across the residence verification flow.
/// Passed by reference between screens; each screen fills in its part.
class VerificationCase {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
  final DateTime createdAt = DateTime.now();
  bool isFavorite = false;

  String address;

  double? latitude;
  double? longitude;
  final List<String> photoPaths = [];

  bool? traced; // true = Traced, false = Untraced

  // ---- Branch A: Untraced ----
  String reasonOfUntraced = '';
  String requireToTrace = '';
  String callingResponse = '';
  String lastLocation = '';
  String untracedComments = '';

  // ---- Branch B: Traced — neighbor step ----
  String neighbor1 = '';
  String neighbor2 = '';
  bool? neighborConfirmed; // true = confirmed, false = not confirmed

  // ---- Branch B1: Neighbor confirmed ----
  String metPersonName = '';
  String relationWithApplicant = '';
  String residenceConfirmation = '';
  String tenureOfResidence = '';
  String ownershipOfResidence = '';
  String rentAmount = '';
  String landlordName = '';
  String buildingDescription = '';
  String totalFloors = '';
  String applicantFloor = '';
  String landArea = '';
  String localityOfAddress = '';
  String documentShown = '';
  String totalFamilyMembers = '';
  String numberOfEarners = '';
  String verifierComments = '';
  bool? applicantResidingThere;

  // ---- Branch B2: Neighbor not confirmed ----
  String whoIsThat = '';
  String residenceConfirmationB2 = '';
  String totalFloorsB2 = '';
  String addressFloorB2 = '';
  String landAreaB2 = '';
  String localityB2 = '';
  String commentsB2 = '';

  String generatedRemarks = '';
  String finalStatus = '';

  VerificationCase({required this.address});

  String get geoTagText => (latitude == null || longitude == null)
      ? 'Not captured'
      : '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';

  String get _mediaSuffix =>
      '\n\nGeo-tag: $geoTagText. Photos attached: ${photoPaths.length}.';

  String buildConfirmedRemarks() {
    return 'Visited at given address ($address) we met with met person name '
        '($relationWithApplicant), who confirmed that applicant is '
        '$residenceConfirmation from last $tenureOfResidence in '
        '$ownershipOfResidence premises.'
        '${rentAmount.isNotEmpty ? ' If rented, paid rent amount $rentAmount to $landlordName.' : ''} '
        'Applicant is residing in $buildingDescription. Building is built '
        'from $totalFloors and applicant resides on $applicantFloor with an '
        'area approx. $landArea in $localityOfAddress locality. Document '
        'shown by met person: $documentShown. Total family members: '
        '$totalFamilyMembers, of which $numberOfEarners are earners.\n\n'
        'Neighbor confirmation: We met with $neighbor1 and $neighbor2, both '
        'confirmed the applicant\'s name and residence.$_mediaSuffix';
  }

  String buildNotConfirmedRemarks() {
    return 'Visited at given address ($address) we met with met person name '
        '($whoIsThat), who confirmed that applicant is '
        '$residenceConfirmationB2. Building is built from $totalFloorsB2 '
        'and premises exist at $addressFloorB2 with an area approx. '
        '$landAreaB2 in $localityB2 locality.\n\n'
        'Neighbor confirmation: We met with $neighbor1 and $neighbor2, both '
        'stated they could not confirm the applicant regarding the address.$_mediaSuffix';
  }

  String buildUntracedRemarks() {
    return 'Visited at given address ($address) but the address could not '
        'be traced. Reason: $reasonOfUntraced. Additional information '
        'required: $requireToTrace. Calling response: $callingResponse. '
        'Last known location: $lastLocation.$_mediaSuffix';
  }
}