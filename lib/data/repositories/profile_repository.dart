import '../../domain/models/user_model.dart';
import '../services/collab_note_service.dart';
import 'base_repository.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(this._service);

  final CollabNoteService _service;
  static const String _collection = 'user';

  UserModel _user = const UserModel(
    id: 'user-1',
    name: 'Mahasiswa',
    nim: '',
    university: '',
    faculty: '',
    studyProgram: '',
    semester: 1,
  );

  UserModel get user => _user;

  @override
  Future<void> loadData() async {
    final rows = await _service.fetchCollection(_collection);
    if (rows.isNotEmpty) _user = UserModel.fromJson(rows.first);
  }

  Future<void> update(UserModel user) async {
    _user = user;
    notifyListeners();
    await _service.saveCollection(_collection, [user.toJson()]);
  }
}
