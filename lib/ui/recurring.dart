import 'package:flutter/material.dart';
import '../core/repository.dart';
import '../core/utils.dart';
import 'forms.dart';
import 'style.dart';

/// Monthly recurring invoices and expenses. No automatic payment collection.
class RecurringPage extends StatefulWidget {
  const RecurringPage({super.key});
  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> {
  late Future<List<Map<String,Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() { _future = Repository.instance.recurringRules(); }

  Future<void> _addRule() async {
    try {
      final students = (await Repository.instance.studentList())
          .where((s) => s['status'] == 'active').toList();
      if (!mounted) return;
      final result = await editEntity(context,
        title: 'Nova recorrência mensal',
        fields: [
          const FieldSpec('kind','Tipo de recorrência',kind:FieldKind.select,
              initial:'invoice',options:{'invoice':'Mensalidade de aluno','expense':'Despesa fixa'}),
          FieldSpec('student_id','Aluno (apenas para mensalidade)',kind:FieldKind.foreign,
              values:{for(final s in students) intValue(s['id']):textValue(s['name'])}),
          const FieldSpec('description','Descrição',mandatory:true),
          const FieldSpec('category','Categoria de despesa',initial:'Despesas fixas'),
          const FieldSpec('amount_cents','Valor mensal (R\$)',kind:FieldKind.money,mandatory:true),
          const FieldSpec('due_day','Dia do mês (1 a 31)',kind:FieldKind.number,initial:'10',mandatory:true),
          FieldSpec('start_month','Mês inicial (AAAA-MM)',initial:monthKey(),mandatory:true),
          const FieldSpec('end_month','Mês final opcional (AAAA-MM)'),
        ],
      );
      if (result == null) return;
      await Repository.instance.addRecurringRule(
        kind:textValue(result['kind']),
        studentId:result['student_id'] is int ? result['student_id'] as int : null,
        description:textValue(result['description']),
        category:textValue(result['category']),
        amountCents:intValue(result['amount_cents']),
        dueDay:intValue(result['due_day']),
        startMonth:textValue(result['start_month']),
        endMonth:textValue(result['end_month']),
      );
      if (!mounted) return;
      setState(_refresh);
      showJrOk(context, 'Recorrência cadastrada. Lançamentos gerados sem duplicar.');
    } catch (e) {
      if(mounted) showJrError(context,e);
    }
  }

  Future<void> _toggle(Map<String,Object?> rule) async {
    try {
      final active = intValue(rule['active']) == 1;
      await Repository.instance.toggleRecurringRule(intValue(rule['id']),!active);
      if (!mounted) return;
      setState(_refresh);
      showJrOk(context,active?'Recorrência pausada':'Recorrência reativada');
    } catch (e) {
      if(mounted) showJrError(context,e);
    }
  }

  Future<void> _generate() async {
    try {
      final count = await Repository.instance.generateRecurringEntries();
      if (!mounted) return;
      setState(_refresh);
      showJrOk(context, '$count lançamento(s) novo(s). Nenhum registro duplicado.');
    } catch (e) {
      if(mounted) showJrError(context,e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Recorrências mensais')),
    floatingActionButton:FloatingActionButton.extended(
      onPressed:_addRule,icon:const Icon(Icons.add),label:const Text('NOVA RECORRÊNCIA')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:_future,builder:(context,s) {
      if (s.hasError) return JrEmpty(text:'Erro: ${s.error}');
      if (!s.hasData) return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.fromLTRB(18,16,18,110),children:[
        const JrPanel(child:Text('Mensalidades recorrentes são geradas como pendentes, nunca como pagas. Despesas fixas entram no caixa somente na data prevista. Para interromper novos lançamentos, pause a recorrência. Lançamentos anteriores não são apagados.')),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:_generate,icon:const Icon(Icons.sync),
            label:const Text('VERIFICAR E GERAR PENDÊNCIAS')),
        const SizedBox(height:15),
        if(s.data!.isEmpty) const JrEmpty(text:'Nenhuma recorrência cadastrada.'),
        ...s.data!.map((r) {
          final active=intValue(r['active'])==1;
          final kind=textValue(r['kind']);
          final day=intValue(r['due_day']);
          final end=textValue(r['end_month']);
          return Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(textValue(r['description']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:brandGoldLight)),
              const SizedBox(height:4),
              Text(kind=='invoice'?'Mensalidade recorrente • aluno #${r['student_id']}':'Despesa fixa • ${r['category']}'),
              const SizedBox(height:5),
              Text('${money(intValue(r['amount_cents']))} • dia $day • desde ${r['start_month']}${end.isEmpty?'':' até $end'}',
                  style:const TextStyle(color:brandMuted)),
              const SizedBox(height:8),
              Row(children:[
                Expanded(child:Text(active?'Ativa':'Pausada',style:TextStyle(color:active?brandGoldLight:brandMuted))),
                TextButton.icon(onPressed:()=>_toggle(r),icon:Icon(active?Icons.pause_circle_outline:Icons.play_circle_outline),
                    label:Text(active?'Pausar':'Reativar')),
              ]),
            ]),
          ));
        }),
      ]);
    }),
  );
}
