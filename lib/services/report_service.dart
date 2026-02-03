import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class ReportService {
  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _monthFormatter = DateFormat('MMMM yyyy', 'es');

  static Future<void> generateGeneralReport(
    List<TaskModel> tasks,
    String reportTitle, {
    bool isMonthly = false,
    bool isWeekly = false,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // SOLUCIÓN AL ERROR DE UNICODE: Usar fuentes que soporten tildes y emojis
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // 1. TÍTULOS DINÁMICOS SEGÚN REGLAS
    String finalTitle = reportTitle;
    if (isMonthly) {
      finalTitle =
          "REPORTE MENSUAL - ${_monthFormatter.format(now).toUpperCase()}";
    } else if (isWeekly) {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      finalTitle =
          "REPORTE SEMANAL (${_dateFormatter.format(start)} AL ${_dateFormatter.format(end)})";
    }

    final total = tasks.length;
    final completedTasks = tasks
        .where((t) => t.status == 'completada')
        .toList();
    final completed = completedTasks.length;
    final inReview = tasks.where((t) => t.status == 'revision').length;
    final efficiency = total > 0
        ? (completed / total * 100).toStringAsFixed(1)
        : "0";

    // 2. LÓGICA EMPLEADO DESTACADO (SOLO SE CALCULA SI ES MENSUAL)
    String topEmployee = "N/A";
    int maxTasks = 0;
    if (isMonthly && completedTasks.isNotEmpty) {
      Map<String, int> counts = {};
      for (var t in completedTasks) {
        counts[t.assignedToName] = (counts[t.assignedToName] ?? 0) + 1;
      }
      var sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topEmployee = sortedEntries.first.key;
      maxTasks = sortedEntries.first.value;
    }

    pdf.addPage(
      pw.MultiPage(
        // Aplicamos el tema de fuente global para evitar errores de Helvetica
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(finalTitle),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard("Total", "$total", PdfColors.blueGrey),
              _buildStatCard("Eficiencia", "$efficiency%", PdfColors.blue700),
              _buildStatCard("En Revisión", "$inReview", PdfColors.orange700),
              _buildStatCard("Completadas", "$completed", PdfColors.green700),
            ],
          ),
          pw.SizedBox(height: 20),

          // REGLA: El empleado destacado es solo del mes
          if (isMonthly && maxTasks > 0) ...[
            _buildTopEmployeeCard(topEmployee, maxTasks),
            pw.SizedBox(height: 20),
          ],

          pw.Text(
            "RESUMEN DE GESTIÓN",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          _buildTaskTable(tasks),
          pw.SizedBox(height: 20),
          ...tasks.map((t) => _buildTaskDetailBlock(t)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateIndividualReport(TaskModel task) async {
    // REGLA: Solo para tareas terminadas
    if (task.status != 'completada') return;

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader("REPORTE INDIVIDUAL (FINALIZADA)"),
            _buildTaskDetailBlock(task),
            if (task.completionComment != null) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                "COMENTARIO DE ENTREGA:",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Text(
                  task.completionComment!,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
            pw.Spacer(),
            _buildSignatureBlock(),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 105,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border(top: pw.BorderSide(color: color, width: 3)),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey200,
            blurRadius: 2,
            offset: PdfPoint(0, 2),
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTopEmployeeCard(String name, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Text("🏆", style: pw.TextStyle(fontSize: 20)),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "RESPONSABLE DESTACADO DEL MES",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber900,
                  fontSize: 8,
                ),
              ),
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Finalizó exitosamente $count tareas.",
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTaskTable(List<TaskModel> tasks) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellStyle: pw.TextStyle(fontSize: 8),
      data: <List<String>>[
        ['TAREA', 'RESPONSABLE', 'VENCE', 'ESTADO'],
        ...tasks.map(
          (t) => [
            t.title,
            t.assignedToName,
            _dateFormatter.format(t.dueDate),
            t.status.toUpperCase(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTaskDetailBlock(TaskModel t) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(left: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blueGrey100, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            t.title.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
              fontSize: 10,
            ),
          ),
          pw.Text(
            "Asignado: ${t.assignedToName}",
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            "Descripción: ${t.description}",
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBlock() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSigLine("Firma Responsable"),
        _buildSigLine("Firma Jefe de Área"),
      ],
    );
  }

  static pw.Widget _buildSigLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.Text(
              _dateFormatter.format(DateTime.now()),
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.blueGrey),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "Página ${context.pageNumber} de ${context.pagesCount}",
        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey),
      ),
    );
  }
}
