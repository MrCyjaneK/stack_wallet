/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

final pSendAmount = StateProvider.autoDispose<Amount?>((_) => null);
final pValidSendToAddress = StateProvider.autoDispose<bool>((_) => false);
final pValidSparkSendToAddress = StateProvider.autoDispose<bool>((_) => false);

final pPreviewTxButtonEnabled =
    Provider.autoDispose.family<bool, Coin>((ref, coin) {
  final amount = ref.watch(pSendAmount) ?? Amount.zero;

  // TODO [prio=low]: move away from Coin
  if (coin == Coin.firo || coin == Coin.firoTestNet) {
    if (ref.watch(publicPrivateBalanceStateProvider) == FiroType.lelantus) {
      return ref.watch(pValidSendToAddress) &&
          !ref.watch(pValidSparkSendToAddress) &&
          amount > Amount.zero;
    } else {
      return (ref.watch(pValidSendToAddress) ||
              ref.watch(pValidSparkSendToAddress)) &&
          amount > Amount.zero;
    }
  } else {
    return ref.watch(pValidSendToAddress) && amount > Amount.zero;
  }
});

final previewTokenTxButtonStateProvider = StateProvider.autoDispose<bool>((_) {
  return false;
});
