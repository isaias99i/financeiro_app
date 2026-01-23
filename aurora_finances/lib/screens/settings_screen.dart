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
import '../theme/app_tokens.dart';

// Tela principal de configuracoes do app.
class SettingsScreen extends StatefulWidget {
  final CategoriesStore categoriesStore;
  final ReceitasStore receitasStore;
  final ExpensesStore expensesStore;
  final CarteiraStore carteiraStore;

  // Tela principal de configuracoes do app.
  const SettingsScreen({
    super.key,
    required this.categoriesStore,
    required this.receitasStore,
    required this.expensesStore,
    required this.carteiraStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Estado da tela de configuracoes com secoes.
class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;

  // Monta a UI principal das configuracoes.
  @override
  // Monta a lista de secoes de configuracao.
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

  // Monta a secao de despesas e categorias.
  Widget _buildDespesasSection(int categoriesCount) {
    // Secao com itens de despesas e categorias.
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
                builder: (context) =>
                    CategoriesScreen(store: widget.categoriesStore),
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

  // Monta a secao de tema e tipografia.
  Widget _buildAppearanceSection() {
    // Secao de aparencia e tipografia.
    return _SettingsSection(
      title: 'Aparencia',
      children: [
        _SettingsItem(
          title: 'Tema',
          subtitle: 'Escolha o tema Aurora',
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

  // Monta a secao de formatos e moeda.
  Widget _buildFormattingSection() {
    // Secao de moeda e formato de data.
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

  // Monta a secao de dados e backup.
  Widget _buildDataSection() {
    // Secao de dados (importacao e recursos futuros).
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
                builder: (context) => InvoiceImportScreen(
                  expensesStore: widget.expensesStore,
                  entryCategoriesStore: widget.categoriesStore,
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

  // Monta a secao de conta e autenticacao.
  Widget _buildAccountSection() {
    // Secao de conta e gerenciamento de dados.
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
    // Confirma a acao antes de apagar dados ou excluir conta.
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
    // Limpa dados no Firestore e opcionalmente exclui a conta.
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
        widget.expensesStore.load(),
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

  // Exibe snackbar com feedback rapido.
  void _showMessage(String message) {
    // Feedback rapido para o usuario.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Cabecalho de destaque da tela de configuracoes.
class _SettingsHero extends StatelessWidget {
  final String title;
  final String subtitle;

  // Cabecalho visual das configuracoes.
  const _SettingsHero({
    required this.title,
    required this.subtitle,
  });

  @override
  // Monta o cabecalho com titulo e subtitulo.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tokens.heroGradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.settings, color: tokens.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card base para cada secao de configuracao.
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  // Agrupador visual para itens de configuracao.
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  // Monta a estrutura visual da secao.
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.textPrimary,
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

// Item de acao dentro da secao.
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
  // Monta o item de lista clicavel.
  Widget build(BuildContext context) {
    // Item clicavel padrao das configuracoes.
    final tokens = AppThemeTokens.of(context);
    final content = ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? tokens.danger : tokens.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? tokens.danger : tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: tokens.textMuted),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: TextStyle(color: tokens.textPrimary, fontSize: 12),
              ),
            )
          : Icon(Icons.chevron_right, color: tokens.textMuted),
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
