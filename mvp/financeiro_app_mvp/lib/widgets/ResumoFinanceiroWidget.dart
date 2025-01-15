import 'package:flutter/material.dart';
import '../screens/despesasScreen.dart';
import '../screens/receitasScreen.dart';

class ResumoFinanceiroWidget extends StatefulWidget {
  final double receitas;
  final double despesas;
  final double saldoMensal;
  final double saldoAposReserva;
  final double saldoAtual;
  final double segurancaAno;

  const ResumoFinanceiroWidget({
    required this.receitas,
    required this.despesas,
    required this.saldoMensal,
    required this.saldoAposReserva,
    required this.saldoAtual,
    required this.segurancaAno,
    super.key,
  });

  @override
  _ResumoFinanceiroWidgetState createState() => _ResumoFinanceiroWidgetState();
}

class _ResumoFinanceiroWidgetState extends State<ResumoFinanceiroWidget> {
  bool _isExpanded = true;
  List<FinanceCardData> cards = [];
  @override
  void initState() {
    super.initState();
    cards = [
      FinanceCardData(
          title: 'Receitas',
          value: 'R\$ ${widget.receitas.toStringAsFixed(2)}',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceitasScreen()),
            );
          }),
      FinanceCardData(
          title: 'Despesas',
          value: 'R\$ ${widget.despesas.toStringAsFixed(2)}',
          color: Colors.black,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DespesasScreen(),
              ),
            );
          }),
      FinanceCardData(
        title: 'Saldo Mensal',
        value: 'R\$ ${widget.saldoMensal.toStringAsFixed(2)}',
        color: widget.saldoMensal >= 0 ? Colors.blue : Colors.orange,
        onTap: () {},
      ),
      FinanceCardData(
        title: 'Segurança Ano',
        value: 'R\$ ${widget.despesas * 12}',
        color: Colors.purple,
        onTap: () {},
      ),
      FinanceCardData(
        title: '% Completo',
        value:
        '% ${(widget.saldoAtual / widget.segurancaAno > 0 ? widget.saldoAtual / widget.segurancaAno : 0)}',
        color: Colors.indigo,
        onTap: () {},
      ),
      FinanceCardData(
        title: 'Atual',
        value: 'R\$ ${widget.saldoAtual.toStringAsFixed(2)}',
        color: Colors.teal,
        onTap: () {},
      ),
      FinanceCardData(
        title: 'Saldo após Reserva',
        value: 'R\$ ${widget.saldoAposReserva.toStringAsFixed(2)}',
        color: widget.saldoAposReserva >= 0 ? Colors.green : Colors.red,
        onTap: () {},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
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
                'Resumo Financeiro',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16, // Espaçamento horizontal entre os cards
                  runSpacing: 16, // Espaçamento vertical entre as linhas
                  children: [
                    for (int i = 0; i < cards.length; i++)
                      Stack(
                        children: [
                          FinanceCard(
                            title: cards[i].title,
                            value: cards[i].value,
                            color: cards[i].color,
                            onTap: cards[i].onTap,
                          ),
                          Positioned.fill(
                            top: -10,
                            right: -10,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    cards.removeAt(i);
                                  });
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    Container(
                      width: 150,
                      height: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: _showAddMenuDialog,
                          icon: const Icon(
                            Icons.add_circle,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMenuDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar novo menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  cards.add(FinanceCardData(
                      title: titleController.text,
                      value: valueController.text,
                      color: Colors.orange,
                      onTap: () {}));
                });
                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}

class FinanceCardData {
  final String title;
  final String value;
  final Color color;
  final Function()? onTap;

  FinanceCardData({
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });
}

class FinanceCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Function()? onTap;

  const FinanceCard({
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}