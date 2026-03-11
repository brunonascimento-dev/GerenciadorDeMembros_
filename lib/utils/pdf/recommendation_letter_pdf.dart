import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../date_formatters.dart';

class RecommendationLetterPdf {
  /// Gera o PDF e abre o menu de compartilhamento do celular
  static Future<void> generateAndShare({
    required Member member,
    required String destinationCity,
    required String destinationChurch,
    required DateTime validUntil,
    String churchName = 'Igreja Evangélica Local', // Nome padrão ou vindo de config
  }) async {
    final doc = pw.Document();

    // Carrega uma fonte padrão (Helvetica já vem embutida no PDF, mas isso garante compatibilidade)
    final fontRegular = pw.Font.courier();
    final fontBold = pw.Font.courierBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // --- CABEÇALHO ---
              pw.Text(
                churchName.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: 18),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Departamento de Secretaria',
                style: pw.TextStyle(font: fontRegular, fontSize: 12),
              ),
              pw.Divider(thickness: 1, height: 40),

              // --- TÍTULO ---
              pw.SizedBox(height: 20),
              pw.Text(
                'CARTA DE RECOMENDAÇÃO',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 40),

              // --- CORPO DO TEXTO ---
              pw.Paragraph(
                style: pw.TextStyle(font: fontRegular, fontSize: 14, lineSpacing: 5),
                text: 'Saudamos a amada igreja com a Paz do Senhor.',
              ),
              
              pw.SizedBox(height: 15),

              // Texto Rico para colocar negrito nas variáveis
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: pw.TextStyle(font: fontRegular, fontSize: 14, lineSpacing: 5),
                  children: [
                    const pw.TextSpan(text: 'Servimo-nos da presente para recomendar o(a) portador(a) desta, o(a) irmão(ã) '),
                    pw.TextSpan(
                      text: member.nome.toUpperCase(),
                      style: pw.TextStyle(font: fontBold),
                    ),
                    const pw.TextSpan(text: ', que exerce o cargo de '),
                    pw.TextSpan(
                      text: (member.cargo ?? 'Membro').toUpperCase(),
                      style: pw.TextStyle(font: fontBold),
                    ),
                    const pw.TextSpan(text: ' em nossa congregação.'),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: pw.TextStyle(font: fontRegular, fontSize: 14, lineSpacing: 5),
                  children: [
                    const pw.TextSpan(
                      text: 'Declaramos que o(a) referido(a) é membro em plena comunhão, não constando nada, '
                          'até a presente data, que desabone sua conduta cristã e moral. Sendo assim, '
                          'recomendamos que o(a) recebam no Senhor para a igreja em ',
                    ),
                    pw.TextSpan(
                      text: '$destinationChurch ($destinationCity)'.toUpperCase(),
                      style: pw.TextStyle(font: fontBold),
                    ),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'Esta carta tem validade até: ${DateFormatters.simple(validUntil)}.',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),

              pw.Spacer(),

              // --- RODAPÉ E ASSINATURA ---
              pw.Text(
                'Itapicuru - BA, ${DateFormatters.fullDate(DateTime.now())}',
                style: pw.TextStyle(font: fontRegular, fontSize: 12),
              ),
              
              pw.SizedBox(height: 50),
              
              pw.Container(
                width: 250,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(width: 1)),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Pastor / Responsável',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Abre o menu de compartilhar (Share) do celular
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'carta_recomendacao_${member.nome.replaceAll(' ', '_')}.pdf',
    );
  }
}