import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/repository.dart';
import '../core/utils.dart';
import 'forms.dart';
import 'style.dart';

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});
  @override State<FinanceTab> createState()=>_FinanceTabState();
}
class _FinanceTabState extends State<FinanceTab> {
  late Future<_FinanceModel> future;
  @override void initState(){super.initState();reload();}
  void reload()=>future=_FinanceModel.load();

  Future<void> addMovement() async {
    final values=await editEntity(context,title:'Nova movimentação',fields:[
      const FieldSpec('direction','Tipo',kind:FieldKind.select,initial:'expense',options:{'expense':'Despesa','income':'Outra receita'}),
      const FieldSpec('category','Categoria',mandatory:true,initial:'Outros'),
      const FieldSpec('description','Descrição',mandatory:true),
      const FieldSpec('amount_cents','Valor (R\$)',kind:FieldKind.money,mandatory:true),
      FieldSpec('occurred_at','Data',kind:FieldKind.date,mandatory:true,initial:todayIso()),
    ]);
    if(values==null)return;
    try{
      await Repository.instance.addFinance(direction:textValue(values['direction']),category:textValue(values['category']),description:textValue(values['description']),amountCents:intValue(values['amount_cents']),occurredAt:textValue(values['occurred_at']));
      if(!mounted)return;showJrOk(context);setState(reload);
    }catch(e){showJrError(context,e);}
  }

  @override Widget build(BuildContext context)=>FutureBuilder<_FinanceModel>(future:future,builder:(context,s){
    if(s.hasError)return JrEmpty(text:'Erro financeiro: ${s.error}');
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final m=s.data!; final month=monthKey();
    final current=m.finance.where((r)=>textValue(r['occurred_at']).startsWith(month)).toList();
    final received=current.where((r)=>r['direction']=='income').fold<int>(0,(a,r)=>a+intValue(r['amount_cents']));
    final spent=current.where((r)=>r['direction']=='expense').fold<int>(0,(a,r)=>a+intValue(r['amount_cents']));
    final pending=m.invoices.where((r)=>['Pendente','Parcial','Vencida'].contains(invoiceStatus(r))).toList();
    return RefreshIndicator(onRefresh:()async{setState(reload);await future;},child:ListView(padding:const EdgeInsets.fromLTRB(18,17,18,35),children:[
      const Text('Financeiro',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),
      const SizedBox(height:5),Text('Caixa do mês • ${friendlyMonth(month)}',style:const TextStyle(color:brandMuted)),
      const SizedBox(height:18),Row(children:[
        Expanded(child:JrStat(label:'Recebido',value:money(received),icon:Icons.arrow_downward_rounded)),
        const SizedBox(width:10),Expanded(child:JrStat(label:'Despesas',value:money(spent),icon:Icons.arrow_upward_rounded)),
      ]),const SizedBox(height:11),
      JrPanel(child:Row(children:[const Expanded(child:Text('Saldo do mês',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800))),Text(money(received-spent),style:const TextStyle(fontSize:20,color:brandGoldLight,fontWeight:FontWeight.w900))])),
      const SizedBox(height:16),ElevatedButton.icon(onPressed:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const InvoicesPage()));if(mounted)setState(reload);},icon:const Icon(Icons.receipt_long),label:Text('MENSALIDADES  •  ${pending.length} EM ABERTO')),
      const SizedBox(height:10),OutlinedButton.icon(onPressed:addMovement,icon:const Icon(Icons.add),label:const Text('LANÇAR RECEITA OU DESPESA')),
      const SizedBox(height:24),const Text('Movimentações recentes',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),
      if(m.finance.isEmpty)const JrEmpty(text:'Nenhuma movimentação. Registre a primeira despesa ou pagamento.',icon:Icons.account_balance_wallet_outlined),
      ...m.finance.take(50).map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:JrPanel(padding:const EdgeInsets.all(10),child:ListTile(
        leading:CircleAvatar(backgroundColor:const Color(0xFF2F2B22),child:Icon(r['direction']=='income'?Icons.south_west:Icons.north_east,color:r['direction']=='income'?brandGold:brandRed)),
        title:Text(textValue(r['description'])),
        subtitle:Text('${r['category']} • ${displayDate(textValue(r['occurred_at']))}'),
        trailing:Text('${r['direction']=='expense'?'-':'+'}${money(intValue(r['amount_cents']))}',style:TextStyle(fontWeight:FontWeight.w800,color:r['direction']=='income'?brandGold:brandRed)),
      )))),
    ]));
  });
}
class _FinanceModel {
  const _FinanceModel(this.finance,this.invoices);
  final List<Map<String,Object?>> finance,invoices;
  static Future<_FinanceModel> load()async=>_FinanceModel(await Repository.instance.financeList(),await Repository.instance.invoiceList());
}

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override State<InvoicesPage> createState()=>_InvoicesPageState();
}
class _InvoicesPageState extends State<InvoicesPage> {
  String filter='open';
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}
  void reload()=>future=Repository.instance.invoiceList();

  Future<void> newInvoice() async {
    try{
      final all=await Repository.instance.studentList();
      final students=all.where((r)=>r['status']=='active').toList();
      if(students.isEmpty){if(mounted)showJrError(context,'Cadastre um aluno ativo primeiro.');return;}
      if(!mounted)return;
      final values=await editEntity(context,title:'Nova mensalidade',fields:[
        FieldSpec('student_id','Aluno',kind:FieldKind.foreign,values:{for(final s in students)intValue(s['id']):textValue(s['name'])}),
        FieldSpec('competency','Competência (AAAA-MM)',initial:monthKey(),mandatory:true),
        FieldSpec('due_date','Vencimento',kind:FieldKind.date,initial:'${monthKey()}-10',mandatory:true),
        const FieldSpec('amount_cents','Valor da mensalidade (R\$)',kind:FieldKind.money,mandatory:true),
        const FieldSpec('discount_cents','Desconto (R\$)',kind:FieldKind.money,initial:'0'),
      ]);
      if(values==null)return;
      final id=values['student_id'];
      if(id==null)throw StateError('Selecione o aluno.');
      final competency=textValue(values['competency']);
      if(!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(competency))throw StateError('Use AAAA-MM na competência');
      final student=students.firstWhere((s)=>s['id']==id);
      await Repository.instance.createInvoice(studentId:intValue(id),competency:competency,dueDate:textValue(values['due_date']),amountCents:intValue(values['amount_cents']),discountCents:intValue(values['discount_cents']),planId:student['plan_id'] as int?);
      if(!mounted)return;showJrOk(context);setState(reload);
    }catch(e){showJrError(context,e);}
  }

  Future<void> pay(Map<String,Object?> invoice)async {
    final remaining=intValue(invoice['amount_cents'])-intValue(invoice['discount_cents'])-intValue(invoice['paid_cents']);
    if(remaining<=0)return;
    final values=await editEntity(context,title:'Registrar pagamento',fields:[
      FieldSpec('amount_cents','Valor recebido (R\$)',kind:FieldKind.money,mandatory:true,initial:editMoney(remaining)),
      const FieldSpec('method','Forma de pagamento',kind:FieldKind.select,initial:'PIX',options:{'PIX':'PIX','Dinheiro':'Dinheiro','Cartão':'Cartão','Transferência':'Transferência','Outro':'Outro'}),
      const FieldSpec('notes','Observação',kind:FieldKind.multi),
    ]);
    if(values==null)return;
    try{
      await Repository.instance.payInvoice(invoiceId:intValue(invoice['id']),amountCents:intValue(values['amount_cents']),method:textValue(values['method']),notes:textValue(values['notes']));
      if(!mounted)return;showJrOk(context,'Pagamento registrado no caixa');setState(reload);
      final print=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Pagamento registrado'),content:const Text('Deseja compartilhar o recibo em PDF?'),actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Agora não')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Gerar PDF')),
      ]));
      if(print==true)await receipt(invoice);
    }catch(e){showJrError(context,e);}
  }

  Future<void> receipt(Map<String,Object?> invoice) async {
    try{
      final payments=await Repository.instance.paymentHistory(intValue(invoice['id']));
      final pdf=pw.Document();
      pdf.addPage(pw.Page(pageFormat:PdfPageFormat.a5,build:(context)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Text('JUAN ROCHA BOXE',style:pw.TextStyle(fontSize:19,fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:10),pw.Text('Comprovante de pagamento'),pw.Divider(),
        pw.Text('Aluno: ${invoice['student_name']}'),
        pw.Text('Mensalidade: ${invoice['competency']}'),
        pw.Text('Vencimento: ${displayDate(textValue(invoice['due_date']))}'),
        pw.Text('Valor: ${money(intValue(invoice['amount_cents'])-intValue(invoice['discount_cents']))}'),
        pw.SizedBox(height:12),
        ...payments.map((p)=>pw.Text('${displayDate(textValue(p['paid_at']))}  -  ${money(intValue(p['amount_cents']))}  (${p['method']})')),
        pw.Divider(),pw.Text('Total recebido: ${money(payments.fold<int>(0,(a,p)=>a+intValue(p['amount_cents'])))}',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:22),pw.Text('Registro de pagamento gerado pelo JR Boxe Gestão.',style:const pw.TextStyle(fontSize:9)),
      ])));
      await Printing.sharePdf(bytes:await pdf.save(),filename:'recibo_juan_rocha_${invoice['id']}.pdf');
    }catch(e){showJrError(context,e);}
  }
  Future<void> cancel(Map<String,Object?> invoice)async{
    if(!await askConfirm(context,'Cancelar esta mensalidade sem pagamentos?'))return;
    try{await Repository.instance.changeInvoiceStatus(intValue(invoice['id']),'cancelled');if(!mounted)return;showJrOk(context,'Mensalidade cancelada');setState(reload);}catch(e){showJrError(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Mensalidades')),floatingActionButton:FloatingActionButton.extended(onPressed:newInvoice,icon:const Icon(Icons.add),label:const Text('MENSALIDADE')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(s.hasError)return JrEmpty(text:'Erro: ${s.error}');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final filtered=s.data!.where((r){final status=invoiceStatus(r);return filter=='all'||(filter=='open'&&['Pendente','Parcial','Vencida'].contains(status))||(filter=='paid'&&status=='Paga');}).toList();
      return ListView(padding:const EdgeInsets.fromLTRB(17,15,17,100),children:[
        Row(children:[for(final f in {'open':'Em aberto','paid':'Pagas','all':'Todas'}.entries)Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(f.value),selected:filter==f.key,onSelected:(_)=>setState(()=>filter=f.key)))]),
        const SizedBox(height:16),
        if(filtered.isEmpty)const JrEmpty(text:'Nenhuma mensalidade neste filtro'),
        ...filtered.map((r)=>Padding(padding:const EdgeInsets.only(bottom:11),child:JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(textValue(r['student_name']),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text('${friendlyMonth(textValue(r['competency']))} • Vence ${displayDate(textValue(r['due_date']))}',style:const TextStyle(color:brandMuted)),
          const SizedBox(height:9),Row(children:[
            Expanded(child:Text(money(intValue(r['amount_cents'])-intValue(r['discount_cents'])),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:brandGoldLight))),
            Text(invoiceStatus(r),style:TextStyle(color:invoiceStatus(r)=='Vencida'?brandRed:brandGold,fontWeight:FontWeight.bold)),
          ]),
          Text('Já recebido: ${money(intValue(r['paid_cents']))}',style:const TextStyle(color:brandMuted,fontSize:12)),
          const SizedBox(height:10),Wrap(spacing:9,runSpacing:3,children:[
            if(['Pendente','Parcial','Vencida'].contains(invoiceStatus(r)))TextButton.icon(onPressed:()=>pay(r),icon:const Icon(Icons.payment),label:const Text('Registrar pagamento')),
            if(intValue(r['paid_cents'])>0)TextButton.icon(onPressed:()=>receipt(r),icon:const Icon(Icons.picture_as_pdf),label:const Text('Recibo')),
            if(intValue(r['paid_cents'])==0&&r['status']=='pending')TextButton.icon(onPressed:()=>cancel(r),icon:const Icon(Icons.cancel_outlined),label:const Text('Cancelar')),
          ]),
        ])))),
      ]);
    }),
  );
}
