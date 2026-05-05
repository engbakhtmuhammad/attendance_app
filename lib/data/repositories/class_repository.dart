import '../../models/class_model.dart';
import '../database/db_helper.dart';

class ClassRepository {
  final DbHelper _db;
  ClassRepository({DbHelper? db}) : _db = db ?? DbHelper.instance;

  Future<void> add(ClassModel cls) => _db.insertClass(cls);
  Future<List<ClassModel>> getAll() => _db.getAllClasses();
  Future<ClassModel?> getActive() => _db.getActiveClass();
  Future<void> startSession(String id, String token) =>
      _db.setClassActive(id, active: true, token: token);
  Future<void> stopSession() =>
      _db.setClassActive('', active: false);
  Future<void> delete(String id) => _db.deleteClass(id);
}
