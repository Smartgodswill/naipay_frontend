import 'package:bdk_flutter/bdk_flutter.dart';

class WalletService {
  // 🔹 Singleton Electrum instance
  static Blockchain? _electrumBlockchain;

  // 🔹 Initialize Electrum blockchain client
  Future<void> initBlockchain(Network network) async {
    if (_electrumBlockchain != null) return;

    final electrumUrl = network == Network.Testnet
        ? "ssl://electrum.blockstream.info:60002"
        : "ssl://electrum.blockstream.info:50002";

    _electrumBlockchain = await Blockchain.create(
      config: BlockchainConfig.electrum(
        config: ElectrumConfig(
          url: electrumUrl,
          socks5: null,
          retry: 5,
          timeout: 10, stopGap: 20, validateDomain: true,
        ),
      ),
    );
  }

  // 🔹 Create a new Bitcoin wallet
  Future<Map<String, dynamic>> createBitcoinWallet(
      String email, Network network) async {
    await initBlockchain(network);

    final mnemonics = await Mnemonic.create(WordCount.Words12);
    final secretKey = await DescriptorSecretKey.create(
      network: network,
      mnemonic: mnemonics,
    );

    final externalDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.External,
    );
    final internalDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.Internal,
    );

    final wallet = await Wallet.create(
      descriptor: externalDescriptor,
      changeDescriptor: internalDescriptor,
      network: network,
      databaseConfig: DatabaseConfig.memory(),
    );

    await wallet.sync(_electrumBlockchain!);

    final balance = await wallet.getBalance();
    final address =
        await wallet.getAddress(addressIndex: AddressIndex.lastUnused());
    final txHistory = await wallet.listTransactions(true);

    return {
      'mnemonic': mnemonics.toString(),
      'bitcoin_descriptor': await externalDescriptor.asString(),
      'balance_sats': balance.confirmed,
      'bitcoin_address': address.address,
      'transaction_history': txHistory,
    };
  }

  // 🔹 Load existing wallet
  Future<Map<String, dynamic>> loadExistingWallet(
      String email, String mnemonicString, Network network) async {
    await initBlockchain(network);

    final mnemonic = await Mnemonic.fromString(mnemonicString);
    final secretKey =
        await DescriptorSecretKey.create(network: network, mnemonic: mnemonic);

    final externalDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.External,
    );
    final internalDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.Internal,
    );

    final wallet = await Wallet.create(
      descriptor: externalDescriptor,
      changeDescriptor: internalDescriptor,
      network: network,
      databaseConfig: DatabaseConfig.memory(),
    );

    await wallet.sync(_electrumBlockchain!);

    final balance = await wallet.getBalance();
    final address =
        await wallet.getAddress(addressIndex: AddressIndex.lastUnused());
    final txHistory = await wallet.listTransactions(true);

    return {
      'mnemonic': mnemonicString,
      'balance_sats': balance.confirmed,
      'bitcoin_address': address.address,
      'transaction_history': txHistory,
    };
  }

  // 🔹 Preview Transaction
 Future<Map<String, dynamic>> previewTransaction({
  required String userMnemonic,
  required String recipientAddress,
  required int amountInSats,
  Network network = Network.Testnet,
  double? feeRate,
}) async {
  await initBlockchain(network);

  if (amountInSats < 546) {
    throw Exception("Amount below dust limit (546 sats).");
  }

  // 🔹 Validate BTC address
  try {
    final address = await Address.create(address: recipientAddress);
  } catch (e) {
    throw Exception("Invalid Bitcoin address.");
  }

  final mnemonic = await Mnemonic.fromString(userMnemonic);
  final secretKey =
      await DescriptorSecretKey.create(network: network, mnemonic: mnemonic);

  final externalDescriptor = await Descriptor.newBip84(
    secretKey: secretKey,
    network: network,
    keychain: KeychainKind.External,
  );
  final internalDescriptor = await Descriptor.newBip84(
    secretKey: secretKey,
    network: network,
    keychain: KeychainKind.Internal,
  );

  final wallet = await Wallet.create(
    descriptor: externalDescriptor,
    changeDescriptor: internalDescriptor,
    network: network,
    databaseConfig: DatabaseConfig.memory(),
  );

  await wallet.sync(_electrumBlockchain!);

  final utxos = await wallet.listUnspent();
  if (utxos.isEmpty) {
    throw Exception('Wallet has no spendable UTXOs.');
  }

  final balance = await wallet.getBalance();
  if (balance.total < amountInSats) {
    throw Exception(
      "Insufficient funds: Available ${balance.total}, required $amountInSats",
    );
  }

  // Address already validated above
  final address = await Address.create(address: recipientAddress);
  final script = await address.scriptPubKey();
  final finalFeeRate = feeRate ?? await _fetchRecommendedFeeRate();

  final txBuilder = TxBuilder()
    ..addRecipient(script, amountInSats)
    ..feeRate(finalFeeRate);

  final txBuilderResult = await txBuilder.finish(wallet);
  final psbt = txBuilderResult.psbt;
  final feeAmount = await psbt.feeAmount();

  return {
    'psbt': psbt,
    'wallet': wallet,
    'blockchain': _electrumBlockchain,
    'fee': feeAmount?.toInt() ?? 0,
    'amount': amountInSats,
    'recipientAddress': recipientAddress,
  };
}


  // 🔹 Confirm Transaction
  Future<Map<String, dynamic>> confirmTransaction({
    required PartiallySignedTransaction psbt,
    required Wallet wallet,
    required Blockchain blockchain,
  }) async {
    final signedPsbt = await wallet.sign(psbt: psbt);
    final signedTx = await signedPsbt.extractTx();
    final txid = await signedTx.txid();
    final feeAmount = await signedPsbt.feeAmount();

    await blockchain.broadcast(signedTx);

    return {
      'txid': txid,
      'bitcoin_transaction_fee': feeAmount?.toInt() ?? 0,
    };
  }

 
Future<double> _fetchRecommendedFeeRate({int targetBlocks = 5}) async {
  try {
    // Ask Electrum for fee rate estimate
    final feeRate = await _electrumBlockchain!.estimateFee(targetBlocks);

    // Convert to sats/vbyte (make sure it's called as a function)
    final rate = feeRate.asSatPerVb();

    // Ensure the value is valid and not zero/negative
    if (rate > 0) {
      return rate;
    }
  } catch (e) {
    print("⚠️ Failed to fetch fee rate: $e");
  }

  // Fallback: safe low fee to avoid failures
  return 2.0; // sats/vbyte
}

}
