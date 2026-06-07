import 'dart:typed_data';

class ProtocolException implements Exception {
  final String message;
  ProtocolException(this.message);
  @override
  String toString() => 'ProtocolException: $message';
}

/// Wire format: [uint16 LE length][opus payload], có thể nối nhiều frame.
class AudioFrameProtocol {
  static const int _prefixBytes = 2;
  static const int _maxOpusFrameBytes = 4096;

  static Uint8List packFrame(Uint8List opusFrame) {
    if (opusFrame.isEmpty) {
      throw ArgumentError('Opus frame must not be empty');
    }
    if (opusFrame.length > 0xFFFF) {
      throw ArgumentError('Opus frame is too large');
    }
    final out = Uint8List(_prefixBytes + opusFrame.length);
    final bd = ByteData.view(out.buffer);
    bd.setUint16(0, opusFrame.length, Endian.little);
    out.setRange(_prefixBytes, out.length, opusFrame);
    return out;
  }

  static List<Uint8List> unpackFrames(Uint8List packet) {
    final bd = ByteData.view(packet.buffer, packet.offsetInBytes, packet.length);
    final frames = <Uint8List>[];
    var pos = 0;
    while (packet.length - pos >= _prefixBytes) {
      final length = bd.getUint16(pos, Endian.little);
      pos += _prefixBytes;
      if (length <= 0 || length > _maxOpusFrameBytes || length > packet.length - pos) {
        throw ProtocolException('Invalid Opus frame length: $length');
      }
      frames.add(Uint8List.sublistView(packet, pos, pos + length));
      pos += length;
    }
    if (pos != packet.length) {
      throw ProtocolException('Trailing bytes after Opus frames: ${packet.length - pos}');
    }
    return frames;
  }
}
