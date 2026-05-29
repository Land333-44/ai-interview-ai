import 'package:appwrite/appwrite.dart';
import '../core/appwrite_constants.dart';

class AppwriteService {
  static final AppwriteService instance = AppwriteService._internal();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Functions functions;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(
          status: true,
        ); // For self-hosted instances (optional but helpful)

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    functions = Functions(client);
  }
}
