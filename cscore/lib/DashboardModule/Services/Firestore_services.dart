import '../Models/Class_materials.dart';
import '../Models/Activity.dart';

class LocalDataService {
  // Sample class materials
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

  // Sample activities
  List<Activity> getActivities() {
    return [
      Activity(
        title: 'Programming Assignment',
        date: 'Thu, Sep 5',
        notes: 'Submit via portal before midnight.',
      ),
      Activity(
        title: 'Web Dev Practice',
        date: 'Thu, Sep 5',
        notes: 'Review Python loops and HTML forms.',
      ),
    ];
  }
}
