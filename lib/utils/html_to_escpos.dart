import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlToEscPos {
  // Comandos ESC/POS básicos
  static const ESC = '\x1B';
  static const GS = '\x1D';

  // Inicializar impresora
  static const INIT = '$ESC@';

  // Alineación
  static const ALIGN_LEFT = '${ESC}a\x00';
  static const ALIGN_CENTER = '${ESC}a\x01';
  static const ALIGN_RIGHT = '${ESC}a\x02';

  // Formato de texto
  static const BOLD_ON = '${ESC}E\x01';
  static const BOLD_OFF = '${ESC}E\x00';
  static const UNDERLINE_ON = '${ESC}-\x01';
  static const UNDERLINE_OFF = '${ESC}-\x00';
  static const DOUBLE_HEIGHT = '${GS}!\x01';
  static const NORMAL_SIZE = '${GS}!\x00';

  // Línea y papel
  static const LINE_FEED = '\n';
  static const CUT_PAPER = '${GS}V\x00';

  /// Convierte HTML a comandos ESC/POS
  static String convertHtmlToEscPos(String htmlString) {
    final document = html_parser.parse(htmlString);
    final buffer = StringBuffer();

    // Inicializar impresora
    buffer.write(INIT);

    try {
      // Buscar el logo/header
      final imgTags = document.getElementsByTagName('img');
      if (imgTags.isNotEmpty) {
        buffer.write(ALIGN_CENTER);
        buffer.write('[LOGO HARCHA]$LINE_FEED');
      }

      // Buscar la fecha y número de recibo
      final strongTags = document.getElementsByTagName('strong');
      for (var tag in strongTags) {
        final text = tag.text.trim();
        if (text.isNotEmpty && !text.startsWith('N°')) {
          buffer.write(ALIGN_CENTER);
          buffer.write(BOLD_ON);
          buffer.write('$text$LINE_FEED');
          buffer.write(BOLD_OFF);
        }
      }

      // Buscar el título principal (ORDEN ENTREGA COMBUSTIBLES)
      final h4Tags = document.getElementsByTagName('h4');
      for (var tag in h4Tags) {
        final text = tag.text.trim();
        if (text.isNotEmpty) {
          buffer.write(ALIGN_CENTER);
          buffer.write(DOUBLE_HEIGHT);
          buffer.write(BOLD_ON);
          buffer.write('$text$LINE_FEED');
          buffer.write(NORMAL_SIZE);
          buffer.write(BOLD_OFF);
          buffer.write(LINE_FEED);
        }
      }

      // Buscar datos de Harcha (RUT, dirección, etc.)
      final datosHarcha = document.getElementsByClassName('datosHarcha');
      if (datosHarcha.isNotEmpty) {
        buffer.write(ALIGN_CENTER);
        final lines = datosHarcha.first.text.split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            buffer.write('$trimmed$LINE_FEED');
          }
        }
        buffer.write(LINE_FEED);
      }

      // Buscar la tabla principal con los datos del recibo
      final tables = document.getElementsByTagName('table');
      for (var table in tables) {
        final rows = table.getElementsByTagName('tr');

        buffer.write(ALIGN_LEFT);

        for (var row in rows) {
          final cells = row.getElementsByTagName('td');

          if (cells.length >= 2) {
            final label = cells[0].text.trim();
            final value = cells[1].text.trim();

            if (label.isNotEmpty) {
              // Formatear como "LABEL: valor"
              buffer.write(BOLD_ON);
              buffer.write(label);
              buffer.write(BOLD_OFF);
              buffer.write(' $value$LINE_FEED');
            }
          } else if (cells.length == 1) {
            final text = cells[0].text.trim();
            if (text.isNotEmpty) {
              buffer.write('$text$LINE_FEED');
            }
          }
        }

        buffer.write(LINE_FEED);
      }

      // Buscar sección de firmas
      final signatureTables = document.querySelectorAll('table[border="0"]');
      if (signatureTables.length > 1) {
        buffer.write(ALIGN_LEFT);
        buffer.write('$LINE_FEED');
        buffer.write('_' * 42); // Línea de separación
        buffer.write(LINE_FEED);

        // Buscar las celdas de firma
        final lastTable = signatureTables.last;
        final rows = lastTable.getElementsByTagName('tr');

        for (var row in rows) {
          final cells = row.getElementsByTagName('td');
          final texts = cells.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

          if (texts.isNotEmpty) {
            buffer.write(texts.join(' | '));
            buffer.write(LINE_FEED);
          }
        }
      }

    } catch (e) {
      print('Error al parsear HTML: $e');
      // Fallback: imprimir texto plano sin formato
      buffer.write(ALIGN_LEFT);
      buffer.write('Error al procesar recibo$LINE_FEED');
      buffer.write(document.body?.text ?? 'Sin contenido');
    }

    // Finalizar con saltos de línea y corte
    buffer.write(LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write(LINE_FEED);
    buffer.write(CUT_PAPER);

    return buffer.toString();
  }

  /// Convierte texto ESC/POS a base64 para RawBT
  static String toBase64(String escPosText) {
    final bytes = utf8.encode(escPosText);
    return base64.encode(bytes);
  }
}
