import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateWalletBloc  extends Cubit<bool>{
  CreateWalletBloc() : super(false);

  Future<void> createWallet(String password) async {
        final storage = new FlutterSecureStorage();

        await storage.write(key: "password", value: password);

        return emit(true);
}


  Future<void> storePasskey(List<String> passkey) async {
        final storage = new FlutterSecureStorage();

        await storage.write(key: "passkey", value: passkey.toString());

        return emit(true);
}
}


class PasskeyBloc  extends Cubit<List<String>>{
  PasskeyBloc() : super([]);
  
  Future<void> readPasskey() async {
        final storage = new FlutterSecureStorage();

        List<String> passkey = (await storage.read(key: "passkey")) as List<String>;

        return emit(passkey);
}
} 