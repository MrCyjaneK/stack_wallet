import 'dart:typed_data';

import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

class BitcoinFrost extends FrostCurrency {
  BitcoinFrost(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.bitcoinFrost;
      case CryptoCurrencyNetwork.test:
        coin = Coin.bitcoinFrostTestNet;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  bool get torSupport => true;

  @override
  NodeModel get defaultNode {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return DefaultNodes.bitcoin;

      case CryptoCurrencyNetwork.test:
        return DefaultNodes.bitcoinTestnet;

      default:
        throw UnimplementedError();
    }
  }

  @override
  String get genesisHash {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        return "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f";
      case CryptoCurrencyNetwork.test:
        return "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943";
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  Amount get dustLimit => Amount(
        rawValue: BigInt.from(294),
        fractionDigits: fractionDigits,
      );

  @override
  String pubKeyToScriptHash({required Uint8List pubKey}) {
    try {
      return Bip39HDCurrency.convertBytesToScriptHash(pubKey);
    } catch (e) {
      rethrow;
    }
  }

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress for frost addresses
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is BitcoinFrost && other.network == network;
  }

  @override
  int get hashCode => Object.hash(BitcoinFrost, network);
}
