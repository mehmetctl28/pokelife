import 'package:flutter/material.dart';
import 'package:pokelife/core/theme/app_colors.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool t1 = false, t2 = false, t3 = false;
  int energy = 3, stress = 2, sleep = 4;
  
  // Klavyeden girilen yazıyı tutacak kontrolcü (Controller)
  final TextEditingController _noteController = TextEditingController(
      text: 'Bugun ders calismak\nbekledigimden kolaydi.');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildTask(String title, int xp, bool done, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          border: Border.all(color: AppColors.cream, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box : Icons.check_box_outline_blank,
              color: done ? AppColors.green : AppColors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: done ? AppColors.blue : AppColors.cream,
                  fontSize: 9,
                  decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
            Text(
              '+$xp XP',
              style: TextStyle(
                color: done ? AppColors.green : AppColors.yellow,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRating(String title, int val, Function(int) onTapped) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.cream, fontSize: 9)),
          Row(
            children: List.generate(5, (index) => GestureDetector(
              onTap: () => onTapped(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < val ? Icons.circle : Icons.circle_outlined,
                  color: AppColors.yellow,
                  size: 16,
                ),
              ),
            )),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('JOURNAL', style: TextStyle(color: AppColors.cream, fontSize: 16)),
          const SizedBox(height: 24),
          const Text('TODAY\'S TASKS', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 12),
          _buildTask('STUDY 25 MIN', 25, t1, () => setState(() => t1 = !t1)),
          _buildTask('WALK 3000 STEPS', 30, t2, () => setState(() => t2 = !t2)),
          _buildTask('30 MIN NO SCREEN', 15, t3, () => setState(() => t3 = !t3)),
          const SizedBox(height: 24),
          const Text('EVENING REFLECTION', style: TextStyle(color: AppColors.yellow, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              border: Border.all(color: AppColors.cream, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRating('ENERGY', energy, (v) => setState(() => energy = v)),
                _buildRating('STRESS', stress, (v) => setState(() => stress = v)),
                _buildRating('SLEEP ', sleep, (v) => setState(() => sleep = v)),
                const SizedBox(height: 8),
                const Text('NOTE:', style: TextStyle(color: AppColors.blue, fontSize: 9)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.blue)),
                  // Eski 'Text' yerine yazılabilir 'TextField' eklendi
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.cream, fontSize: 8),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Type your note here...',
                      hintStyle: TextStyle(color: AppColors.blue, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}