import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rubrica_model.dart';

class IAService {
  // Obtén tu key gratis en: https://aistudio.google.com/apikey
  static const String _apiKey = 'AIzaSyDeFTwhI4eQIPuKytaNpmv9GHIdC_WAiPc';

  static const String _url =
    'https://generativelanguage.googleapis.com/v1beta/models/'
    'gemini-2.5-flash:generateContent?key=$_apiKey';

  Future<Map<String, dynamic>?> calificarConRubrica({
    required String textoPdf,
    required Rubrica rubrica,
  }) async {
    try {
      final criteriosTexto = rubrica.criterios
          .map((c) => '- ${c.nombre} (${c.peso}%): ${c.descripcion}')
          .join('\n');

      final criteriosJson = rubrica.criterios
          .map((c) =>
              '"${c.id}": {"calificacion": 0, "comentario": "..."}')
          .join(',\n    ');

      final prompt = '''
Eres un evaluador académico. Califica el siguiente trabajo usando la rúbrica proporcionada.

RÚBRICA: ${rubrica.nombre}
${rubrica.descripcion.isNotEmpty ? 'Descripción: ${rubrica.descripcion}' : ''}

CRITERIOS:
$criteriosTexto

TRABAJO DEL ALUMNO:
$textoPdf

INSTRUCCIONES:
1. Califica cada criterio del 0 al 10
2. Da un comentario específico y constructivo para cada criterio
3. Responde ÚNICAMENTE con JSON válido, sin texto adicional, sin markdown
4. Usa exactamente los IDs de los criterios proporcionados

FORMATO DE RESPUESTA (JSON exacto):
{
  "criterios": {
    $criteriosJson
  },
  "comentarioGeneral": "Comentario general sobre el trabajo"
}
''';

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1500,
          },
          'systemInstruction': {
            'parts': [
              {
                'text':
                    'Eres un evaluador académico justo y preciso. '
                    'Respondes ÚNICAMENTE con JSON válido, '
                    'sin markdown ni texto adicional.'
              }
            ]
          },
        }),
      );

      // PRINTS TEMPORALES PARA DEPURACIÓN
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final contenido =
          data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Limpiar posibles backticks de markdown
      final jsonLimpio = contenido
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonLimpio) as Map<String, dynamic>;
    } catch (e) {
      // PRINT TEMPORAL PARA DEPURACIÓN
      print('ERROR IA: $e');
      return null;
    }
  }
}