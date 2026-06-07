import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  test('packFrame prepends little-endian uint16 length', () {
    final opus = Uint8List.fromList([1, 2, 3]);
    final packed = AudioFrameProtocol.packFrame(opus);
    expect(packed, [3, 0, 1, 2, 3]); // length=3 LE
  });

  test('unpackFrames reverses packFrame for one frame', () {
    final opus = Uint8List.fromList([10, 20, 30, 40]);
    final packed = AudioFrameProtocol.packFrame(opus);
    final frames = AudioFrameProtocol.unpackFrames(packed);
    expect(frames.length, 1);
    expect(frames.first, opus);
  });

  test('unpackFrames splits multiple concatenated frames', () {
    final a = AudioFrameProtocol.packFrame(Uint8List.fromList([1, 1]));
    final b = AudioFrameProtocol.packFrame(Uint8List.fromList([2, 2, 2]));
    final packet = Uint8List.fromList([...a, ...b]);
    final frames = AudioFrameProtocol.unpackFrames(packet);
    expect(frames.map((f) => f.length), [2, 3]);
  });

  test('packFrame rejects empty input', () {
    expect(() => AudioFrameProtocol.packFrame(Uint8List(0)), throwsArgumentError);
  });

  test('unpackFrames throws on invalid length', () {
    final bad = Uint8List.fromList([255, 255, 1, 2]); // claims 65535 bytes
    expect(() => AudioFrameProtocol.unpackFrames(bad), throwsA(isA<ProtocolException>()));
  });

  test('unpackFrames throws on trailing bytes', () {
    final a = AudioFrameProtocol.packFrame(Uint8List.fromList([9]));
    final packet = Uint8List.fromList([...a, 7]); // 1 byte thừa
    expect(() => AudioFrameProtocol.unpackFrames(packet), throwsA(isA<ProtocolException>()));
  });
}
