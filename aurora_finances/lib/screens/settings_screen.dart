import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/carteira_store.dart';
import '../data/categories_store.dart';
import '../data/despesas_store.dart';
import '../data/receitas_store.dart';
import '../screens/categorias_screen.dart';
import '../screens/appearance_screen.dart';
import '../screens/fatura_import_screen.dart';
import '../screens/labels_colors_screen.dart';
import '../screens/formatting_screen.dart';
import '../screens/typography_screen.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/app_settings_scope.dart';

class SettingsScreen extends StatefulWidget {
  final CategoriesStore categoriesStore;
  final ReceitasStore receitasStore;
  final DespesasStore despesasStore;
  final CarteiraStore carteiraStore;

  const SettingsScreen({
    super.key,
    required this.categoriesStore,
    required this.receitasStore,
    required this.despesasStore,
    required this.carteiraStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
      ),
      body: AnimatedBuilder(
        animation: widget.categoriesStore,
        builder: (context, _) {
          if (!widget.categoriesStore.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoriesCount = widget.categoriesStore.categories.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsHero(
                title: 'Preferencias',
                subtitle: 'Ajuste o app no seu ritmo.',
              ),
              const SizedBox(height: 16),
              _buildDespesasSection(categoriesCount),
              const SizedBox(height: 12),
              _buildAppearanceSection(),
              const SizedBox(height: 12),
              _buildFormattingSection(),
              const SizedBox(height: 12),
              _buildDataSection(),
              const SizedBox(height: 12),
              _buildAccountSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDespesasSection(int categoriesCount) {
    return _SettingsSection(
      title: 'Despesas',
      children: [
        _SettingsItem(
          title: 'Categorias',
          subtitle: 'Gerencie categorias globais',
          badge: '$categoriesCount',
          icon: Icons.category,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoriasScreen(store: widget.categoriesStore),
              ),
            );
          },
        ),
        _SettingsItem(
          title: 'Rotulos e cores',
          subtitle: 'Nomes e paleta do resumo',
          icon: Icons.palette_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LabelsColorsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _SettingsSection(
      title: 'Aparencia',
      children: [
        _SettingsItem(
          title: 'Tema e contraste',
          subtitle: 'Ajustes visuais do app',
          icon: Icons.auto_awesome,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppearanceScreen(),
              ),
            );
          },
        ),
        _SettingsItem(
          title: 'Tipografia',
          subtitle: 'Tamanho e estilo das fontes',
          icon: Icons.text_fields,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TypographyScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFormattingSection() {
    return _SettingsSection(
      title: 'Moeda e formato',
      children: [
        _SettingsItem(
          title: 'Moeda',
          subtitle: 'Escolha a moeda padrao',
          icon: Icons.attach_money,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FormattingScreen(),
              ),
            );
          },
        ),
        _SettingsItem(
          title: 'Formato de data',
          subtitle: 'Defina o padrao de exibicao',
          icon: Icons.date_range,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FormattingScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _SettingsSection(
      title: 'Dados',
      children: [
        _SettingsItem(
          title: 'Importar fatura (PDF)',
          subtitle: 'OCR para cartao de credito',
          icon: Icons.receipt_long,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FaturaImportScreen(
                  despesasStore: widget.despesasStore,
                  categoriesStore: widget.categoriesStore,
                ),
              ),
            );
          },
        ),
        _SettingsItem(
          title: 'Backup e restauracao',
          subtitle: 'Em breve',
          icon: Icons.cloud_upload_outlined,
          isDisabled: true,
        ),
        _SettingsItem(
          title: 'Exportar relatorio',
          subtitle: 'Em breve',
          icon: Icons.download_outlined,
          isDisabled: true,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _SettingsSection(
      title: 'Conta e dados',
      children: [
        _SettingsItem(
          title: 'Redefinir dados do app',
          subtitle: 'Apaga receitas, despesas, carteira e categorias',
          icon: Icons.restart_alt,
          isDestructive: true,
          onTap: _isBusy ? null : () => _confirmReset(deleteAccount: false),
        ),
        _SettingsItem(
          title: 'Excluir conta e dados',
          subtitle: 'Remove todos os dados e a conta do sistema',
          icon: Icons.delete_forever,
          isDestructive: true,
          onTap: _isBusy ? null : () => _confirmReset(deleteAccount: true),
        ),
      ],
    );
  }

  Future<void> _confirmReset({required bool deleteAccount}) async {
    final title = deleteAccount ? 'Excluir conta e dados?' : 'Redefinir dados do app?';
    final message = deleteAccount
        ? 'Essa acao remove todos os dados do Firestore e exclui sua conta.'
        : 'Essa acao remove todos os dados do Firestore e redefine o app.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _clearUserData(deleteAccount: deleteAccount);
  }

  Future<void> _clearUserData({required bool deleteAccount}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Nenhum usuario logado.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final batch = firestore.batch();
      batch.delete(userRef.collection('settings').doc('data'));
      batch.delete(userRef.collection('receitas').doc('data'));
      batch.delete(userRef.collection('despesas').doc('data'));
      batch.delete(userRef.collection('carteira').doc('data'));
      batch.delete(userRef.collection('categories').doc('data'));
      await batch.commit();

      if (!mounted) return;
      final settingsStore = AppSettingsScope.of(context);
      await Future.wait([
        widget.receitasStore.load(),
        widget.despesasStore.load(),
        widget.carteiraStore.load(),
        widget.categoriesStore.load(),
        settingsStore.loadForUser(user.uid),
      ]);

      if (deleteAccount) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          _showMessage(e.message ?? 'Falha ao excluir conta.');
          return;
        }
        await FirebaseAuth.instance.signOut();
      }

      _showMessage(deleteAccount ? 'Conta excluida.' : 'Dados redefinidos.');
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Falha ao limpar dados.');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsHero({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C8EC9).withValues(alpha: 0.3),
            const Color(0xFF1FAF86).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool isDestructive;

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.onTap,
    this.isDisabled = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? const Color(0xFFE36A4F) : Colors.white70,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? const Color(0xFFE36A4F) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
    );

    if (isDisabled) {
      return Opacity(
        opacity: 0.5,
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }
}
