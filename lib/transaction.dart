import 'package:flutter/material.dart';
import 'package:fjkm_kajy/db/db_helper.dart';
import 'package:fjkm_kajy/components/currency.dart';
import 'package:intl/intl.dart';
import 'package:fjkm_kajy/services/export_service.dart';
import 'package:fjkm_kajy/services/trasanction_service.dart';

void _showExportDialog(BuildContext context) {
  DateTime? startDate;
  DateTime? endDate;
  String selectedType = 'Tous';
  String format = 'PDF';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Exporter les données",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              "Période",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDateCard(
                    label: startDate == null
                        ? "Début"
                        : DateFormat('dd/MM/yyyy').format(startDate!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => startDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateCard(
                    label: endDate == null
                        ? "Fin"
                        : DateFormat('dd/MM/yyyy').format(endDate!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => endDate = picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: ['Tous', 'Entrant', 'Sortant'].map((type) {
                bool selected = selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: Colors.indigo,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) => setModalState(() => selectedType = type),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            const Text("Format", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildFormatCard(
                    icon: Icons.picture_as_pdf,
                    label: "PDF",
                    selected: format == 'PDF',
                    onTap: () => setModalState(() => format = 'PDF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatCard(
                    icon: Icons.table_chart,
                    label: "Excel",
                    selected: format == 'Excel',
                    onTap: () => setModalState(() => format = 'Excel'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final data = await TransactionService.getFilteredData(
                    startDate: startDate,
                    endDate: endDate,
                    type: selectedType,
                  );

                  Navigator.pop(context);

                  if (format == 'PDF') {
                    await ExportService.exportToPDF(data);
                  } else {
                    await ExportService.exportToExcel(data);
                  }
                },
                // icon: const Icon(Icons.download),
                label: const Text("Exporter"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDateCard({required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(label)),
    ),
  );
}

Widget _buildFormatCard({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: selected ? Colors.indigo : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: selected ? Colors.white : Colors.black),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  String _filterType = 'Tous';

  bool _selectionMode = false;
  List<int> _selectedIds = [];

  Future<Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>
  _transactionFuture = Future.value({});

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    _transactionFuture = _loadGroupedTransactions();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);

        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _selectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (int id in _selectedIds) {
      await DatabaseHelper.instance.deleteOperation(id);
    }

    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Opérations supprimées"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllTransactions() async {
    await DatabaseHelper.instance.deleteAllOperations();

    setState(() {
      _refreshTransactions();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Toutes les opérations ont été supprimées"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>>
  _loadGroupedTransactions() async {
    final List<Map<String, dynamic>> allData = await DatabaseHelper.instance
        .getAllTrasanctions();

    final filteredData = _filterType == 'Tous'
        ? allData
        : allData.where((item) => item['type'] == _filterType).toList();

    Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> grouped =
        {};

    for (var item in filteredData) {
      try {
        DateTime date = DateTime.parse(item['date']);

        String year = date.year.toString();
        String month = DateFormat('MMMM', 'fr_FR').format(date);
        String day = DateFormat('dd MMM yyyy', 'fr_FR').format(date);

        grouped.putIfAbsent(year, () => {});
        grouped[year]!.putIfAbsent(month, () => {});
        grouped[year]![month]!.putIfAbsent(day, () => []);

        grouped[year]![month]![day]!.add(item);
      } catch (e) {
        print("Erreur sur item: $item => $e");
      }
    }

    return grouped;
  }

  double _sumItems(List<Map<String, dynamic>> items, String type) {
    return items
        .where((e) => e['type'] == type)
        .fold(0.0, (sum, item) => sum + (item['montant'] ?? 0.0));
  }

  double _total(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final montant = (item['montant'] ?? 0.0) as num;

      if (item['type'] == 'Entrant') {
        return sum + montant;
      } else if (item['type'] == 'Sortant') {
        return sum - montant;
      }

      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),

      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          _selectionMode
              ? "${_selectedIds.length} sélectionné(s)"
              : "Historique",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),

        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                await _deleteSelected();
              },
            ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'export') {
                _showExportDialog(context);
              }

              if (value == 'delete_all') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Supprimer toutes les opérations"),
                    content: const Text("Cette action est irréversible."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteAllTransactions();
                        },
                        child: const Text("Supprimer"),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'export', child: Text("Exporter")),
              const PopupMenuItem(
                value: 'delete_all',
                child: Text("Tout supprimer"),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          _buildModernFilters(),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _transactionFuture,

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groupedData = snapshot.data ?? {};

                if (groupedData.isEmpty) {
                  return _buildEmptyState();
                }

                final years = groupedData.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView(
                  padding: const EdgeInsets.all(16),

                  children: years.map((year) {
                    final months = groupedData[year] as Map<String, dynamic>;

                    double yearTotal = 0;

                    months.forEach((_, days) {
                      days.forEach((_, items) {
                        yearTotal += _total(
                          List<Map<String, dynamic>>.from(items),
                        );
                      });
                    });

                    final sortedMonths = months.keys.toList()
                      ..sort((a, b) {
                        final monthOrder = {
                          'janvier': 1,
                          'février': 2,
                          'mars': 3,
                          'avril': 4,
                          'mai': 5,
                          'juin': 6,
                          'juillet': 7,
                          'août': 8,
                          'septembre': 9,
                          'octobre': 10,
                          'novembre': 11,
                          'décembre': 12,
                        };

                        return monthOrder[b.toLowerCase()]!.compareTo(
                          monthOrder[a.toLowerCase()]!,
                        );
                      });

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: ExpansionTile(
                        initiallyExpanded: true,
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,

                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Année $year",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Balance annuelle : ${NumberFormat('#,##0', 'fr_FR').format(yearTotal)} Ar",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),

                        children: sortedMonths.map<Widget>((month) {
                          final days = months[month] as Map<String, dynamic>;

                          // double monthTotal = 0;

                          // days.forEach((_, items) {
                          //   monthTotal += _total(
                          //     List<Map<String, dynamic>>.from(items),
                          //   );
                          // });

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),

                            child: Card(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: ExpansionTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.date_range,
                                          size: 18,
                                          color: Colors.black87,
                                        ),
                                        const SizedBox(width: 6),

                                        Text(
                                          month.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Text(
                                    //   "Total: ${NumberFormat('#,##0', 'fr_FR').format(monthTotal)}",
                                    //   style: const TextStyle(
                                    //     fontSize: 12,
                                    //     color: Colors.grey,
                                    //   ),
                                    // ),
                                  ],
                                ),

                                children: days.keys.map<Widget>((day) {
                                  final items = List<Map<String, dynamic>>.from(
                                    days[day],
                                  );

                                  // double dayTotal = _total(items);
                                  // double dayTotal =
                                  //     _sumItems(items, "Entrant") -
                                  //             _sumItems(items, "Sortant") >
                                  //         0
                                  //     ? _sumItems(items, "Entrant") -
                                  //           _sumItems(items, "Sortant")
                                  //     : 0;
                                  // double entrant = _sumItems(items, "Entrant");
                                  // double sortant = _sumItems(items, "Sortant");

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.push_pin,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 6),

                                            Text(
                                              day,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Row(
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.spaceBetween,
                                        //   children: [
                                        //     Row(
                                        //       children: [
                                        //         const Icon(
                                        //           Icons.arrow_downward,
                                        //           color: Colors.green,
                                        //           size: 18,
                                        //         ),
                                        //         const SizedBox(width: 4),

                                        //         Text(
                                        //           "${NumberFormat('#,##0', 'fr_FR').format(entrant)} Ar",
                                        //           style: const TextStyle(
                                        //             color: Colors.green,
                                        //           ),
                                        //         ),
                                        //       ],
                                        //     ),

                                        //     Row(
                                        //       children: [
                                        //         const Icon(
                                        //           Icons.arrow_upward,
                                        //           color: Colors.red,
                                        //           size: 18,
                                        //         ),
                                        //         const SizedBox(width: 4),

                                        //         Text(
                                        //           "${NumberFormat('#,##0', 'fr_FR').format(sortant)} Ar",
                                        //           style: const TextStyle(
                                        //             color: Colors.red,
                                        //           ),
                                        //         ),
                                        //       ],
                                        //     ),

                                        //     Row(
                                        //       children: [
                                        //         const Icon(
                                        //           Icons.account_balance_wallet,
                                        //           size: 18,
                                        //           color: Colors.black87,
                                        //         ),
                                        //         const SizedBox(width: 4),

                                        //         Text(
                                        //           "${NumberFormat('#,##0', 'fr_FR').format(dayTotal)} Ar",
                                        //           overflow:
                                        //               TextOverflow.ellipsis,
                                        //           maxLines: 1,
                                        //           style: const TextStyle(
                                        //             fontWeight: FontWeight.bold,
                                        //             fontSize: 13,
                                        //           ),
                                        //         ),
                                        //       ],
                                        //     ),
                                        //   ],
                                        // ),
                                        const SizedBox(height: 10),

                                        ...items.map(
                                          (item) => _buildModernTile(item),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildModernFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: ['Tous', 'Entrant', 'Sortant'].map((label) {
            bool isSelected = _filterType == label;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _filterType = label;
                    _refreshTransactions();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A237E)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModernTile(Map<String, dynamic> item) {
    bool isExpense = item['type'] == 'Sortant';

    bool isSelected = _selectedIds.contains(item['id']);

    return GestureDetector(
      onLongPress: () {
        _toggleSelection(item['id']);
      },

      onTap: () {
        if (_selectionMode) {
          _toggleSelection(item['id']);
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),

          border: isSelected
              ? Border.all(color: Colors.indigo, width: 2)
              : null,

          gradient: LinearGradient(
            colors: isExpense
                ? [Colors.red.shade50, Colors.red.shade100]
                : [Colors.green.shade50, Colors.green.shade100],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpense ? Icons.trending_down : Icons.trending_up,
              color: isExpense ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['description'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item['type'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${isExpense ? '-' : '+'} ${NumberFormat('#,##0', 'fr_FR').format(item['montant'])} Ar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),

                if (!_selectionMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showEditDeleteDialog(item);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 80,
            color: Colors.indigo.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucune activité ici",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String selectedType = 'Sortant';
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nouvelle Opération",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                title: Text(
                  "Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                ),
                trailing: const Text(
                  "Modifier",
                  style: TextStyle(color: Colors.indigo),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null)
                    setModalState(() => selectedDate = picked);
                },
              ),

              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Type d'opération",
                ),
                items: ['Entrant', 'Sortant']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Montant",
                  suffixText: " Ar",
                ),
              ),

              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final String montantTexte = amountController.text.trim();
                    final String description = descController.text.trim();

                    if (montantTexte.isEmpty || description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ Remplissez tout !")),
                      );
                      return;
                    }

                    final double? montant = double.tryParse(montantTexte);
                    if (montant != null) {
                      await DatabaseHelper.instance.insertOperation({
                        'type': selectedType,
                        'date': selectedDate.toIso8601String(),
                        'montant': montant,
                        'description': description,
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _refreshTransactions();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Enregistrement réussi !"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDeleteDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier'),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Supprimer"),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(item);
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final amountController = TextEditingController(
      text: item['montant'].toString(),
    );
    final descController = TextEditingController(
      text: item['description'].toString(),
    );
    String selectedType = item['type'];
    DateTime selectedDate = DateTime.parse(item['date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Modification",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                title: Text(
                  "Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                ),
                trailing: const Text(
                  "Modifier",
                  style: TextStyle(color: Colors.indigo),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null)
                    setModalState(() => selectedDate = picked);
                },
              ),

              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Type d'opération",
                ),
                items: ['Entrant', 'Sortant']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Montant",
                  suffixText: " Ar",
                ),
              ),

              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final String montantTexte = amountController.text.trim();
                    final String description = descController.text.trim();

                    if (montantTexte.isEmpty || description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Remplissez tout !")),
                      );
                      return;
                    }

                    final double? montant = double.tryParse(montantTexte);
                    if (montant != null) {
                      await DatabaseHelper.instance.updateOperation({
                        'type': selectedType,
                        'date': selectedDate.toIso8601String(),
                        'montant': montant,
                        'description': description,
                      }, item['id']);

                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _refreshTransactions();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Modification réussie !"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Mettre à jour"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Confirmer la suppression",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text("Cette action est irréversible."),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      await DatabaseHelper.instance.deleteOperation(item['id']);

                      setState(() {
                        _refreshTransactions();
                      });
                    },
                    child: const Text("Supprimer"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
