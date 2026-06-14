class PickLeg {
  final int matchId;
  final String liga;
  final String deporte;
  final String enfrentamiento;
  final String tipo;        // ganador | ponches | total | prop_nba
  final String seleccion;
  final double probabilidad;
  final int confianza;

  PickLeg({
    required this.matchId,
    required this.liga,
    required this.deporte,
    required this.enfrentamiento,
    required this.tipo,
    required this.seleccion,
    required this.probabilidad,
    required this.confianza,
  });

  factory PickLeg.fromJson(Map<String, dynamic> j) => PickLeg(
        matchId: (j['match_id'] as num?)?.toInt() ?? 0,
        liga: j['liga'] ?? '',
        deporte: j['deporte'] ?? '',
        enfrentamiento: j['enfrentamiento'] ?? '',
        tipo: j['tipo'] ?? '',
        seleccion: j['seleccion'] ?? '',
        probabilidad: (j['probabilidad'] as num?)?.toDouble() ?? 0,
        confianza: (j['confianza'] as num?)?.toInt() ?? 0,
      );

  String get emoji {
    switch (deporte) {
      case 'baseball':
        return '⚾';
      case 'basketball':
        return '🏀';
      case 'american_football':
        return '🏈';
      default:
        return '⚽';
    }
  }
}

class PickTier {
  final List<PickLeg> jugadas;
  final double probabilidadCombinada;
  final bool completo;

  PickTier({required this.jugadas, required this.probabilidadCombinada, required this.completo});

  factory PickTier.fromJson(Map<String, dynamic> j) => PickTier(
        jugadas: ((j['jugadas'] as List?) ?? [])
            .map((e) => PickLeg.fromJson(e as Map<String, dynamic>))
            .toList(),
        probabilidadCombinada: (j['probabilidad_combinada'] as num?)?.toDouble() ?? 0,
        completo: j['completo'] == true,
      );
}

class PicksDelDia {
  final String fecha;
  final int juegosAnalizados;
  final int juegosYaEmpezados;
  final String? aviso;
  final PickTier fija;
  final PickTier dupleta;
  final PickTier tripleta;
  final PickTier pick7;

  PicksDelDia({
    required this.fecha,
    required this.juegosAnalizados,
    required this.juegosYaEmpezados,
    this.aviso,
    required this.fija,
    required this.dupleta,
    required this.tripleta,
    required this.pick7,
  });

  factory PicksDelDia.fromJson(Map<String, dynamic> j) => PicksDelDia(
        fecha: j['fecha'] ?? '',
        juegosAnalizados: (j['juegos_analizados'] as num?)?.toInt() ?? 0,
        juegosYaEmpezados: (j['juegos_ya_empezados'] as num?)?.toInt() ?? 0,
        aviso: j['aviso'],
        fija: PickTier.fromJson(j['fija'] ?? {}),
        dupleta: PickTier.fromJson(j['dupleta'] ?? {}),
        tripleta: PickTier.fromJson(j['tripleta'] ?? {}),
        pick7: PickTier.fromJson(j['pick_7'] ?? {}),
      );
}
