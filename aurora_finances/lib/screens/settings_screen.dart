import 'package:flutter/material.dart';

import '../data/categories_store.dart';
import '../screens/categorias_screen.dart';
import '../screens/appearance_screen.dart';
import '../screens/labels_colors_screen.dart';
import '../screens/formatting_screen.dart';
import '../screens/typography_screen.dart';
import '../widgets/aurora_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  final CategoriesStore categoriesStore;

  const SettingsScreen({super.key, required this.categoriesStore});

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      appBar: AppBar(
        title: const Text('Configuracoes'),
      ),
      body: AnimatedBuilder(
        animation: categoriesStore,
        builder: (context, _) {
          if (!categoriesStore.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoriesCount = categoriesStore.categories.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsHero(
                title: 'Preferencias',
                subtitle: 'Ajuste o app no seu ritmo.',
              ),
              const SizedBox(height: 16),
              _SettingsSection(
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
                          builder: (context) => CategoriasScreen(store: categoriesStore),
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
              ),
              const SizedBox(height: 12),
              _SettingsSection(
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
              ),
              const SizedBox(height: 12),
              _SettingsSection(
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
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Dados',
                children: [
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
              ),
            ],
          );
        },
      ),
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

  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.onTap,
    this.isDisabled = false,
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
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
