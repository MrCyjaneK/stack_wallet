import 'dart:convert';

import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_dto.dart';
import 'package:stackwallet/dto/ethereum/eth_token_tx_extra_dto.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/utilities/extensions/impl/contract_abi.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/isar/models/token_wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class EthTokenWallet extends Wallet {
  @override
  int get isarTransactionVersion => 2;

  EthTokenWallet(this.ethWallet, this._tokenContract)
      : super(ethWallet.cryptoCurrency);

  final EthereumWallet ethWallet;

  EthContract get tokenContract => _tokenContract;
  EthContract _tokenContract;

  late web3dart.DeployedContract _deployedContract;
  late web3dart.ContractFunction _sendFunction;

  static const _gasLimit = 200000;

  // ===========================================================================

  // ===========================================================================

  Future<EthContract> _updateTokenABI({
    required EthContract forContract,
    required String usingContractAddress,
  }) async {
    final abiResponse = await EthereumAPI.getTokenAbi(
      name: forContract.name,
      contractAddress: usingContractAddress,
    );
    // Fetch token ABI so we can call token functions
    if (abiResponse.value != null) {
      final updatedToken = forContract.copyWith(abi: abiResponse.value!);
      // Store updated contract
      final id = await mainDB.putEthContract(updatedToken);
      return updatedToken..id = id;
    } else {
      throw abiResponse.exception!;
    }
  }

  String _addressFromTopic(String topic) =>
      checksumEthereumAddress("0x${topic.substring(topic.length - 40)}");

  // ===========================================================================

  @override
  FilterOperation? get changeAddressFilterOperation =>
      ethWallet.changeAddressFilterOperation;

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      ethWallet.receivingAddressFilterOperation;

  @override
  Future<void> init() async {
    try {
      await super.init();

      final contractAddress =
          web3dart.EthereumAddress.fromHex(tokenContract.address);

      if (tokenContract.abi == null) {
        _tokenContract = await _updateTokenABI(
          forContract: tokenContract,
          usingContractAddress: contractAddress.hex,
        );
      }

      try {
        // try parse abi and extract transfer function
        _deployedContract = web3dart.DeployedContract(
          ContractAbiExtensions.fromJsonList(
            jsonList: tokenContract.abi!,
            name: tokenContract.name,
          ),
          contractAddress,
        );
        _sendFunction = _deployedContract.function('transfer');
      } catch (_) {
        // some failure so first try to make sure we have the latest abi
        _tokenContract = await _updateTokenABI(
          forContract: tokenContract,
          usingContractAddress: contractAddress.hex,
        );

        try {
          // try again to parse abi and extract transfer function
          _deployedContract = web3dart.DeployedContract(
            ContractAbiExtensions.fromJsonList(
              jsonList: tokenContract.abi!,
              name: tokenContract.name,
            ),
            contractAddress,
          );
          _sendFunction = _deployedContract.function('transfer');
        } catch (_) {
          // if it fails again we check if there is a proxy token impl and
          // then try one last time to update and parse the abi
          final contractAddressResponse =
              await EthereumAPI.getProxyTokenImplementationAddress(
                  contractAddress.hex);

          if (contractAddressResponse.value != null) {
            _tokenContract = await _updateTokenABI(
              forContract: tokenContract,
              usingContractAddress: contractAddressResponse.value!,
            );
          } else {
            throw contractAddressResponse.exception!;
          }

          _deployedContract = web3dart.DeployedContract(
            ContractAbiExtensions.fromJsonList(
              jsonList: tokenContract.abi!,
              name: tokenContract.name,
            ),
            contractAddress,
          );

          _sendFunction = _deployedContract.function('transfer');
        }
      }
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType wallet failed init(): $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    final feeRateType = txData.feeRateType!;
    int fee = 0;
    final feeObject = await fees;
    switch (feeRateType) {
      case FeeRateType.fast:
        fee = feeObject.fast;
        break;
      case FeeRateType.average:
        fee = feeObject.medium;
        break;
      case FeeRateType.slow:
        fee = feeObject.slow;
        break;
      case FeeRateType.custom:
        throw UnimplementedError("custom eth token fees");
    }

    final feeEstimate = await estimateFeeFor(Amount.zero, fee);

    final client = ethWallet.getEthClient();

    final myAddress = (await getCurrentReceivingAddress())!.value;
    final myWeb3Address = web3dart.EthereumAddress.fromHex(myAddress);

    final nonce = txData.nonce ??
        await client.getTransactionCount(myWeb3Address,
            atBlock: const web3dart.BlockNum.pending());

    final amount = txData.recipients!.first.amount;
    final address = txData.recipients!.first.address;

    final tx = web3dart.Transaction.callContract(
      contract: _deployedContract,
      function: _sendFunction,
      parameters: [web3dart.EthereumAddress.fromHex(address), amount.raw],
      maxGas: _gasLimit,
      gasPrice: web3dart.EtherAmount.fromUnitAndValue(
        web3dart.EtherUnit.wei,
        fee,
      ),
      nonce: nonce,
    );

    return txData.copyWith(
      fee: feeEstimate,
      feeInWei: BigInt.from(fee),
      web3dartTransaction: tx,
      chainId: await client.getChainId(),
      nonce: tx.nonce,
    );
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      return await ethWallet.confirmSend(txData: txData);
    } catch (e) {
      // rethrow to pass error in alert
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    return ethWallet.estimateEthFee(
      feeRate,
      _gasLimit,
      cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees => EthereumAPI.getFees();

  @override
  Future<bool> pingCheck() async {
    return await ethWallet.pingCheck();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      throw Exception();
    } catch (_, s) {
      Logging.instance.log(
        "Eth token wallet recover called. This should not happen. Stacktrace: $s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final info = await mainDB.isar.tokenWalletInfo
          .where()
          .walletIdTokenAddressEqualTo(walletId, tokenContract.address)
          .findFirst();
      final response = await EthereumAPI.getWalletTokenBalance(
        address: (await getCurrentReceivingAddress())!.value,
        contractAddress: tokenContract.address,
      );

      if (response.value != null && info != null) {
        await info.updateCachedBalance(
          Balance(
            total: response.value!,
            spendable: response.value!,
            blockedTotal: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenContract.decimals,
            ),
            pendingSpendable: Amount(
              rawValue: BigInt.zero,
              fractionDigits: tokenContract.decimals,
            ),
          ),
          isar: mainDB.isar,
        );
      } else {
        Logging.instance.log(
          "CachedEthTokenBalance.fetchAndUpdateCachedBalance failed: ${response.exception}",
          level: LogLevel.Warning,
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType wallet failed to update balance: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateChainHeight() async {
    await ethWallet.updateChainHeight();
  }

  @override
  Future<void> updateTransactions() async {
    try {
      final String addressString =
          checksumEthereumAddress((await getCurrentReceivingAddress())!.value);

      final response = await EthereumAPI.getTokenTransactions(
        address: addressString,
        tokenContractAddress: tokenContract.address,
      );

      if (response.value == null) {
        if (response.exception != null &&
            response.exception!.message
                .contains("response is empty but status code is 200")) {
          Logging.instance.log(
            "No ${tokenContract.name} transfers found for $addressString",
            level: LogLevel.Info,
          );
          return;
        }
        throw response.exception ??
            Exception("Failed to fetch token transaction data");
      }

      // no need to continue if no transactions found
      if (response.value!.isEmpty) {
        return;
      }

      final response2 = await EthereumAPI.getEthTokenTransactionsByTxids(
        response.value!.map((e) => e.transactionHash).toSet().toList(),
      );

      if (response2.value == null) {
        throw response2.exception ??
            Exception("Failed to fetch token transactions");
      }
      final List<({EthTokenTxDto tx, EthTokenTxExtraDTO extra})> data = [];
      for (final tokenDto in response.value!) {
        try {
          final txExtra = response2.value!.firstWhere(
            (e) => e.hash == tokenDto.transactionHash,
          );
          data.add(
            (
              tx: tokenDto,
              extra: txExtra,
            ),
          );
        } catch (_) {
          // Server indexing failed for some reason. Instead of hard crashing or
          // showing no transactions we just skip it here. Not ideal but better
          // than nothing showing up
          Logging.instance.log(
            "Server error: Transaction ${tokenDto.transactionHash} not found.",
            level: LogLevel.Error,
          );
        }
      }

      final List<TransactionV2> txns = [];

      for (final tuple in data) {
        // ignore all non Transfer events (for now)
        if (tuple.tx.topics[0] == kTransferEventSignature) {
          final amount = Amount(
            rawValue: tuple.tx.data.toBigIntFromHex,
            fractionDigits: tokenContract.decimals,
          );

          if (amount.raw == BigInt.zero) {
            // probably don't need to show this
            continue;
          }

          final Amount txFee = tuple.extra.gasUsed * tuple.extra.gasPrice;
          final addressFrom = _addressFromTopic(
            tuple.tx.topics[1],
          );
          final addressTo = _addressFromTopic(
            tuple.tx.topics[2],
          );

          final TransactionType txType;
          if (addressTo == addressString) {
            if (addressFrom == addressTo) {
              txType = TransactionType.sentToSelf;
            } else {
              txType = TransactionType.incoming;
            }
          } else if (addressFrom == addressString) {
            txType = TransactionType.outgoing;
          } else {
            // ignore for now I guess since anything here is not reflected in
            // balance anyways
            continue;

            // throw Exception("Unknown token transaction found for "
            //     "${ethWallet.walletName} ${ethWallet.walletId}: "
            //     "${tuple.item1.toString()}");
          }

          final otherData = {
            "nonce": tuple.extra.nonce,
            "isCancelled": false,
            "overrideFee": txFee.toJsonString(),
            "contractAddress": tuple.tx.address,
          };

          // hack eth tx data into inputs and outputs
          final List<OutputV2> outputs = [];
          final List<InputV2> inputs = [];

          OutputV2 output = OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: "00",
            valueStringSats: amount.raw.toString(),
            addresses: [
              addressTo,
            ],
            walletOwns: addressTo == addressString,
          );
          InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: null,
            scriptSigAsm: null,
            sequence: null,
            outpoint: null,
            addresses: [addressFrom],
            valueStringSats: amount.raw.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: addressFrom == addressString,
          );

          outputs.add(output);
          inputs.add(input);

          final txn = TransactionV2(
            walletId: walletId,
            blockHash: tuple.extra.blockHash,
            hash: tuple.tx.transactionHash,
            txid: tuple.tx.transactionHash,
            timestamp: tuple.extra.timestamp,
            height: tuple.tx.blockNumber,
            inputs: List.unmodifiable(inputs),
            outputs: List.unmodifiable(outputs),
            version: -1,
            type: txType,
            subType: TransactionSubType.ethToken,
            otherData: jsonEncode(otherData),
          );

          txns.add(txn);
        }
      }
      await mainDB.updateOrPutTransactionV2s(txns);
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType wallet failed to update transactions: $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    await ethWallet.updateNode();
  }

  @override
  Future<bool> updateUTXOs() async {
    return await ethWallet.updateUTXOs();
  }

  @override
  FilterOperation? get transactionFilterOperation => FilterGroup.and([
        FilterCondition.equalTo(
          property: r"contractAddress",
          value: tokenContract.address,
        ),
        const FilterCondition.equalTo(
          property: r"subType",
          value: TransactionSubType.ethToken,
        ),
      ]);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    await ethWallet.checkSaveInitialReceivingAddress();
  }
}
