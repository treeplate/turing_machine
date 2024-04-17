import 'dart:math';
import 'dart:typed_data';

abstract class Tape {
  int get bitsPerElement;

  bool read(int index);

  void write(int index, bool value);

  void loadIndex(int index);

  void loadStart();

  int parseSingleUnary(int index, {required int addend}) {
    int i = 0;
    while (!read(index)) {
      index += addend;
    }
    while (read(index)) {
      i++;
      index += addend;
      loadIndex(index);
    }
    return i;
  }
}

class Uint8ListTape extends Tape {
  Uint8List storage;
  Uint8ListTape(Uint8List input) : storage = input {}
  int get bitsPerElement => 8;

  String toStringBinary() =>
      "${storage.map((e) => e.toRadixString(2).padLeft(8, '0')).join()}";

  String toStringHex() =>
      "${storage.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}";

  String toString() => toStringBinary();

  bool read(int index) {
    int macroIndex = (index / 8).floor();
    int subIndex = index % 8;
    int macro = storage.elementAt(macroIndex);
    int subIndexAsDivisor = pow(2, 7 - subIndex).toInt();
    return (macro / subIndexAsDivisor).floor().isOdd;
  }

  void write(int index, bool value) {
    int macroIndex = (index / 8).floor();
    int subIndex = index % 8;
    int macro = storage.elementAt(macroIndex);
    int mask = pow(2, 7 - subIndex).toInt();
    if (value) {
      storage[macroIndex] = macro | mask;
    } else {
      storage[macroIndex] = macro & ~mask;
    }
  }

  void loadIndex(int index) {
    if (index ~/ 8 >= storage.length) {
      storage = Uint8List.fromList(storage + [0]);
    }
    if (index ~/ 8 >= storage.length) {
      throw Exception(
        "Need to allocate storage one uint8 at a time (tried to loadIndex $index)",
      );
    }
  }

  @override
  void loadStart() {
    storage.insert(0, 0);
  }
}
