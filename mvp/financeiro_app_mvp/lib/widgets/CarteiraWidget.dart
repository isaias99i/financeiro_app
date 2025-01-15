import 'package:flutter/material.dart';

class CarteiraWidget extends StatefulWidget {
  const CarteiraWidget({super.key});

  @override
  _CarteiraWidgetState createState() => _CarteiraWidgetState();
}

class _CarteiraWidgetState extends State<CarteiraWidget> {
  bool _isExpanded = false; // Estado para controlar a expansão
  final List<String> bancos = ['Banco Inter', 'Santander', 'Itaú', 'Físico'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carteira',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
              body: Column(
                children: bancos.map((banco) {
                  return Card(
                    elevation: 4,
                    child: ListTile(
                      title: Text(banco),
                      leading: const Icon(Icons.account_balance_wallet),
                      onTap: () {
                        // Ações específicas para cada banco
                      },
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
