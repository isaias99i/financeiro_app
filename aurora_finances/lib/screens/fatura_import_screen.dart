import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import '../data/categories_store.dart';
import '../data/despesas_store.dart';
import '../data/settings_store.dart';
import '../models/despesas_models.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/invoice_parser.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/aurora_scaffold.dart';

class FaturaImportScreen extends StatefulWidget {
  final DespesasStore despesasStore;
  final CategoriesStore categoriesStore;

  const FaturaImportScreen({
    super.key,
    required this.despesasStore,
    required this.categoriesStore,
  });

  @override
  State<FaturaImportScreen> createState() => _FaturaImportScreenState();
}

class _FaturaImportScreenState extends State<FaturaImportScreen> {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final List<_DraftEntry> _entries = [];
  _ColumnOption? _selectedColumn;
  bool _isProcessing = false;
  String? _error;
  String? _pdfPassword;

  @override
  void initState() {
    super.initState();
    if (!widget.despesasStore.isLoaded) {
      widget.despesasStore.load();
    }
    if (!widget.categoriesStore.isLoaded) {
      widget.categoriesStore.load();
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final categories = widget.categoriesStore.categories.toList();
    final options = _columnOptions();
    if (_selectedColumn != null && !options.contains(_selectedColumn)) {
      _selectedColumn = null;
    }

    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Importar fatura'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCardSection(options),
          const SizedBox(height: 16),
          _buildPdfSection(),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          if (_entries.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionTitle('Lancamentos encontrados'),
            const SizedBox(height: 8),
            _buildEntriesList(settings, categories),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isProcessing ? null : () => _saveEntries(settings),
              child: const Text('Importar lancamentos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCardSection(List<_ColumnOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cartao de credito'),
        DropdownButtonFormField<_ColumnOption>(
          key: ValueKey(_selectedColumn?.column.id ?? 'none'),
          initialValue: _selectedColumn,
          decoration: _dropdownDecoration('Escolha a coluna do cartao'),
          dropdownColor: const Color(0xFF10212C),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text('${option.group.title} - ${option.column.title}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedColumn = value);
          },
        ),
        if (options.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Crie um grupo/coluna de despesas detalhadas para importar a fatura.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }

  Widget _buildPdfSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Fatura (PDF)'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dica: PDFs com texto selecionavel costumam dar resultado melhor.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _pickPdf,
                icon: const Icon(Icons.upload_file),
                label: const Text('Selecionar PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.16),
      contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
    );
  }

  List<_ColumnOption> _columnOptions() {
    final options = <_ColumnOption>[];
    for (final group in widget.despesasStore.groups) {
      for (final column in group.columns) {
        if (!column.requiresEntries) continue;
        options.add(_ColumnOption(group: group, column: column));
      }
    }
    return options;
  }

  Future<void> _pickPdf() async {
    setState(() {
      _error = null;
    });
    if (_selectedColumn == null) {
      setState(() {
        _error = 'Selecione a coluna do cartao antes de importar.';
      });
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.files.single.path == null) {
      return;
    }
    _pdfPassword = await _promptForPassword();
    final path = result.files.single.path!;
    await _processPdf(path, password: _pdfPassword);
  }

  Future<void> _processPdf(String pdfPath, {String? password}) async {
    setState(() {
      _isProcessing = true;
      _entries.clear();
      _error = null;
    });
    try {
      final extracted = <InvoiceParsedItem>[];
      final text = _extractPdfText(pdfPath, password);
      if (text != null && text.trim().isNotEmpty) {
        extracted.addAll(
          InvoiceParser.parse(
            text,
            referenceDate: DateTime.now(),
          ),
        );
      }

      if (extracted.isEmpty) {
        extracted.addAll(await _ocrPdf(pdfPath, password: password));
      }

      if (extracted.isEmpty) {
        setState(() {
          _error =
              'Nenhum lancamento identificado. Tente outro PDF ou ajuste o contraste da fatura.';
        });
        return;
      }

      final categories = widget.categoriesStore.categories.toList();
      final drafts = extracted.map((item) {
        final inferredCategory = InvoiceParser.inferCategory(
          item.description,
          categories,
        );
        return _DraftEntry.fromParsed(
          item,
          category: inferredCategory,
        );
      }).toList();

      setState(() => _entries.addAll(drafts));
    } catch (e) {
      setState(() {
        _error = 'Falha ao ler a fatura. Verifique o PDF e tente novamente.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String? _extractPdfText(String pdfPath, String? password) {
    try {
      final document = sfpdf.PdfDocument(
        inputBytes: File(pdfPath).readAsBytesSync(),
        password: password,
      );
      final extractor = sfpdf.PdfTextExtractor(document);
      final buffer = StringBuffer();
      for (var i = 0; i < document.pages.count; i++) {
        buffer.writeln(extractor.extractText(startPageIndex: i));
      }
      document.dispose();
      return buffer.toString();
    } catch (_) {
      return null;
    }
  }

  Future<List<InvoiceParsedItem>> _ocrPdf(
    String pdfPath, {
    String? password,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final document = await PdfDocument.openFile(
      pdfPath,
      password: password,
    );
    final pageCount = document.pagesCount;
    final extracted = <InvoiceParsedItem>[];
    for (var i = 1; i <= pageCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      if (pageImage == null) {
        await page.close();
        continue;
      }
      final bytes = pageImage.bytes;
      final imagePath = path.join(tempDir.path, 'invoice_page_$i.png');
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final items = InvoiceParser.parse(
        recognizedText.text,
        referenceDate: DateTime.now(),
      );
      extracted.addAll(items);
      await page.close();
    }
    await document.close();
    await _cleanupTempImages(tempDir);
    return extracted;
  }

  Future<void> _cleanupTempImages(Directory tempDir) async {
    try {
      final files = tempDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).startsWith('invoice_page_'));
      for (final file in files) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup.
    }
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController(text: _pdfPassword ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Senha do PDF'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Senha (opcional)',
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Pular'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  }

  Widget _buildEntriesList(AppSettingsStore settings, List<String> categories) {
    if (_entries.isEmpty) {
      return const Text('Nenhum lancamento identificado.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _EntryCard(
          entry: entry,
          categories: categories,
          settings: settings,
          onRemove: () => _removeEntry(index),
          onDatePick: () => _pickEntryDate(entry),
          onCategoryChanged: (value) => setState(() => entry.category = value),
          onAmountChanged: (value) {
            setState(() {
              entry.amountValue = parseCurrencyToDouble(value);
            });
          },
          onInstallmentToggle: (value) {
            setState(() {
              entry.isInstallment = value;
              if (!value) {
                entry.installmentCount = 1;
                entry.installmentIndex = 1;
                entry.installmentCountController.text = '1';
                entry.installmentIndexController.text = '1';
              }
            });
          },
          onInstallmentCountChanged: (value) {
            setState(() {
              entry.installmentCount = int.tryParse(value) ?? 1;
            });
          },
          onInstallmentIndexChanged: (value) {
            setState(() {
              entry.installmentIndex = int.tryParse(value) ?? 1;
            });
          },
          fieldDecoration: _fieldDecoration,
          dropdownDecoration: _dropdownDecoration,
        );
      },
    );
  }

  Future<void> _pickEntryDate(_DraftEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() => entry.date = picked);
  }

  void _removeEntry(int index) {
    setState(() {
      final entry = _entries.removeAt(index);
      entry.dispose();
    });
  }

  Future<void> _saveEntries(AppSettingsStore settings) async {
    final column = _selectedColumn?.column;
    if (column == null) {
      _showSnack('Selecione a coluna do cartao.');
      return;
    }

    for (final entry in _entries) {
      entry.syncControllers(settings);
    }

    for (final entry in _entries) {
      if (entry.amountValue <= 0) continue;
      if (entry.isInstallment && entry.installmentCount > 1) {
        _addInstallments(entry, column.id);
        continue;
      }
      widget.despesasStore.addEntry(
        ExpenseEntry(
          id: widget.despesasStore.nextId(),
          columnId: column.id,
          date: entry.date,
          category: entry.category,
          reason: entry.reason,
          amount: entry.amountValue,
        ),
      );
    }

    _showSnack('Lancamentos importados.');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addInstallments(_DraftEntry entry, String columnId) {
    final count = entry.installmentCount;
    final index = entry.installmentIndex;
    for (var i = index; i <= count; i++) {
      widget.despesasStore.addEntry(
        ExpenseEntry(
          id: widget.despesasStore.nextId(),
          columnId: columnId,
          date: _installmentDate(entry.date, i),
          category: entry.category,
          reason: entry.reason,
          amount: entry.amountValue,
          installmentCount: count,
          installmentIndex: i,
          purchaseDate: entry.date,
        ),
      );
    }
  }

  DateTime _installmentDate(DateTime purchaseDate, int installmentIndex) {
    final targetMonth = DateTime(
      purchaseDate.year,
      purchaseDate.month + (installmentIndex - 1),
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final safeDay = purchaseDate.day > lastDay ? lastDay : purchaseDate.day;
    return DateTime(targetMonth.year, targetMonth.month, safeDay);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DraftEntry {
  DateTime date;
  String category;
  String reason;
  bool isInstallment;
  int installmentCount;
  int installmentIndex;
  double amountValue;
  final TextEditingController reasonController;
  final TextEditingController amountController;
  final TextEditingController installmentCountController;
  final TextEditingController installmentIndexController;

  _DraftEntry({
    required this.date,
    required this.category,
    required this.reason,
    required this.amountValue,
    required this.isInstallment,
    required this.installmentCount,
    required this.installmentIndex,
    required this.reasonController,
    required this.amountController,
    required this.installmentCountController,
    required this.installmentIndexController,
  });

  factory _DraftEntry.fromParsed(
    InvoiceParsedItem item, {
    required String category,
  }) {
    final amountText = item.amount.toStringAsFixed(2);
    final installmentInfo = item.installment;
    final isInstallment = installmentInfo != null && installmentInfo.count > 1;
    final count = installmentInfo?.count ?? 1;
    final index = installmentInfo?.index ?? 1;

    return _DraftEntry(
      date: item.date,
      category: category,
      reason: item.description,
      amountValue: item.amount,
      isInstallment: isInstallment,
      installmentCount: count,
      installmentIndex: index,
      reasonController: TextEditingController(text: item.description),
      amountController: TextEditingController(text: amountText),
      installmentCountController: TextEditingController(text: '$count'),
      installmentIndexController: TextEditingController(text: '$index'),
    );
  }

  void syncControllers(AppSettingsStore settings) {
    reason = reasonController.text.trim();
    amountValue = parseCurrencyToDouble(amountController.text);
    final count = int.tryParse(installmentCountController.text) ?? 1;
    final index = int.tryParse(installmentIndexController.text) ?? 1;
    installmentCount = count <= 0 ? 1 : count;
    installmentIndex = index <= 0 ? 1 : index;
    if (installmentIndex > installmentCount) {
      installmentIndex = installmentCount;
    }
  }

  void dispose() {
    reasonController.dispose();
    amountController.dispose();
    installmentCountController.dispose();
    installmentIndexController.dispose();
  }
}

class _ColumnOption {
  final ExpenseGroup group;
  final ExpenseColumn column;

  const _ColumnOption({required this.group, required this.column});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ColumnOption &&
        other.group.id == group.id &&
        other.column.id == column.id;
  }

  @override
  int get hashCode => Object.hash(group.id, column.id);
}

class _EntryCard extends StatelessWidget {
  final _DraftEntry entry;
  final List<String> categories;
  final AppSettingsStore settings;
  final VoidCallback onRemove;
  final VoidCallback onDatePick;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<bool> onInstallmentToggle;
  final ValueChanged<String> onInstallmentCountChanged;
  final ValueChanged<String> onInstallmentIndexChanged;
  final InputDecoration Function(String) fieldDecoration;
  final InputDecoration Function(String) dropdownDecoration;

  const _EntryCard({
    required this.entry,
    required this.categories,
    required this.settings,
    required this.onRemove,
    required this.onDatePick,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onInstallmentToggle,
    required this.onInstallmentCountChanged,
    required this.onInstallmentIndexChanged,
    required this.fieldDecoration,
    required this.dropdownDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final moneyFormatter = settings.currencyFormatter();
    final categoryList = categories.isEmpty ? ['Outros'] : categories.toList();
    if (entry.category.isNotEmpty && !categoryList.contains(entry.category)) {
      categoryList.insert(0, entry.category);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(entry.category),
                  initialValue:
                      entry.category.isNotEmpty ? entry.category : categoryList.first,
                  decoration: dropdownDecoration('Categoria'),
                  dropdownColor: const Color(0xFF10212C),
                  items: categoryList
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    onCategoryChanged(value);
                  },
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.reasonController,
            decoration: fieldDecoration('Descricao'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              CurrencyInputFormatter(
                locale: settings.currencyLocale,
                symbol: settings.currencySymbol,
              ),
            ],
            decoration: fieldDecoration('Valor'),
            style: const TextStyle(color: Colors.white),
            onChanged: onAmountChanged,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onDatePick,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              settings.dateFormatter().format(entry.date),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Compra parcelada'),
            subtitle: const Text('Criar parcelas nos meses seguintes'),
            value: entry.isInstallment,
            onChanged: onInstallmentToggle,
          ),
          if (entry.isInstallment) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.installmentCountController,
                    keyboardType: TextInputType.number,
                    decoration: fieldDecoration('Parcelas'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: onInstallmentCountChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: entry.installmentIndexController,
                    keyboardType: TextInputType.number,
                    decoration: fieldDecoration('Parcela atual'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: onInstallmentIndexChanged,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            moneyFormatter.format(entry.amountValue),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
