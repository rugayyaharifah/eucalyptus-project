// lib/services/meal_plan_service.dart
import 'package:balanced_meal/models/meal_plan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MealPlan>> getCurrentWeekMealPlans(String userId) {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final start = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day); // force 00:00
    final end = start
        .add(const Duration(days: 7))
        .subtract(const Duration(seconds: 1)); // Sunday 23:59:59

    return _firestore
        .collection('mealPlans')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealPlan.fromMap(doc.data())).toList());
  }

  Future<void> saveMealPlan(MealPlan mealPlan) async {
    await _firestore
        .collection('mealPlans')
        .doc(mealPlan.id)
        .set(mealPlan.toMap());
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}
