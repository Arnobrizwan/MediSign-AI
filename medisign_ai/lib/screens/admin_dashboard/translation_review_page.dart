import 'package:flutter/material.dart';

class TranslationReviewPage extends StatelessWidget {
  const TranslationReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF45B69);
    const Color darkColor = Color(0xFF2D3142);
    const Color accentColor = Color(0xFF6B778D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Translation Review',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            color: Colors.white,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithStats(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildLanguageSelectionBar(),
                    const SizedBox(height: 24),
                    _buildFlaggedTranslationsSection(),
                    const SizedBox(height: 24),
                    _buildTranslationStatisticsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Add translation',
      ),
    );
  }

  Widget _buildHeaderWithStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Translation Accuracy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: Today, 10:45 AM',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildStatBadge('94%', 'Accuracy', Icons.check_circle),
            const SizedBox(width: 16),
            _buildStatBadge('12', 'Pending', Icons.pending_actions),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF45B69)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Source:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B778D),
                ),
              ),
              const SizedBox(width: 8),
              _buildLanguageChip('English', true),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: Color(0xFF6B778D),
              size: 20,
            ),
          ),
          Row(
            children: [
              const Text(
                'Target:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B778D),
                ),
              ),
              const SizedBox(width: 8),
              _buildLanguageChip('Spanish', false),
              const SizedBox(width: 8),
              _buildLanguageChip('Mandarin', false),
              const SizedBox(width: 8),
              _buildLanguageChip('Arabic', false),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF6B778D),
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String language, bool isSource) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSource
            ? const Color(0xFFF45B69).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: isSource
            ? Border.all(color: const Color(0xFFF45B69), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Text(
            language,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSource ? FontWeight.bold : FontWeight.normal,
              color: isSource
                  ? const Color(0xFFF45B69)
                  : const Color(0xFF6B778D),
            ),
          ),
          if (!isSource) ...[
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: Colors.grey[400]),
          ],
        ],
      ),
    );
  }

  Widget _buildFlaggedTranslationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF45B69).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Color(0xFFF45B69),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Flagged Translations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B778D),
                        side: const BorderSide(color: Color(0xFF6B778D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'Sort: Priority',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B778D),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Color(0xFF6B778D),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: const [
              _TranslationItem(
                original:
                    'Your prescription has been approved and is ready for pickup.',
                translation:
                    'Su receta ha sido aprobada y está lista para ser recogida.',
                language: 'Spanish',
                itemContext: 'Pharmacy Notification',
                accuracy: 4,
                flagReason: 'Medical terminology review',
                priority: 'High',
              ),
              Divider(height: 1),
              _TranslationItem(
                original:
                    'Please fast for 12 hours before your blood test appointment.',
                translation:
                    'Por favor ayune durante 12 horas antes de su cita para el análisis de sangre.',
                language: 'Spanish',
                itemContext: 'Lab Instructions',
                accuracy: 3,
                flagReason: 'Phrasing clarity',
                priority: 'Medium',
              ),
              Divider(height: 1),
              _TranslationItem(
                original: 'Take this medication twice daily with food.',
                translation: '一日两次随餐服用此药。',
                language: 'Mandarin',
                itemContext: 'Medication Instructions',
                accuracy: 2,
                flagReason: 'Dosage clarity',
                priority: 'Critical',
              ),
              Divider(height: 1),
              _TranslationItem(
                original:
                    'Your insurance coverage has been verified for this procedure.',
                translation:
                    'تم التحقق من تغطية التأمين الخاص بك لهذا الإجراء.',
                language: 'Arabic',
                itemContext: 'Billing Information',
                accuracy: 5,
                flagReason: 'Technical term verification',
                priority: 'Low',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.visibility,
                  size: 16,
                  color: Color(0xFF6B778D),
                ),
                label: const Text(
                  'View All Flagged Translations',
                  style: TextStyle(
                    color: Color(0xFF6B778D),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF45B69).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Color(0xFFF45B69),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Translation Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildStatisticCard(
                      'Total Translations', '1,245', Icons.translate)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatisticCard('Languages', '8', Icons.language)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatisticCard(
                      'Avg. Accuracy', '94%', Icons.check_circle)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatisticCard(
                      'Pending Review', '12', Icons.pending_actions)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 2, child: _buildLanguageChart()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildAccuracyList()),
            ],
          ),
        ],  
      ),
    );
  }

  Widget _buildStatisticCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF6B778D),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B778D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Translation Volume by Language',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLanguageBarChart('Spanish', 45),
                _buildLanguageBarChart('Mandarin', 30),
                _buildLanguageBarChart('Arabic', 15),
                _buildLanguageBarChart('French', 10),
                _buildLanguageBarChart('Other', 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBarChart(String language, int percentage) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            language,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B778D),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 16,
                width: percentage * 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFF45B69),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),  
        ),
      ],
    );  
  }

  Widget _buildAccuracyList() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accuracy by Language',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),  
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildAccuracyItem('Spanish', 96),
                const Divider(height: 24),
                _buildAccuracyItem('Mandarin', 94),
                const Divider(height: 24),
                _buildAccuracyItem('Arabic', 92),
                const Divider(height: 24),
                _buildAccuracyItem('French', 97),
                const Divider(height: 24),
                _buildAccuracyItem('Russian', 91),
              ],  
            ),
          ),  
        ],  
      ),  
    );  
  }

  Widget _buildAccuracyItem(String language, int score) {
    Color color;
    if (score >= 95) {
      color = Colors.green;
    } else if (score >= 90) {
      color = Colors.amber;
    } else {
      color = Colors.red;
    }

    return Row(
      children: [
        Text(
          language,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D3142),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$score%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),  
          ),  
        ),  
      ],  
    );  
  }  
}

// Updated _TranslationItem with itemContext instead of context
class _TranslationItem extends StatelessWidget {
  final String original;
  final String translation;
  final String language;
  final String itemContext;
  final int accuracy;
  final String flagReason;
  final String priority;

  const _TranslationItem({
    Key? key,
    required this.original,
    required this.translation,
    required this.language,
    required this.itemContext,
    required this.accuracy,
    required this.flagReason,
    required this.priority,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'critical':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.amber;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: priorityColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  language,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  itemContext, // use itemContext here
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
              ),
              const Spacer(),
              _buildLocalStarRating(accuracy),
            ],
          ),
          const SizedBox(height: 16),
          // ORIGINAL / TRANSLATION panels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORIGINAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B778D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        original,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRANSLATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B778D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        translation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flag reason and actions
          Row(
            children: [
              const Icon(Icons.flag, size: 16, color: Color(0xFFF45B69)),
              const SizedBox(width: 8),
              Text(
                'Flagged for: $flagReason',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFF45B69),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Suggest Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B778D),
                ),
              ),  
              const SizedBox(width: 8),  
              ElevatedButton.icon(  
                onPressed: () {},  
                icon: const Icon(Icons.check, size: 16),  
                label: const Text('Approve'),  
                style: ElevatedButton.styleFrom(  
                  backgroundColor: const Color(0xFFF45B69),  
                  foregroundColor: Colors.white,  
                  shape: RoundedRectangleBorder(  
                    borderRadius: BorderRadius.circular(8),  
                  ),  
                ),  
              ),  
            ],  
          ),  
        ],  
      ),  
    );  
  }  

  Widget _buildLocalStarRating(int rating) {  
    return Row(  
      children: List.generate(5, (index) {  
        return Icon(  
          index < rating ? Icons.star : Icons.star_border,  
          color: index < rating ? Colors.amber : Colors.grey[400],  
          size: 18,  
        );  
      }),  
    );  
  }  
}