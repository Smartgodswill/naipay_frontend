
import 'dart:convert';

import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
class RestorewalletService {
  static Wallet? _walletInstance;
  static Descriptor? _externalDescriptor;
  static Blockchain? _blockchain;


  Future<String> getLocalDbPath(String descriptor) async {
  final hash = sha256.convert(utf8.encode(descriptor)).toString();
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/wallet-$hash.db';
}
  /// Restore wallet from mnemonic and persist it
  Future<Map<String, dynamic>> restoreWallet(String mnemonicWords,String db_path, String email, {Network network = Network.Testnet}) async {
    try {
      // Check if wallet is already initialized
      if (_walletInstance != null && _externalDescriptor != null && _blockchain != null) {
        return await _getWalletData();
      }
      // Attempt to create mnemonic
      final mnemonic = await Mnemonic.fromString(mnemonicWords);
      print(mnemonic);
      final descriptorSecretKey = await DescriptorSecretKey.create(
        network: network,
        mnemonic: mnemonic,
      );

      // Create BIP-84 external descriptor
      _externalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: network,
        keychain: KeychainKind.External,
      );

      // Create BIP-84 internal descriptor (for change addresses)
      final internalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: network,
        keychain: KeychainKind.Internal,
      );

      // Initialize blockchain
      _blockchain = await Blockchain.create(
        config: BlockchainConfig.esplora(
          config: EsploraConfig(
            baseUrl: 'https://mempool.space/testnet/api',
            stopGap: 100,
            timeout: 120,
          ),
        ),
      );

      
     final db_pathRestore = await getLocalDbPath(db_path);
      // Create wallet
      _walletInstance = await Wallet.create(
        descriptor: _externalDescriptor!,
        changeDescriptor: internalDescriptor,
        network: network,
        databaseConfig: DatabaseConfig.sqlite(
          config: SqliteDbConfiguration(path:db_pathRestore)),
      
      );

      // Sync wallet with blockchain
      await _walletInstance!.sync(_blockchain!);

      return await _getWalletData();
    } catch (e, stackTrace) {
      // Improved error handling
      String errorMessage;
      if (e.toString().contains('mnemonic has an invalid word count')) {
        errorMessage = 'Invalid mnemonic phrase: Must contain 12, 15, 18, 21, or 24 words.';
      } else if (e.toString().contains('invalid mnemonic')) {
        errorMessage = 'Invalid mnemonic phrase: One or more words are not in the BIP-39 wordlist.';
      } else {
        errorMessage = 'Failed to restore wallet: $e';
      }
      print('Error restoring wallet: $e');
      print('StackTrace: $stackTrace');
      throw Exception(errorMessage);
    }
  }

  /// Retrieve wallet data
  Future<Map<String, dynamic>> _getWalletData() async {
    if (_walletInstance == null || _externalDescriptor == null) {
      throw Exception('Wallet is not initialized');
    }

    final addressInfo = await _walletInstance!.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );
    final balance = await _walletInstance!.getBalance();
    final transactions = await _walletInstance!.listTransactions(true);

    final bitcoinTransactionHistory = transactions.map((tx) => {
          'txid': tx.txid,
          'type': 'bitcoin',
          'received': tx.received,
          'sent': tx.sent,
          'fee': tx.fee ?? 0,
          'timestamp': tx.confirmationTime?.timestamp ?? 0,
          'confirmed': tx.confirmationTime != null,
        }).toList();

    return {
      'bitcoin_address': addressInfo.address.toString(),
      'bitcoin_descriptor': await _externalDescriptor!.asString(),
      'balance_sats': balance.total.toInt(),
      'transaction_history': bitcoinTransactionHistory,
    };
  }

  /// Reset wallet instance (use this on logout or app restart)
  void resetWallet() {
    _walletInstance = null;
    _externalDescriptor = null;
    _blockchain = null;
    print('Wallet instance reset successfully');
  }
}