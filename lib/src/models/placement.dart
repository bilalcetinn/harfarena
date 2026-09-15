import 'position.dart';

class Placement {
  const Placement({
    required this.position,
    required this.letter,
    this.isBlank = false,
  });

  final Position position;
  final String letter;
  final bool isBlank;

  Placement copyWith({bool? isBlank}) => Placement(
        position: position,
        letter: letter,
        isBlank: isBlank ?? this.isBlank,
      );

  @override
  String toString() => '${position.toString()}:$letter${isBlank ? "*" : ""}';
}
