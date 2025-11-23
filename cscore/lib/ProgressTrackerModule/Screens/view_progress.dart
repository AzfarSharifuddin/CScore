import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cscore/ProgressTrackerModule/Services/progress_service.dart';
import 'package:cscore/ProgressTrackerModule/Model/progress_record.dart';
import 'package:cscore/ProgressTrackerModule/Model/badge_model.dart';
import 'edit_progress_page.dart';
import 'add_learning_progress.dart';
import 'add_activity_progress.dart';

class ViewProgressScreen extends StatelessWidget {
  final ProgressService _progressService = ProgressService();

  ViewProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: Text("Login required")));
        }

        final userId = snapshot.data!.uid;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFF5F5F7),
            title: const Text(
              "My Progress",
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // 📌 Badges Section — Top of Progress Page
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: StreamBuilder<List<BadgeModel>>(
                  stream: _progressService.getUserBadges(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "No badges earned yet 🏆",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      );
                    }

                    final badges = snapshot.data!;
                    return SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: badges.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3))
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundImage:
                                      NetworkImage(badges[i].iconUrl),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  badges[i].title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 📈 Progress Records Section
              Expanded(child: _buildProgressBody(context, userId)),
            ],
          ),

          // ➕ Floating Add Button
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => Wrap(children: [
                  ListTile(
                    leading: const Icon(Icons.school_rounded),
                    title: const Text("Add Learning Progress"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddLearningProgressPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.fitness_center_rounded),
                    title: const Text("Add Activity Progress"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddActivityProgressPage()));
                    },
                  ),
                ]),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // 📄 Progress Records List
  Widget _buildProgressBody(BuildContext context, String userId) {
    return StreamBuilder<List<ProgressRecord>>(
      stream: _progressService.getCombinedProgress(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red)),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = snapshot.data!;
        if (progress.isEmpty) {
          return const Center(
            child: Text(
              "No progress yet.\nTap + to add your first record!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: progress.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final p = progress[i];
            final isLearning = p.type == 'learning';
            final isQuiz = p.type == 'quiz';

            Color statusColor;
            switch (p.status.toLowerCase()) {
              case 'completed':
                statusColor = Colors.green;
                break;
              case 'in progress':
                statusColor = Colors.orange;
                break;
              case 'not started':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.grey;
            }

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProgressPage(record: p)),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLearning
                            ? Icons.school_rounded
                            : isQuiz
                                ? Icons.quiz_rounded
                                : Icons.fitness_center_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.activityName,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (isLearning || isQuiz)
                              Text("Status: ${p.status}",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600))
                            else
                              Text("Score: ${p.score.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text("${p.completedAt}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ]),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Progress"),
                            content: const Text(
                                "Are you sure you want to delete this record? This action cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Delete",
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _progressService.deleteProgress(userId, p);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Progress deleted successfully"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
