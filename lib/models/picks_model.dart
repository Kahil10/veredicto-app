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
  final int jugadasDisponibles;
  final int nsTotal;
  final String estado;          // completo | parcial | pocos | sin_juegos
  final String? mensajeHorario;
  final int pickMaxN;
  final List<PickLeg> juegosRestantes;           // patas reales del pick grande
  final PickTier fija;
  final PickTier dupleta;
  final PickTier tripleta;
  final PickTier pick7;

  PicksDelDia({
    required this.fecha,
    required this.juegosAnalizados,
    required this.juegosYaEmpezados,
    required this.jugadasDisponibles,
    required this.nsTotal,
    required this.estado,
    this.mensajeHorario,
    required this.pickMaxN,
    required this.juegosRestantes,
    required this.fija,
    required this.dupleta,
    required this.tripleta,
    required this.pick7,
  });

  bool get esParcial => estado == 'parcial';
  bool get esPocos => estado == 'pocos';
  bool get esSinJuegos => estado == 'sin_juegos';
  bool get esCompleto => estado == 'completo';

  factory PicksDelDia.fromJson(Map<String, dynamic> j) => PicksDelDia(
        fecha: j['fecha'] ?? '',
        juegosAnalizados: (j['juegos_analizados'] as num?)?.toInt() ?? 0,
        juegosYaEmpezados: (j['juegos_ya_empezados'] as num?)?.toInt() ?? 0,
        jugadasDisponibles: (j['jugadas_disponibles'] as num?)?.toInt() ?? 0,
        nsTotal: (j['ns_total'] as num?)?.toInt() ?? 0,
        estado: j['estado'] ?? 'completo',
        mensajeHorario: j['mensaje_horario'] ?? j['aviso'],
        pickMaxN: (j['pick_max_n'] as num?)?.toInt() ?? 0,
        juegosRestantes: ((j['juegos_restantes'] as List?) ?? [])
            .map((e) => PickLeg.fromJson(e as Map<String, dynamic>))
            .toList(),
        fija: PickTier.fromJson(j['fija'] ?? {}),
        dupleta: PickTier.fromJson(j['dupleta'] ?? {}),
        tripleta: PickTier.fromJson(j['tripleta'] ?? {}),
        pick7: PickTier.fromJson(j['pick_7'] ?? {}),
      );
}
