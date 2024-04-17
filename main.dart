import 'dart:math';
import 'dart:typed_data';

import 'tape.dart';

/* UN*2 (multiply a unary number by two):
[
TickResult(0, false, true, false),
TickResult(1, false, true, false),
TickResult(2, true, false, false),
TickResult(1, true, true, false),
TickResult(3, false, true, false),
TickResult(4, false, true, false),
TickResult(0, true, true, true),
TickResult(3, true, true, false),
TickResult(5, true, false, false),
TickResult(4, true, true, false),
TickResult(2, true, false, false),
TickResult(5, true, false, false),
]
*/
// XN*2 (multiply an extended binary number by two): parseTM(10389728107)
void main() {
  Uint8ListTape tape = Uint8ListTape(Uint8List.fromList([0x1F, 0xFF]));
  Device device = Device(
    parseTM(11)!,
    tape,
  );
  print(device.internalStates.join('  '));
}

List<TickResult>? parseTM(int n) {
  List<TickResult> states = [TickResult(0, false, true, false)];
  List<int> contracted = contract(n, true);
  StringBuffer newStateAndNewMark = StringBuffer();
  void emitState(bool isRight, bool isStop) {
    String nsanm = newStateAndNewMark.toString();
    bool newMark = nsanm.length >= 1 ? nsanm[nsanm.length - 1] == '1' : false;
    int newState = nsanm.length >= 2
        ? int.parse(nsanm.substring(0, nsanm.length - 1), radix: 2)
        : 0;
    states.add(TickResult(newState, newMark, isRight, isStop));
    newStateAndNewMark = StringBuffer();
  }

  for (int x in contracted) {
    switch (x) {
      case 0:
        newStateAndNewMark.write(0);
        break;
      case 1:
        newStateAndNewMark.write(1);
        break;
      case 2:
        emitState(true, false);
        break;
      case 3:
        emitState(false, false);
        break;
      case 4:
        emitState(true, true);
        break;
      default:
        print(x);
        return null;
    }
  }
  return states;
}

List<int> contract(int expanded, bool add110) {
  print(expanded);
  int index = 0;
  int onesSoFar = 0;
  List<int> contracted = [];
  for (; index < 64; index++) {
    int subIndexAsDivisor = pow(2, 63 - index).toInt();
    bool currentBit = (expanded / subIndexAsDivisor).floor().isOdd;
    if (currentBit) {
      onesSoFar++;
    } else {
      contracted.add(onesSoFar);
      onesSoFar = 0;
    }
  }
  if (add110) {
    onesSoFar += 2;
    contracted.add(onesSoFar);
  }

  return contracted;
}

class TickResult {
  final int newState;
  final bool newMark;
  final bool isRight;
  final bool isStop;

  TickResult(
    this.newState,
    this.newMark,
    this.isRight,
    this.isStop,
  );

  String toString() =>
      "${newState.toRadixString(2)}${newMark ? 1 : 0}${isRight ? 'R' : 'L'}${isStop ? '.STOP' : ''}";
}

class Device {
  final List<TickResult> internalStates;
  final Tape tape;
  int index = 0;
  int state = 0;

  void right() {
    index++;
    tape.loadIndex(index);
  }

  void left() {
    if (index > 0) {
      index--;
    } else {
      index = tape.bitsPerElement - 1;
      tape.loadStart();
    }
  }

  Device(this.internalStates, this.tape);
  bool tick() {
    bool currentMark = tape.read(index);
    int rI = state * 2 + (currentMark ? 1 : 0);
    TickResult action = internalStates[rI];
    //print('${state.toRadixString(2)}${currentMark ? 1 : 0} -> $action (#$rI)');
    state = action.newState;
    tape.write(index, action.newMark);
    action.isRight ? right() : left();
    return !action.isStop;
  }

  Tape compute() {
    while (tick()) {}
    return tape;
  }
}
