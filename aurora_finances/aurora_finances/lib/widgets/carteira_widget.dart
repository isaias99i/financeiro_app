import 'package:flutter/material.dart';

class CarteiraWidget extends StatefulWidget {
  const CarteiraWidget({super.key});

  @override
  State<CarteiraWidget> createState() => _CarteiraWidgetState();
}

class _CarteiraWidgetState extends State<CarteiraWidget> {
  bool _isExpanded = false;
  final List<String> bancos = ['Banco Inter', 'Santander', 'Itau', 'Fisico'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carteira',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ExpansionPanelList(
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              isExpanded: _isExpanded,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return const ListTile(
                  title: Text(
                    'Bancos',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                );
              },
              body: Column(
                children: bancos.map((banco) {
                  return Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(banco, style: const TextStyle(color: Colors.white)),
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
                      onTap: () {},
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
