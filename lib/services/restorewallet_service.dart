


import 'package:bdk_flutter/bdk_flutter.dart';

class RestorewalletService {
  
Future<Map<String, dynamic>> restoreWallet(
  String mnemonicWords,
  String db_path,
  String email, {
  Network network = Network.Testnet,
}) async {
  try {
    // Convert the mnemonic phrase string into a Mnemonic object
    final mnemonic = await Mnemonic.fromString(mnemonicWords);
    print(mnemonic);
    // Create descriptor secret key from mnemonic
    final descriptorSecretKey = await DescriptorSecretKey.create(network: network, mnemonic: mnemonic);
    print(descriptorSecretKey);

    // Create external (receive) descriptor
    final externalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.External,
    );

    // Create internal (change) descriptor
    final internalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.Internal,
    );

    // Initialize blockchain with Esplora config (testnet)
    final blockchain = await Blockchain.create(
      config: BlockchainConfig.esplora(
        config: EsploraConfig(
          baseUrl: 'https://mempool.space/testnet/api',
          stopGap: 100,
          timeout: 50,
        ),
      ),
    );
  print(blockchain.toString());
    // Use provided db_path or memory DB (for persistence you want a path)
    final wallet = await Wallet.create(
      descriptor: externalDescriptor,
      changeDescriptor: internalDescriptor,
      network: network,
      databaseConfig: DatabaseConfig.memory() ,
      
    );
    print(wallet.toString());

    // Sync wallet with blockchain
    await wallet.sync(blockchain);

    // Gather wallet data
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
    print('❌ Failed to restore wallet: $e');
    print('📌 Stack: $stack');
    throw Exception('Failed to restore wallet for $email,try checking your internet connection while you restart this app');
  }
}

  }

  /// Retrieve wallet data
 