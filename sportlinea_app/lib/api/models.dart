class Player {
  Player({
    required this.id,
    required this.email,
    required this.fullName,
    required this.balance,
    this.countryOfResidence,
  });

  final String id;
  final String email;
  final String fullName;
  final double balance;
  final String? countryOfResidence;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        countryOfResidence: json['countryOfResidence']?.toString(),
      );
}

class Outcome {
  Outcome({required this.id, required this.title, required this.value});

  final int id;
  final String title;
  final double value;

  factory Outcome.fromJson(Map<String, dynamic> json) => Outcome(
        id: (json['id'] as num).toInt(),
        title: json['outcomeDescription']?.toString() ?? '',
        value: (json['value'] as num).toDouble(),
      );
}

class SportEventDto {
  SportEventDto({
    required this.id,
    required this.title,
    required this.sportType,
    required this.sportCategory,
    required this.startDate,
    required this.status,
    required this.coefficients,
    this.result,
  });

  final int id;
  final String title;
  final String sportType;
  final String sportCategory;
  final DateTime startDate;
  final String status;
  final String? result;
  final List<Outcome> coefficients;

  factory SportEventDto.fromJson(Map<String, dynamic> json) => SportEventDto(
        id: (json['id'] as num).toInt(),
        title: json['title']?.toString() ?? '',
        sportType: json['sportType']?.toString() ?? '',
        sportCategory: json['sportCategory']?.toString() ?? '',
        startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
        status: json['status']?.toString() ?? '',
        result: json['result']?.toString(),
        coefficients: (json['coefficients'] as List<dynamic>? ?? [])
            .map((e) => Outcome.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BetDto {
  BetDto({
    required this.id,
    required this.eventTitle,
    required this.outcome,
    required this.amount,
    required this.coefficient,
    required this.winnings,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String eventTitle;
  final String outcome;
  final double amount;
  final double coefficient;
  final double winnings;
  final String status;
  final DateTime createdAt;

  factory BetDto.fromJson(Map<String, dynamic> json) => BetDto(
        id: (json['id'] as num).toInt(),
        eventTitle: json['eventTitle']?.toString() ?? '',
        outcome: json['outcomeDescription']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        coefficient: (json['coefficientValue'] as num?)?.toDouble() ?? 0,
        winnings: (json['winnings'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  String get statusRu => switch (status) {
        'Accepted' => 'Принята',
        'Won' => 'Выигрыш',
        'Lost' => 'Проигрыш',
        'Cancelled' => 'Отмена',
        _ => status,
      };
}
