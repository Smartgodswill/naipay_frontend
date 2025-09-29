


import 'package:bdk_flutter/bdk_flutter.dart';

class RestorewalletService {
  
Future<Map<String, dynamic>> restoreWallet(
  String mnemonicWords,
  String db_path,
  String email, {
  Network network = Network.Testnet,
}) async {
  try {
    final mnemonic = await Mnemonic.fromString(mnemonicWords);
    print(mnemonic);
    final descriptorSecretKey = await DescriptorSecretKey.create(network: network, mnemonic: mnemonic);
    print(descriptorSecretKey);

    final externalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.External,
    );

    final internalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.Internal,
    );

   final blockchain = await Blockchain.create(
  config: BlockchainConfig.electrum(
    config: ElectrumConfig(
      url: "ssl://electrum.blockstream.info:60002",
      retry: 5,
      timeout: 5,
      stopGap: 20, validateDomain: true,
    ),
  ),
);

  print(blockchain.toString());
    
final wallet = await Wallet.create(
  descriptor: externalDescriptor,
  changeDescriptor: internalDescriptor,
  network: network,
  databaseConfig:DatabaseConfig.memory()
);

    print(wallet.toString());

  try {
  await wallet.sync(blockchain);
} catch (e, st) {
  print("Wallet sync failed: $e");
  print("Stack: $st");
}
    final balance = await wallet.getBalance();
    final addressInfo = await wallet.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );
    final transactions = await wallet.listTransactions(true);

    // Return wallet info as map
    return {
      'mnemonic': mnemonicWords,
      'bitcoin_descriptor': await externalDescriptor.asString(),
      'balance_sats': balance.confirmed,
      'bitcoin_address': addressInfo.address,
      'transaction_history': transactions,
    };
  } catch (e, stack) {
    print('Failed to restore wallet: $e');
    print('Stack: $stack');
    throw Exception('Failed to restore wallet for $email,try checking your internet connection while you restart this app');
  }
}

  }

 