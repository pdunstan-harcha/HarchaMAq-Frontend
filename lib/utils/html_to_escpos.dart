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

      // Buscar elementos dentro del header (fecha y código)
      final header = document.getElementsByClassName('header');
      if (header.isNotEmpty) {
        final divs = header.first.getElementsByTagName('div');
        for (var div in divs) {
          final text = div.text.trim();
          if (text.isNotEmpty) {
            buffer.write(ALIGN_CENTER);
            buffer.write(BOLD_ON);
            buffer.write('$text$LINE_FEED');
            buffer.write(BOLD_OFF);
          }
        }
      }

      // Buscar datos de la empresa (company-info o datosHarcha)
      var companyInfo = document.getElementsByClassName('company-info');
      if (companyInfo.isEmpty) {
        companyInfo = document.getElementsByClassName('datosHarcha');
      }

      if (companyInfo.isNotEmpty) {
        buffer.write(ALIGN_CENTER);
        final text = companyInfo.first.text;
        final lines = text.split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            buffer.write('$trimmed$LINE_FEED');
          }
        }
        buffer.write(LINE_FEED);
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

      // Buscar la tabla principal con los datos del recibo (data-table)
      final dataTables = document.getElementsByClassName('data-table');
      if (dataTables.isNotEmpty) {
        buffer.write(ALIGN_LEFT);
        final rows = dataTables.first.getElementsByTagName('tr');

        for (var row in rows) {
          final cells = row.getElementsByTagName('td');

          if (cells.length >= 2) {
            final label = cells[0].text.trim();
            final value = cells[1].text.trim();

            if (label.isNotEmpty) {
              buffer.write(BOLD_ON);
              buffer.write(label);
              buffer.write(BOLD_OFF);
              buffer.write(' $value$LINE_FEED');
            }
          }
        }
        buffer.write(LINE_FEED);
      }

      // Buscar observaciones
      final obsLabel = document.getElementsByClassName('obs-label');
      final obsText = document.getElementsByClassName('obs-text');

      if (obsLabel.isNotEmpty) {
        buffer.write(ALIGN_LEFT);
        buffer.write(BOLD_ON);
        buffer.write('${obsLabel.first.text.trim()}$LINE_FEED');
        buffer.write(BOLD_OFF);

        if (obsText.isNotEmpty) {
          final text = obsText.first.text.trim();
          if (text.isNotEmpty) {
            buffer.write('$text$LINE_FEED');
          }
        }
        buffer.write(LINE_FEED);
      }

      // Buscar sección de firmas
      final signatures = document.getElementsByClassName('signatures');
      if (signatures.isNotEmpty) {
        buffer.write(ALIGN_LEFT);
        buffer.write('_' * 42); // Línea de separación
        buffer.write(LINE_FEED);
        buffer.write(LINE_FEED);

        // Buscar divs con class sig-line
        final sigLines = document.getElementsByClassName('sig-line');
        final sigNames = signatures.first.getElementsByTagName('strong');

        if (sigLines.length >= 2 && sigNames.length >= 2) {
          // Firma operador
          buffer.write('${sigLines[0].text.trim()}$LINE_FEED');
          buffer.write('${sigNames[0].text.trim()}$LINE_FEED');
          buffer.write(LINE_FEED);

          // Firma encargado
          buffer.write('${sigLines[1].text.trim()}$LINE_FEED');
          buffer.write('${sigNames[1].text.trim()}$LINE_FEED');
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
