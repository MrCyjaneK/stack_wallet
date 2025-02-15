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
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class CurrencySettings extends ConsumerStatefulWidget {
  const CurrencySettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuCurrency";

  @override
  ConsumerState<CurrencySettings> createState() => _CurrencySettings();
}

Future<void> chooseCurrency(BuildContext context) async {
  await showDialog<dynamic>(
    context: context,
    useSafeArea: false,
    barrierDismissible: true,
    builder: (context) {
      return DesktopDialog(
        maxHeight: 800,
        maxWidth: 600,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Select currency",
                    style: STextStyles.desktopH3(context),
                    textAlign: TextAlign.center,
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            const Expanded(
              child: BaseCurrencySettingsView(),
            ),
          ],
        ),
      );
    },
  );
}

class _CurrencySettings extends ConsumerState<CurrencySettings> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            radiusMultiplier: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    Assets.svg.circleDollarSign,
                    width: 48,
                    height: 48,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Currency",
                            style: STextStyles.desktopTextSmall(context),
                          ),
                          TextSpan(
                            text:
                                "\n\nSelect a fiat currency to evaluate your crypto assets. We use CoinGecko conversion rates "
                                "when displaying your balance and transaction amounts.",
                            style:
                                STextStyles.desktopTextExtraExtraSmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                        10,
                      ),
                      child: PrimaryButton(
                        width: 200,
                        buttonHeight: ButtonHeight.m,
                        enabled: true,
                        label: "Change currency",
                        onPressed: () {
                          chooseCurrency(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
