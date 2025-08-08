import 'dart:convert';
import 'dart:io';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class WalletService {
  static Wallet? _walletInstance;
  static Descriptor? _externalDescriptor;
  static Blockchain? _blockchain;
  static Mnemonic? _mnemonic;

  /// Creates a new wallet or returns existing wallet data.
  Future<Map<String, dynamic>> createBitcoinWallet(String? email, {Network network = Network.Testnet}) async {
    try {
      if (_walletInstance != null && _externalDescriptor != null && _blockchain != null) {
        return await _getWalletData(email);
      }

      // Generate new mnemonic
      _mnemonic = await Mnemonic.create(WordCount.Words12);
      print(_mnemonic);

      final descriptorSecretKey = await DescriptorSecretKey.create(
        network: network,
        mnemonic: _mnemonic!,
      );

      _externalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: network,
        keychain: KeychainKind.External,
      );

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
            stopGap: 10,
            timeout: 120,
          ),
        ),
      );

      // ⚠️ Unique DB name based on descriptor hash
      final descriptorString = await _externalDescriptor!.asString();
      final descriptorHash = sha256.convert(utf8.encode(descriptorString)).toString();
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/wallet-$descriptorHash.db';

      print("📁 DB Path: $dbPath");
      print("🧾 Descriptor: $descriptorString");
      print("🔐 Mnemonic: ${_mnemonic!.asString()}");


      // Create wallet using SQLite
      _walletInstance = await Wallet.create(
        descriptor: _externalDescriptor!,
        changeDescriptor: internalDescriptor,
        network: network,
        databaseConfig: DatabaseConfig.sqlite(
          config: SqliteDbConfiguration(path: dbPath),
        ),
      );

      await _walletInstance!.sync(_blockchain!);

      return await _getWalletData(email);
    } catch (e, stackTrace) {
      print('❌ Error in createBitcoinWallet: $e');
      print('📌 StackTrace: $stackTrace');
      throw Exception('Failed to create wallet: $e');
    }
  }

  /// Retrieve wallet data
  Future<Map<String, dynamic>> _getWalletData(String? email) async {
    if (_walletInstance == null || _externalDescriptor == null) {
      throw Exception('Wallet not initialized');
    }

    try {
      await _walletInstance!.sync(_blockchain!);
    } catch (e) {
      print('⚠️ Sync failed: $e');
    }

    final addressInfo = await _walletInstance!.getAddress(
      addressIndex: AddressIndex.lastUnused(),
    );

    final balance = await _walletInstance!.getBalance();

    final transactions = await _walletInstance!.listTransactions(true);

    final bitcoinTransactionHistory = transactions.map((tx) {
      return {
        'txid': tx.txid,
        'type': 'bitcoin',
        'received': tx.received,
        'sent': tx.sent,
        'fee': tx.fee ?? 0,
        'timestamp': tx.confirmationTime?.timestamp ?? 0,
        'confirmed': tx.confirmationTime != null,
      };
    }).toList();

    return {
      'email': email,
      'bitcoin_address': addressInfo.address.toString(),
      'bitcoin_descriptor': await _externalDescriptor!.asString(),
      'mnemonic': _mnemonic?.asString(),
      'balance_sats': balance.total.toInt(),
      'transaction_history': bitcoinTransactionHistory,
    };
  }

  void resetWallet() {
    _walletInstance = null;
    _externalDescriptor = null;
    _blockchain = null;
    _mnemonic = null;
    print('🔄 Wallet instance reset successfully');
  }


    Future<String> getLocalDbPath(String descriptor) async {
  final hash = sha256.convert(utf8.encode(descriptor)).toString();
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/wallet-$hash.db';
}
  Future<Map<String, dynamic>> loadExistingWallet(String? email,String db_path, String mnemonic, {Network network = Network.Testnet}) async {
  try {
    // Regenerate mnemonic and descriptor
    print('🧠 Mnemonic passed in: "$mnemonic"');
    final _mnemonic = await Mnemonic.fromString(mnemonic);
    print('🧠 Mnemonic Recived in: "$_mnemonic"');
    print(db_path);
    final descriptorSecretKey = await DescriptorSecretKey.create(
      network: network,
      mnemonic: _mnemonic,
    );

    _externalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.External,
    );

    final internalDescriptor = await Descriptor.newBip84(
      secretKey: descriptorSecretKey,
      network: network,
      keychain: KeychainKind.Internal,
    );

    

    _blockchain ??= await Blockchain.create(
      config: BlockchainConfig.esplora(
        config: EsploraConfig(
          baseUrl: 'https://mempool.space/testnet/api',
          stopGap: 10,
          timeout: 120,
        ),
      ),
    );
    final db_pathload = await getLocalDbPath(db_path);

    _walletInstance = await Wallet.create(
      descriptor: _externalDescriptor!,
      changeDescriptor: internalDescriptor,
      network: network,
      databaseConfig: DatabaseConfig.sqlite(
        config: SqliteDbConfiguration(path: db_pathload),
      ),
    );

    await _walletInstance!.sync(_blockchain!);

    return await _getWalletData(email);
  } catch (e, stack) {
    print('❌ Failed to load existing wallet: $e');
    print('📌 Stack: $stack');
    throw Exception('Failed to load wallet for $email');
  }
}

}
