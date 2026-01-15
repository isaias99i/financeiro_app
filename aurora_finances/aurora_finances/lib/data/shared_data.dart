import '../models/dynamic_table_models.dart';
import 'generate_data_despesas_until_2040.dart';
import 'generate_data_receitas_until_2040.dart';

class SharedData {
  static final List<DynamicRow> receitas = generateDataReceitasUntil2040();
  static final List<DynamicRow> despesas = generateDataDespesasUntil2040();
}
