import '../../models/admin_model.dart';
import '../database/db_helper.dart';

class AdminRepository {
  final DbHelper _db;
  AdminRepository({DbHelper? db}) : _db = db ?? DbHelper.instance;

  Future<AdminModel?> getById(String id) => _db.getAdminById(id);
  Future<List<AdminModel>> getAll() => _db.getAllAdmins();
  Future<void> add(AdminModel admin) => _db.insertAdmin(admin);
  Future<bool> idExists(String id) async {
    final a = await _db.getAdminById(id);
    return a != null;
  }
}
