import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/event_model.dart';
import 'dart:math'; // Necessário para a função min()

class PdfService {
  // --- PARTE 1: CARTA DE RECOMENDAÇÃO (Igual ao anterior) ---
  Future<void> generateRecommendationLetter({
    required Member member,
    required String destinationCity,
    required String destinationChurch,
    String churchName = 'Igreja Evangélica Local',
  }) async {
    final doc = pw.Document();
    final fontRegular = pw.Font.courier();
    final fontBold = pw.Font.courierBold();
    final dateFormat = DateFormat("d 'de' MMMM 'de' y", "pt_BR");

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(churchName.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text('Departamento de Secretaria',
                  style: pw.TextStyle(font: fontRegular, fontSize: 12)),
              pw.Divider(thickness: 1, height: 40),
              pw.SizedBox(height: 20),
              pw.Text('CARTA DE RECOMENDAÇÃO',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 20,
                      decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 40),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: pw.TextStyle(
                      font: fontRegular, fontSize: 14, lineSpacing: 5),
                  children: [
                    const pw.TextSpan(
                        text:
                            'Servimo-nos da presente para recomendar o(a) portador(a) desta, o(a) irmão(ã) '),
                    pw.TextSpan(
                        text: member.nome.toUpperCase(),
                        style: pw.TextStyle(font: fontBold)),
                    const pw.TextSpan(text: ', que exerce o cargo de '),
                    pw.TextSpan(
                        text: (member.cargo ?? 'Membro').toUpperCase(),
                        style: pw.TextStyle(font: fontBold)),
                    const pw.TextSpan(text: ' em nossa congregação.\n\n'),
                    const pw.TextSpan(
                        text:
                            'Declaramos que o(a) referido(a) é membro em plena comunhão, não constando nada que desabone sua conduta. Recomendamos que o recebam no Senhor na igreja em '),
                    pw.TextSpan(
                        text: '$destinationChurch ($destinationCity)'
                            .toUpperCase(),
                        style: pw.TextStyle(font: fontBold)),
                    const pw.TextSpan(text: '.'),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Text('Itapicuru - BA, ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 12)),
              pw.SizedBox(height: 50),
              pw.Container(
                  width: 250,
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(width: 1)))),
              pw.SizedBox(height: 5),
              pw.Text('Pastor / Responsável',
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'carta_${member.nome}.pdf');
  }

  Future<void> generateFinancialReport({
    required int month,
    required int year,
    required List<FinancialEntry> fixedIncomes,
    required List<FinancialEntry> fixedExpenses,
    required List<FinancialEntry> variableIncomes,
    required List<FinancialEntry> variableExpenses,
  }) async {
    final doc = pw.Document();
    final monthName = DateFormat('MMMM', 'pt_BR').format(DateTime(year, month));
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    double sum(List<FinancialEntry> values) =>
        values.fold(0, (total, entry) => total + entry.amount);

    final totalFixedIncomes = sum(fixedIncomes);
    final totalVariableIncomes = sum(variableIncomes);
    final totalFixedExpenses = sum(fixedExpenses);
    final totalVariableExpenses = sum(variableExpenses);

    final totalIncomes = totalFixedIncomes + totalVariableIncomes;
    final totalExpenses = totalFixedExpenses + totalVariableExpenses;
    final balance = totalIncomes - totalExpenses;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Relatório Financeiro',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${monthName[0].toUpperCase()}${monthName.substring(1)}/$year',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          _buildFinancialSection('Entradas Fixas', fixedIncomes, currency),
          pw.SizedBox(height: 12),
          _buildFinancialSection(
              'Entradas Não Fixas', variableIncomes, currency),
          pw.SizedBox(height: 12),
          _buildFinancialSection('Despesas Fixas', fixedExpenses, currency),
          pw.SizedBox(height: 12),
          _buildFinancialSection(
              'Despesas Não Fixas', variableExpenses, currency),
          pw.SizedBox(height: 16),
          _buildFinancialSummary(
            currency: currency,
            totalFixedIncomes: totalFixedIncomes,
            totalVariableIncomes: totalVariableIncomes,
            totalFixedExpenses: totalFixedExpenses,
            totalVariableExpenses: totalVariableExpenses,
            totalIncomes: totalIncomes,
            totalExpenses: totalExpenses,
            balance: balance,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // --- PARTE 2: RELATÓRIO MENSAL INTELIGENTE (PAGINADO) ---
  Future<void> generateMonthlyReport(
    List<Member> members,
    List<EventModel> rawEvents,
    String congregationName,
    int month,
    int year,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM', 'pt_BR').format(DateTime(year, month));

    // 1. FUNDIR EVENTOS DUPLICADOS (Mesma lógica de antes)
    final Map<String, EventModel> mergedEventsMap = {};
    for (var event in rawEvents) {
      final key = '${event.date.day}-${event.type}';
      if (mergedEventsMap.containsKey(key)) {
        final existing = mergedEventsMap[key]!;
        final combinedPresence =
            {...existing.presentMemberIds, ...event.presentMemberIds}.toList();
        mergedEventsMap[key] = EventModel(
          id: existing.id,
          congregationId: existing.congregationId,
          date: existing.date,
          type: existing.type,
          presentMemberIds: combinedPresence,
        );
      } else {
        mergedEventsMap[key] = event;
      }
    }

    final allEvents = mergedEventsMap.values.toList();
    allEvents.sort((a, b) {
      int dateComp = a.date.compareTo(b.date);
      return (dateComp == 0) ? a.type.compareTo(b.type) : dateComp;
    });

    // 2. ORDENAR MEMBROS
    final uniqueMembers = <String, Member>{};
    for (var m in members) {
      uniqueMembers.putIfAbsent(m.id!, () => m);
    }
    final sortedMembers = uniqueMembers.values.toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    // 3. PAGINAÇÃO HORIZONTAL (QUEBRA DE COLUNAS)
    // Quantas colunas de evento cabem por página confortavelmente?
    const int eventsPerPage = 12;
    int currentEventIndex = 0;

    // Se não tiver eventos, gera pelo menos uma página vazia
    if (allEvents.isEmpty) {
      _addReportPage(pdf, sortedMembers, [], congregationName, monthName, year,
          isLastPage: true, allEventsRef: []);
    } else {
      // Loop para criar várias páginas se tiver muitos eventos
      while (currentEventIndex < allEvents.length) {
        // Pega o pedaço (chunk) de eventos para esta página
        final int endIndex =
            min(currentEventIndex + eventsPerPage, allEvents.length);
        final List<EventModel> pageEvents =
            allEvents.sublist(currentEventIndex, endIndex);

        // Verifica se é a última página (para adicionar a coluna de Frequência Total)
        final bool isLastPage = endIndex == allEvents.length;

        _addReportPage(
            pdf, sortedMembers, pageEvents, congregationName, monthName, year,
            isLastPage: isLastPage,
            allEventsRef: allEvents // Passa todos para calcular a % correta
            );

        currentEventIndex += eventsPerPage;
      }
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // --- FUNÇÃO AUXILIAR PARA DESENHAR A PÁGINA ---
  void _addReportPage(
    pw.Document pdf,
    List<Member> members,
    List<EventModel> pageEvents,
    String congName,
    String monthName,
    int year, {
    required bool isLastPage,
    required List<EventModel> allEventsRef,
  }) {
    // Cabeçalhos
    final headers = ['Membro'];

    // Adiciona cabeçalhos dos eventos desta página
    for (var e in pageEvents) {
      final dia = DateFormat('dd/MM').format(e.date);
      String tipo = e.type == 'Santa Ceia' ? 'S. Ceia' : e.type;
      headers.add('$dia\n$tipo');
    }

    // Só adiciona a coluna Freq se for a última leva de colunas
    if (isLastPage) {
      headers.add('Freq.\nTotal');
    }

    // Dados das linhas
    final data = <List<String>>[];

    for (var member in members) {
      // Abrevia nome
      final nome = member.nome.length > 20
          ? '${member.nome.substring(0, 18)}...'
          : member.nome;
      final row = <String>[nome];

      // Preenche presença APENAS dos eventos desta página
      for (var event in pageEvents) {
        final present = event.presentMemberIds.contains(member.id);
        row.add(present ? 'P' : '.');
      }

      // Se for a última página, calcula a porcentagem baseada em TODOS os eventos do mês
      if (isLastPage) {
        int totalPresencas = 0;
        for (var e in allEventsRef) {
          if (e.presentMemberIds.contains(member.id)) totalPresencas++;
        }
        final percent = allEventsRef.isEmpty
            ? 0
            : (totalPresencas / allEventsRef.length) * 100;
        row.add('${percent.toStringAsFixed(0)}%');
      }

      data.add(row);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      'Relatório - $congName (Parte ${pageEvents.isNotEmpty ? "${pageEvents.first.date.day}-${pageEvents.last.date.day}" : "Geral"})',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('$monthName/$year',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              )),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {0: pw.Alignment.centerLeft},
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
                "Legenda: P = Presente | . = Ausente | Continua na próxima página...",
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialSection(
    String title,
    List<FinancialEntry> entries,
    NumberFormat currency,
  ) {
    if (entries.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 4),
          pw.Text('Nenhum item informado.'),
        ],
      );
    }

    final rows = entries
        .map((entry) => [entry.description, currency.format(entry.amount)])
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: const ['Descrição', 'Valor'],
          data: rows,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight
          },
        ),
      ],
    );
  }

  pw.Widget _buildFinancialSummary({
    required NumberFormat currency,
    required double totalFixedIncomes,
    required double totalVariableIncomes,
    required double totalFixedExpenses,
    required double totalVariableExpenses,
    required double totalIncomes,
    required double totalExpenses,
    required double balance,
  }) {
    final rows = [
      ['Total Entradas Fixas', currency.format(totalFixedIncomes)],
      ['Total Entradas Não Fixas', currency.format(totalVariableIncomes)],
      ['Total Despesas Fixas', currency.format(totalFixedExpenses)],
      ['Total Despesas Não Fixas', currency.format(totalVariableExpenses)],
      ['Total de Entradas', currency.format(totalIncomes)],
      ['Total de Despesas', currency.format(totalExpenses)],
      ['Saldo do Mês', currency.format(balance)],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Resumo',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Indicador', 'Valor'],
          data: rows,
          border: pw.TableBorder.all(color: PdfColors.grey400),
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight
          },
        ),
      ],
    );
  }
}
