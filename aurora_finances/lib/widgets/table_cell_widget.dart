import 'package:flutter/material.dart';

class TableCellWidget extends StatelessWidget {
  final String content;
  final double width;
  final double height;
  final bool isHeader;
  final bool isMerged; // Indica se a célula é mesclada
  final Color textColor;
  final VoidCallback? onTap; // Função chamada ao clicar na célula
  final int colSpan; // Número de colunas a mesclar (opcional)
  final int rowSpan; //Numero de linhas a mesclar

  final Map<String, Widget Function(BuildContext)> routes = {
    //'Gastos Detalhados': (context) => const gastosDetalhados(),
    // Adicione mais rotas conforme necessário...
  };

  TableCellWidget({
    super.key,
    required this.content,
    required this.width,
    this.height = 40,
    this.isHeader = false,
    this.isMerged = false, // Por padrão, não é uma célula mesclada
    this.textColor = Colors.black,
    this.onTap, // Clique opcional
    this.colSpan = 1, // Por padrão, ocupa apenas 1 célula
    this.rowSpan = 1, // Por padrão, ocupa apenas 1 célula
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
              () {
            if (routes.containsKey(content)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => routes[content]!(context),
                ),
              );
            }
          },
      child: Container(
        width: width * colSpan,
        height: isMerged ? height * rowSpan : height, // Mescla aumenta a altura
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: content == 'Mês'
              ? Colors.blue[600]
              : isHeader
              ? Colors.blue[900]
              : Colors.blue[200],
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
