import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

/// Guía "Cómo usar Veredicto" — páginas deslizantes premium. Reutilizable:
/// se abre desde el botón "?" de Picks, desde Perfil, y una sola vez automática.
class GuiaScreen extends StatefulWidget {
  const GuiaScreen({super.key});

  static const _flag = 'guia_picks_vista';

  /// True si nunca se ha visto (para auto-apertura única).
  static Future<bool> debeMostrarse() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_flag) ?? false);
  }

  static Future<void> marcarVista() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flag, true);
  }

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  final _ctrl = PageController();
  int _page = 0;

  late final List<_Pagina> _paginas = [
    _Pagina(
      emoji: '🔮',
      color: kAccent,
      titulo: 'BIENVENIDO A VEREDICTO',
      cuerpo: 'No adivinamos: analizamos. Un motor estadístico evalúa miles de '
          'datos por partido (forma, pitchers, ratings, lesiones, cara a cara) '
          'para darte pronósticos con respaldo real.',
      ejemplo: _ChipsEjemplo(const [
        ('TASA DE ACIERTO', '63%', kGreen),
        ('VERIFICADO', '✓', kAccent3),
      ]),
    ),
    _Pagina(
      emoji: '⭐',
      color: kGold,
      titulo: 'EL PICK DEL DÍA COMPLETO',
      cuerpo: 'Es NUESTRO MEJOR pronóstico y el más responsable. Se arma cada '
          'mañana, antes de que empiecen los juegos de MLB, con la jornada '
          'fuerte completa. Si vas a confiar en uno, que sea este.',
      ejemplo: _BannerEjemplo(
        icon: Icons.verified_rounded,
        color: kGreen,
        texto: 'Pick del Día completo — la jornada fuerte está activa',
      ),
    ),
    _Pagina(
      emoji: '🟡',
      color: kGold,
      titulo: 'PICKS PARCIALES',
      cuerpo: 'Cuando los juegos grandes ya empezaron, la app rearma picks SOLA '
          'con los partidos que quedan. OJO: estos NO son las fijas — se arman '
          'con lo disponible. Úsalos bajo tu criterio, no son nuestra recomendación principal.',
      ejemplo: _BannerEjemplo(
        icon: Icons.access_time_rounded,
        color: kGold,
        texto: 'Pick parcial — los juegos principales ya comenzaron',
      ),
    ),
    _Pagina(
      emoji: '🎯',
      color: kAccent,
      titulo: 'LOS NIVELES',
      cuerpo: 'La Fija (1 jugada) es la más segura. La Dupleta (2), Tripleta (3) '
          'y Pick de 7 combinan más jugadas. La verdad: a más patas, más premio '
          'pero MENOS probabilidad de pegarlas todas. Elige según tu riesgo.',
      ejemplo: _ChipsEjemplo(const [
        ('FIJA', '+seguro', kGreen),
        ('TRIPLETA', 'medio', kGold),
        ('PICK 7', '+premio', kAccent2),
      ]),
    ),
    _Pagina(
      emoji: '🔬',
      color: kAccent3,
      titulo: 'ARMA TUS PROPIOS PICKS',
      cuerpo: 'Veredicto es tu material de apoyo. Abre cualquier partido y vas a '
          'ver el análisis completo: ratings ofensivo/defensivo, forma reciente, '
          'pitchers y ERA, lesiones, cara a cara y props. Aprende a leerlo y arma '
          'tu propia jugada con criterio.',
      ejemplo: _MiniAnalisis(),
    ),
    _Pagina(
      emoji: '✅',
      color: kGreen,
      titulo: 'JUEGA RESPONSABLE',
      cuerpo: 'Ninguna jugada es 100% segura — el deporte tiene sorpresas. '
          'Nuestra tasa de acierto es una guía de confianza, no una promesa. '
          'Verifica siempre y apuesta solo lo que puedas permitirte.',
      ejemplo: const SizedBox.shrink(),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cerrar() {
    GuiaScreen.marcarVista();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _page == _paginas.length - 1;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text('GUÍA VEREDICTO', style: bebasNeue(16, color: kMuted, letterSpacing: 1.5)),
                  const Spacer(),
                  TextButton(
                    onPressed: _cerrar,
                    child: Text(ultima ? '' : 'Saltar',
                        style: dmSans(13, color: kMuted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _paginas.length,
                itemBuilder: (_, i) => _vistaPagina(_paginas[i]),
              ),
            ),
            // Puntos de progreso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_paginas.length, (i) {
                final activo = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: activo ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: activo ? _paginas[_page].color : kMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Botón
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paginas[_page].color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (ultima) {
                      _cerrar();
                    } else {
                      _ctrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(ultima ? 'ENTENDIDO' : 'SIGUIENTE',
                      style: bebasNeue(18, color: Colors.black, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaPagina(_Pagina p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: p.color.withValues(alpha: 0.4)),
            ),
            child: Text(p.emoji, style: const TextStyle(fontSize: 38)),
          ),
          const SizedBox(height: 22),
          Text(p.titulo, style: bebasNeue(30, color: kText, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(p.cuerpo, style: dmSans(14, color: kMuted).copyWith(height: 1.5)),
          const SizedBox(height: 22),
          p.ejemplo,
        ],
      ),
    );
  }
}

class _Pagina {
  final String emoji;
  final Color color;
  final String titulo;
  final String cuerpo;
  final Widget ejemplo;
  _Pagina({
    required this.emoji,
    required this.color,
    required this.titulo,
    required this.cuerpo,
    required this.ejemplo,
  });
}

// ── Mini-ejemplos visuales ─────────────────────────────────────────────────────

class _ChipsEjemplo extends StatelessWidget {
  final List<(String, String, Color)> items;
  const _ChipsEjemplo(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: it.$3.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: it.$3.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(it.$1, style: jetMono(10, color: kMuted, weight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(it.$2, style: bebasNeue(16, color: it.$3)),
          ]),
        );
      }).toList(),
    );
  }
}

class _BannerEjemplo extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;
  const _BannerEjemplo({required this.icon, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: dmSans(12, color: kText))),
      ]),
    );
  }
}

class _MiniAnalisis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget fila(String etq, String val, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(etq, style: dmSans(11, color: kMuted)),
            const Spacer(),
            Text(val, style: jetMono(12, color: c, weight: FontWeight.w700)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EJEMPLO DE ANÁLISIS', style: jetMono(9, color: kMuted, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        fila('Ofensiva / Defensiva', '116.4 / 108.5', kGreen),
        fila('Forma reciente', '8V - 2D', kAccent),
        fila('Pitcher (ERA)', '3.16', kGold),
        fila('Cara a cara', '4 - 1', kAccent3),
      ]),
    );
  }
}
