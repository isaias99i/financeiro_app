import 'package:flutter/material.dart';

import '../data/categories_store.dart';
import '../widgets/aurora_scaffold.dart';

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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: ListTile(
                  title: Text(category, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showCategoryDialog(category: category),
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => _removeCategory(category),
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
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
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7FD7FF), width: 1.4),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF101B24),
              Color(0xFF183446),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category, color: Color(0xFF7FD7FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: initialValue,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration.copyWith(labelText: 'Categoria'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                        backgroundColor: const Color(0xFF3C8FD9),
                        foregroundColor: Colors.white,
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category, color: Colors.white70, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Nenhuma categoria cadastrada.',
              style: TextStyle(color: Colors.white),
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
