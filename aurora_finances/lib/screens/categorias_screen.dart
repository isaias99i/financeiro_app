import 'package:flutter/material.dart';

import '../data/categories_store.dart';
import '../widgets/aurora_scaffold.dart';
import '../theme/app_tokens.dart';

// Tela de gerenciamento de categorias.
class CategoriasScreen extends StatefulWidget {
  final CategoriesStore store;

  const CategoriasScreen({super.key, required this.store});

  @override
  // Cria o estado da tela de categorias.
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

// Estado da tela de categorias.
class _CategoriasScreenState extends State<CategoriasScreen> {
  @override
  // Carrega categorias ao iniciar.
  void initState() {
    super.initState();
    if (!widget.store.isLoaded) {
      widget.store.load();
    }
  }

  @override
  // Monta a lista de categorias.
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar categoria',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (!widget.store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = widget.store.categories;
          if (categories.isEmpty) {
            return _EmptyCategories(onAdd: _showCategoryDialog);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final tokens = AppThemeTokens.of(context);
              return Container(
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.border),
                ),
                child: ListTile(
                  title: Text(category, style: TextStyle(color: tokens.textPrimary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showCategoryDialog(category: category),
                        icon: Icon(Icons.edit, color: tokens.textSecondary),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => _removeCategory(category),
                        icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
                        tooltip: 'Remover',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Abre dialogo para adicionar/editar categoria.
  Future<void> _showCategoryDialog({String? category}) async {
    final controller = TextEditingController(text: category ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return _CategoryDialog(
          title: category == null ? 'Nova categoria' : 'Editar categoria',
          initialValue: controller,
          onSave: (value) {
            if (category == null) {
              widget.store.addCategory(value);
            } else {
              widget.store.updateCategory(category, value);
            }
          },
        );
      },
    );
  }

  // Remove uma categoria.
  void _removeCategory(String category) {
    widget.store.removeCategory(category);
  }
}

// Dialogo para criar/editar categoria.
class _CategoryDialog extends StatelessWidget {
  final String title;
  final TextEditingController initialValue;
  final void Function(String value) onSave;

  const _CategoryDialog({
    required this.title,
    required this.initialValue,
    required this.onSave,
  });

  @override
  // Monta o conteudo do dialogo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: tokens.surfaceAlt,
      labelStyle: TextStyle(color: tokens.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.focus, width: 1.4),
      ),
    );

    return Dialog(
      backgroundColor: tokens.background.withValues(alpha: 0.0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.panelGradient,
          ),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.shadow,
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category, color: tokens.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: tokens.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: initialValue,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: tokens.textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Categoria'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.textSecondary,
                        side: BorderSide(color: tokens.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = initialValue.text.trim();
                        if (value.isEmpty) {
                          return;
                        }
                        onSave(value);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: tokens.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Estado vazio quando nao ha categorias.
class _EmptyCategories extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCategories({required this.onAdd});

  @override
  // Monta o estado vazio com CTA.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category, color: tokens.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Nenhuma categoria cadastrada.',
              style: TextStyle(color: tokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar categoria'),
            ),
          ],
        ),
      ),
    );
  }
}
