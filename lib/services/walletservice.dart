import 'package:bdk_flutter/bdk_flutter.dart';

class WalletService {
  Future<Map<String, dynamic>> createBitcoinAndTronWallet(String? email) async {
    try {
      final mnemonic = await Mnemonic.create(WordCount.Words12);
      final descriptorSecretKey = await DescriptorSecretKey.create(
        network: Network.Testnet,
        mnemonic: mnemonic,
      );
      final externalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: Network.Testnet,
        keychain: KeychainKind.External,
      );
      final internalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: Network.Testnet,
        keychain: KeychainKind.Internal,
      );

      final blockchain = await Blockchain.create(
        config: BlockchainConfig.esplora(
          config: EsploraConfig(
            baseUrl: 'https://mempool.space/testnet/api',
            stopGap: 100,
            timeout: 120,
            
          ),
        ),
      );

      final wallet = await Wallet.create(
        descriptor: externalDescriptor,
        changeDescriptor: internalDescriptor,
        network: Network.Testnet,
        databaseConfig:DatabaseConfig.memory(),
      );

      await wallet.sync(blockchain);

      final addressInfo = await wallet.getAddress(
        addressIndex: AddressIndex.lastUnused(),
      );
      final balance = await wallet.getBalance();
      final transactions = await wallet.listTransactions(true);
      final bitcoinTransactionHistory = transactions
          .map(
            (tx) => {
              'txid': tx.txid,
              'type': 'bitcoin',
              'from': null, 
              'to': null, 
              'received': tx.received,
              'sent': tx.sent,
              'fee': tx.fee ?? 0,
              'timestamp': tx.confirmationTime?.timestamp ?? 0,
              'confirmed': tx.confirmationTime != null,
            },
          )
          .toList();
      final result = {
        'email': email,
        'bitcoin_address': addressInfo.address.toString(),
        'bitcoin_descriptor': await externalDescriptor.asString(),
        'mnemonic': mnemonic.asString(),
        'balance_sats': balance.total.toInt(),
        'transaction_history':bitcoinTransactionHistory,
      };

      print(" Wallet creation completed successfully");
      print(" Result keys: ${result.keys.toList()}");
      return result;
    } catch (e, stackTrace) {
      print(' Error in createBitcoinAndTronWallet: $e');
      print(' StackTrace: $stackTrace');

      if (e.toString().contains('Null check operator')) {
        throw Exception(
          'Null safety error in wallet creation. Check TronwalletAction implementation: $e',
        );
      }

      throw Exception('Failed to create wallet: $e');
    }
  }
}
