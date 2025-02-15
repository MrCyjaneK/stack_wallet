/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/aggregate_currency.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_provider_option.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/services/exchange/trocador/trocador_exchange.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ExchangeProviderOptions extends ConsumerStatefulWidget {
  const ExchangeProviderOptions({
    Key? key,
    required this.fixedRate,
    required this.reversed,
  }) : super(key: key);

  final bool fixedRate;
  final bool reversed;

  @override
  ConsumerState<ExchangeProviderOptions> createState() =>
      _ExchangeProviderOptionsState();
}

class _ExchangeProviderOptionsState
    extends ConsumerState<ExchangeProviderOptions> {
  final isDesktop = Util.isDesktop;

  bool exchangeSupported({
    required String exchangeName,
    required AggregateCurrency? sendCurrency,
    required AggregateCurrency? receiveCurrency,
  }) {
    // If using Tor, only allow exchanges that support it.
    if (Prefs.instance.useTor) {
      if (!Exchange.exchangeNamesWithTorSupport.contains(exchangeName)) {
        return false;
      }
    }

    final send = sendCurrency?.forExchange(exchangeName);
    if (send == null) return false;

    final rcv = receiveCurrency?.forExchange(exchangeName);
    if (rcv == null) return false;

    if (widget.fixedRate) {
      return send.supportsFixedRate && rcv.supportsFixedRate;
    } else {
      return send.supportsEstimatedRate && rcv.supportsEstimatedRate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendCurrency =
        ref.watch(efCurrencyPairProvider.select((value) => value.send));
    final receivingCurrency =
        ref.watch(efCurrencyPairProvider.select((value) => value.receive));

    final showChangeNow = exchangeSupported(
      exchangeName: ChangeNowExchange.exchangeName,
      sendCurrency: sendCurrency,
      receiveCurrency: receivingCurrency,
    );
    final showMajesticBank = exchangeSupported(
      exchangeName: MajesticBankExchange.exchangeName,
      sendCurrency: sendCurrency,
      receiveCurrency: receivingCurrency,
    );
    final showTrocador = exchangeSupported(
      exchangeName: TrocadorExchange.exchangeName,
      sendCurrency: sendCurrency,
      receiveCurrency: receivingCurrency,
    );

    return RoundedWhiteContainer(
      padding: isDesktop ? const EdgeInsets.all(0) : const EdgeInsets.all(12),
      borderColor: isDesktop
          ? Theme.of(context).extension<StackColors>()!.background
          : null,
      child: Column(
        children: [
          if (showChangeNow)
            ExchangeOption(
              exchange: ChangeNowExchange.instance,
              fixedRate: widget.fixedRate,
              reversed: widget.reversed,
            ),
          if (showChangeNow && showMajesticBank)
            isDesktop
                ? Container(
                    height: 1,
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                  )
                : const SizedBox(
                    height: 16,
                  ),
          if (showMajesticBank)
            ExchangeOption(
              exchange: MajesticBankExchange.instance,
              fixedRate: widget.fixedRate,
              reversed: widget.reversed,
            ),
          if ((showChangeNow || showMajesticBank) && showTrocador)
            isDesktop
                ? Container(
                    height: 1,
                    color:
                        Theme.of(context).extension<StackColors>()!.background,
                  )
                : const SizedBox(
                    height: 16,
                  ),
          if (showTrocador)
            ExchangeOption(
              fixedRate: widget.fixedRate,
              reversed: widget.reversed,
              exchange: TrocadorExchange.instance,
            ),
        ],
      ),
    );
  }
}
