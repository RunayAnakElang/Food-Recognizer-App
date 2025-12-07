import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:submission/controller/result_controller.dart';
import 'package:submission/controller/home_controller.dart';
import 'package:submission/services/meal_service.dart';
import 'package:submission/ui/meal_detail_page.dart';
import 'package:submission/services/gemini_service.dart';

class ResultPage extends StatelessWidget {
  final File imageFile;

  const ResultPage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ResultController(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Classification Result'),
        ),
        body: SafeArea(child: _ResultBody(imageFile: imageFile)),
      ),
    );
  }
}

class _ResultBody extends StatefulWidget {
  final File imageFile;

  const _ResultBody({required this.imageFile});

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody> {
  final MealService _mealService = MealService();
  List<Meal> _relatedMeals = [];
  bool _isLoadingMeals = false;

  @override
  void initState() {
    super.initState();
    _runClassification();
  }

  bool _hasSearched = false;
  bool _hasFetchedNutrition = false;

  void _runClassification() {
    setState(() {
      _relatedMeals = [];
      _isLoadingMeals = false;
      _hasSearched = false;
      _hasFetchedNutrition = false;
    });

    Future.microtask(() {
      context.read<ResultController>().classifyImage(widget.imageFile);
    });
  }

  Future<void> _searchRelatedMeals(String foodName) async {
    if (foodName.toLowerCase() == 'not food' ||
        foodName.toLowerCase() == 'unknown' ||
        _hasSearched) {
      return;
    }

    setState(() {
      _isLoadingMeals = true;
      _hasSearched = true;
    });

    final meals = await _mealService.searchMealByName(foodName);

    setState(() {
      _relatedMeals = meals;
      _isLoadingMeals = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResultController>(
      builder: (context, controller, child) {
        if (controller.state == ResultState.success) {
          if (_relatedMeals.isEmpty && !_isLoadingMeals) {
            Future.microtask(() => _searchRelatedMeals(controller.foodName));
          }

          if (!_hasFetchedNutrition && !controller.isLoadingNutrition &&
              controller.foodName.toLowerCase() != 'not food' &&
              controller.foodName.toLowerCase() != 'unknown') {
            Future.microtask(() {
              _hasFetchedNutrition = true;
              controller.fetchNutritionalInfo();
            });
          }
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              _buildResultSection(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Image.file(
      widget.imageFile,
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildResultSection(ResultController controller) {
    final isNotFood = controller.foodName.toLowerCase() == 'not food';
    final isSuccess = controller.state == ResultState.success;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStateWidget(controller),

          if (isSuccess && !isNotFood)
            _buildNutritionSection(controller),

          if (isSuccess && !isNotFood)
            _buildRelatedMealsSection(),

          if (controller.state != ResultState.loading)
            const SizedBox(height: 24),
          if (isSuccess || controller.state == ResultState.error)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStateWidget(ResultController controller) {
    switch (controller.state) {
      case ResultState.loading:
        return _buildLoadingWidget();
      case ResultState.error:
        return _buildErrorWidget(controller.errorMessage);
      case ResultState.success:
        return _buildSuccessWidget(controller);
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Analyzing your food...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
        const SizedBox(height: 16),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage,
          style: TextStyle(color: Colors.red[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessWidget(ResultController controller) {
    final isNotFood = controller.foodName.toLowerCase() == 'not food';

    return Column(
      children: [
        if (isNotFood)
          _buildNotFoodWidget()
        else
          _buildFoodResultWidget(controller),
      ],
    );
  }

  Widget _buildNotFoodWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Not Food Detected',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Please try another image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodResultWidget(ResultController controller) {
    final confidenceValue = double.tryParse(
      controller.confidence.replaceAll('%', ''),
    ) ?? 0.0;

    Color confidenceColor;
    String confidenceLabel;

    if (confidenceValue >= 70) {
      confidenceColor = Colors.green;
      confidenceLabel = 'High Confidence';
    } else if (confidenceValue >= 40) {
      confidenceColor = Colors.orange;
      confidenceLabel = 'Medium Confidence';
    } else {
      confidenceColor = Colors.red;
      confidenceLabel = 'Low Confidence';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            _formatFoodName(controller.foodName),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: confidenceColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            confidenceLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: confidenceColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.confidence,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: confidenceColor,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: confidenceValue / 100,
            backgroundColor: confidenceColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(ResultController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Nutritional Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (controller.isLoadingNutrition)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (controller.nutritionalInfo != null)
          _buildNutritionDetails(controller.nutritionalInfo!)
        else
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not fetch nutritional data from Gemini.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNutritionDetails(NutritionalInfo info) {
    const MaterialColor primaryNutritionColor = Colors.green;

    Widget buildNutrientRow(String label, String value, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: primaryNutritionColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryNutritionColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          buildNutrientRow('Calories', info.calories, primaryNutritionColor.shade700),
          const Divider(height: 16),
          buildNutrientRow('Protein', info.protein, primaryNutritionColor.shade700),
          buildNutrientRow('Fat', info.fat, primaryNutritionColor.shade700),
          buildNutrientRow('Carbohydrates', info.carbohydrates, primaryNutritionColor.shade700),
          buildNutrientRow('Fiber', info.fiber, primaryNutritionColor.shade700),
        ],
      ),
    );
  }

  Widget _buildRelatedMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Related Recipes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingMeals)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_relatedMeals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No related recipes found',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _relatedMeals.length,
            itemBuilder: (context, index) {
              return _buildMealCard(_relatedMeals[index]);
            },
          ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MealDetailPage(meal: meal),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'meal_${meal.id}',
              child: Image.network(
                meal.thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 50),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (meal.category != null)
                        Text(
                          meal.category!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      if (meal.category != null && meal.area != null)
                        Text(' • ', style: TextStyle(color: Colors.grey[600])),
                      if (meal.area != null)
                        Text(
                          meal.area!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _runClassification,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              try {
                context.read<HomeController>().clearSelectedImage();
              } catch (_) {
                // ignore
              }
            },
            icon: const Icon(Icons.home),
            label: const Text('Home'),
          ),
        ),
      ],
    );
  }

  String _formatFoodName(String name) {
    return name
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}