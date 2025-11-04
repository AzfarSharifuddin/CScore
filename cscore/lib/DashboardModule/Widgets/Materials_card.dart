import 'package:flutter/material.dart';
import '../Models/Class_materials.dart';

class MaterialCard extends StatelessWidget {
  final ClassMaterial material;
  const MaterialCard({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          material.type == 'PDF' ? Icons.picture_as_pdf : Icons.video_library,
          color: Colors.blueGrey,
        ),
        title: Text(material.title),
        subtitle: Text(material.type),
        onTap: () {
          // Can open PDF or video later
        },
      ),
    );
  }
}

