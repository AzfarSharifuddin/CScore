import '../Models/Class_materials.dart';

class LocalDataService {
  // 📝 Class Materials (still useful for local/static materials)
  List<ClassMaterial> getMaterials() {
    return [
      ClassMaterial(
        title: 'CSS Layout Notes.pdf',
        type: 'PDF',
        link: 'assets/css_layout_notes.pdf',
      ),
      ClassMaterial(
        title: 'Python Loops Video',
        type: 'Video',
        link: 'https://example.com/python-loops',
      ),
    ];
  }
}
