import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fjkm_kajy/db/db_helper.dart';
import 'package:fjkm_kajy/components/currency.dart';
import 'package:fjkm_kajy/services/security_service.dart';
import 'package:fjkm_kajy/screens/pin.dart';
import 'package:fjkm_kajy/screens/setup-pin.dart';
import 'package:fjkm_kajy/utils/inactivity.dart';
import 'package:fjkm_kajy/screens/home-page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool hasPin = await PinService.hasPin();

  await initializeDateFormatting('fr_FR', null);

  runApp(FinanceApp(hasPin: hasPin));
}

class FinanceApp extends StatelessWidget {
  final bool hasPin;

  const FinanceApp({super.key, required this.hasPin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion de Finance',

      builder: (context, child) {
        return InactivityWrapper(child: child!);
      },

      initialRoute: hasPin ? '/pin' : '/setup',

      routes: {
        '/pin': (_) => const PinPage(),
        '/setup': (_) => const SetupPinPage(),
        '/home': (_) => const MainPage(),
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<Map<String, dynamic>> _getDashboardData() async {
    try {
      final db = DatabaseHelper.instance;
      final revenus = await db.getTotalRevenus();
      final depenses = await db.getTotalDepenses();
      final transactions = await db.getAllTrasanctions();
      final totalRevenus = await db.getRevenus();
      final solde = await db.getSoldePrincipal();

      return {
        'solde': solde,
        'revenus': revenus,
        'totalRevenus': totalRevenus,
        'depenses': depenses,
        'list': transactions,
      };
    } catch (e) {
      return {
        'solde': 0.0,
        'revenus': 0.0,
        'totalRevenus': 0.0,
        'depenses': 0.0,
        'list': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Tableau de bord",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          final data =
              snapshot.data ??
              {
                'solde': 0.0,
                'revenus': 0.0,
                'totalRevenus': 0.0,
                'depenses': 0.0,
                'list': [],
              };
          final List<Map<String, dynamic>> transactions =
              List<Map<String, dynamic>>.from(data['list']);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPremiumBalanceCard(data['solde']),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernStatCard(
                          "Revenus",
                          data['totalRevenus'],
                          Icons.south_west,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildModernStatCard(
                          "Dépenses",
                          data['depenses'],
                          Icons.north_east,
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  _buildSectionHeader(context),
                  const SizedBox(height: 15),

                  transactions.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            buildYearFilter(transactions),

                            const SizedBox(height: 20),

                            buildChart(transactions),
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 60,
            color: Colors.indigo.withOpacity(0.2),
          ),
          const SizedBox(height: 10),
          const Text(
            "Aucune donnée",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SOLDE DISPONIBLE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            formatCurrency(balance),
            style: TextStyle(
              color: balance < 0 ? Colors.red : Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Compte Principal",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              formatCurrency(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Transactions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  int selectedYear = DateTime.now().year;

  Map<String, Map<String, double>> groupByMonthYear(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<String, Map<String, double>> result = {};

    for (var t in transactions) {
      DateTime date = DateTime.parse(t['date']);

      String key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      if (!result.containsKey(key)) {
        result[key] = {'in': 0, 'out': 0};
      }

      double amount = (t['montant'] as num).toDouble();

      if (t['type'] == 'Sortant') {
        result[key]!['out'] = result[key]!['out']! + amount;
      } else {
        result[key]!['in'] = result[key]!['in']! + amount;
      }
    }

    return result;
  }

  List<int> getYears(List<Map<String, dynamic>> transactions) {
    return transactions
        .map((t) => DateTime.parse(t['date']).year)
        .toSet()
        .toList()
      ..sort();
  }

  Widget buildYearFilter(List<Map<String, dynamic>> transactions) {
    final years = getYears(transactions);

    if (years.isNotEmpty && !years.contains(selectedYear)) {
      selectedYear = years.first;
    }

    return DropdownButton<int>(
      value: selectedYear,
      isExpanded: true,

      items: years.map((year) {
        return DropdownMenuItem(value: year, child: Text(year.toString()));
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedYear = value!;
        });
      },
    );
  }

  Widget buildChart(List<Map<String, dynamic>> transactions) {
    final filtered = transactions.where((t) {
      final date = DateTime.parse(t['date']);
      return date.year == selectedYear;
    }).toList();

    final data = groupByMonthYear(filtered);

    final keys = data.keys.toList()..sort();

    List<String> monthNames = [
      "",
      "Jan",
      "Fev",
      "Mar",
      "Avr",
      "Mai",
      "Jun",
      "Jul",
      "Aou",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,

          borderData: FlBorderData(show: false),

          gridData: FlGridData(show: true),

          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,

                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= keys.length) {
                    return const SizedBox();
                  }

                  final key = keys[value.toInt()];
                  final month = int.parse(key.split("-")[1]);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthNames[month],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
          ),

          barGroups: List.generate(keys.length, (index) {
            final key = keys[index];
            final item = data[key]!;

            return BarChartGroupData(
              x: index,
              barsSpace: 4,

              barRods: [
                BarChartRodData(
                  toY: item['in']!,
                  color: Colors.green,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),

                BarChartRodData(
                  toY: item['out']!,
                  color: Colors.red,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
