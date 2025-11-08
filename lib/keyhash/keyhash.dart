import 'dart:convert';
import 'dart:typed_data';
// import 'package:crypto/crypto.dart';

void main() {
  // SHA-1 của bạn (bỏ dấu :)
  String sha1 = 'D44908E936E6C6B198CAA77DAED9A61492BE68F4';
  
  // Convert hex to bytes
  List<int> bytes = [];
  for (int i = 0; i < sha1.length; i += 2) {
    bytes.add(int.parse(sha1.substring(i, i + 2), radix: 16));
  }
  
  // Base64 encode
  String keyHash = base64.encode(bytes);
  print('Facebook Key Hash: $keyHash');
}