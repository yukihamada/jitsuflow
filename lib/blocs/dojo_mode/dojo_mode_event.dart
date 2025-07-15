abstract class DojoModeEvent {}

class LoadDojoModeData extends DojoModeEvent {
  final int dojoId;
  
  LoadDojoModeData(this.dojoId);
}

class SwitchToDojoMode extends DojoModeEvent {}

class SwitchToUserMode extends DojoModeEvent {}

class ProcessPayment extends DojoModeEvent {
  final int dojoId;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final int? customerId;
  
  ProcessPayment({
    required this.dojoId,
    required this.items,
    required this.paymentMethod,
    this.customerId,
  });
}

class AddRentalTransaction extends DojoModeEvent {
  final int dojoId;
  final int rentalId;
  final int userId;
  final DateTime returnDueDate;
  
  AddRentalTransaction({
    required this.dojoId,
    required this.rentalId,
    required this.userId,
    required this.returnDueDate,
  });
}

class StartSparringRecording extends DojoModeEvent {
  final int dojoId;
  final int participant1Id;
  final int participant2Id;
  final String ruleSet;
  
  StartSparringRecording({
    required this.dojoId,
    required this.participant1Id,
    required this.participant2Id,
    required this.ruleSet,
  });
}

class StopSparringRecording extends DojoModeEvent {
  final int? winnerId;
  final String finishType;
  
  StopSparringRecording({
    this.winnerId,
    required this.finishType,
  });
}