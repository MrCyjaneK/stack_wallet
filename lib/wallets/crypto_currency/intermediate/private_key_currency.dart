import 'dart:typed_data';

import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

abstract class FrostCurrency extends CryptoCurrency {
  FrostCurrency(super.network);

  String pubKeyToScriptHash({required Uint8List pubKey});

  Amount get dustLimit;
}
