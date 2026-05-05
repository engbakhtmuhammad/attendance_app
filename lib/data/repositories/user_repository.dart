import '../../models/user_model.dart';
import '../database/db_helper.dart';

class UserRepository {
  final DbHelper _db;
  UserRepository({DbHelper? db}) : _db = db ?? DbHelper.instance;

  Future<void> add(UserModel user) => _db.insertUser(user);
  Future<UserModel?> getById(String id) => _db.getUserById(id);
  Future<List<UserModel>> getPending() => _db.getUsersByStatus('pending');
  Future<List<UserModel>> getApproved() => _db.getUsersByStatus('approved');
  Future<List<UserModel>> getAll() => _db.getAllUsers();
  Future<void> approve(String id) => _db.updateUserStatus(id, 'approved');
  Future<void> reject(String id) => _db.updateUserStatus(id, 'blocked');
  Future<void> bindDevice(String id, String deviceId) =>
      _db.updateUserDeviceId(id, deviceId);
}
