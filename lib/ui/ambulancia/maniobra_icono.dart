import 'package:flutter/material.dart';

/// Traduce el campo `maneuver` de Google Directions al icono de flecha
/// correspondiente, usado por la píldora de navegación del mapa.
IconData iconoManiobra(String maniobra) => switch (maniobra) {
      'turn-right' => Icons.turn_right,
      'turn-left' => Icons.turn_left,
      'turn-slight-right' => Icons.turn_slight_right,
      'turn-slight-left' => Icons.turn_slight_left,
      'turn-sharp-right' => Icons.turn_sharp_right,
      'turn-sharp-left' => Icons.turn_sharp_left,
      'uturn-right' => Icons.u_turn_right,
      'uturn-left' => Icons.u_turn_left,
      'roundabout-right' => Icons.roundabout_right,
      'roundabout-left' => Icons.roundabout_left,
      'fork-right' || 'ramp-right' => Icons.fork_right,
      'fork-left' || 'ramp-left' => Icons.fork_left,
      'merge' => Icons.merge,
      _ => Icons.straight,
    };
