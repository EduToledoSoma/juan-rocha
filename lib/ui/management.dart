import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/repository.dart';
import '../core/export_service.dart';
import '../core/utils.dart';
import 'forms.dart';
import 'style.dart';

class ManagementTab extends StatelessWidget {
  const ManagementTab({super.key});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(18,18,18,28),children:[
    const Text('Gestão do CT',style:TextStyle(fontWeight:FontWeight.w900,fontSize:27)),
    const SizedBox(height:4),const Text('Organize os módulos administrativos',style:TextStyle(color:brandMuted)),
    const SizedBox(height:20),
    _menu(context,Icons.workspace_premium_outlined,'Planos','Valores, modalidades e duração',const PlansPage()),
    _menu(context,Icons.view_kanban_outlined,'CRM / interessados','Aulas experimentais e matrículas',const LeadsPage()),
    _menu(context,Icons.inventory_2_outlined,'Uniformes e luvas','Produtos, estoque e vendas',const ProductsPage()),
    _menu(context,Icons.notifications_active_outlined,'Alertas internos','Vencimentos, aniversários, baixa frequência',const AlertsPage()),
    _menu(context,Icons.analytics_outlined,'Relatórios e exportação','PDF, registros e backup JSON',const ReportsPage()),
    _menu(context,Icons.history_edu_outlined,'Auditoria','Histórico das operações locais',const AuditPage()),
    const SizedBox(height:20),
    JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.info_outline,color:brandGold),const SizedBox(height:8),
      const Text('Versão local para este dispositivo',style:TextStyle(fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const Text('Os registros permanecem neste aparelho. Acesso por vários funcionários, autenticação, sincronização segura e restauração do backup ainda exigem um backend e testes antes de usar com dados reais de alunos.',style:TextStyle(fontSize:12,color:brandMuted)),
    ])),
  ]);
}
Widget _menu(BuildContext context,IconData icon,String title,String subtitle,Widget page)=>Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(padding:const EdgeInsets.all(9),child:ListTile(
  leading:CircleAvatar(backgroundColor:const Color(0xFF302919),child:Icon(icon,color:brandGold)),
  title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),
  trailing:const Icon(Icons.chevron_right,color:brandGold),
  onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>page)),
)));

class PlansPage extends StatefulWidget {const PlansPage({super.key});@override State<PlansPage> createState()=>_PlansPageState();}
class _PlansPageState extends State<PlansPage>{
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}void reload() { future=Repository.instance.list('plans',orderBy:'active DESC,name'); }
  Future<void> edit([Map<String,Object?>? item])async{
    final result=await editEntity(context,title:item==null?'Novo plano':'Editar plano',original:item,fields:const [
      FieldSpec('name','Nome do plano',mandatory:true),FieldSpec('modality','Modalidade',initial:'Boxe'),
      FieldSpec('fee_cents','Mensalidade (R\$)',kind:FieldKind.money,mandatory:true),
      FieldSpec('duration_months','Duração em meses',kind:FieldKind.number,initial:'1',mandatory:true),
      FieldSpec('weekly_sessions','Aulas por semana',kind:FieldKind.number,initial:'3',mandatory:true),
      FieldSpec('active','Status',kind:FieldKind.select,initial:'1',options:{'1':'Ativo','0':'Inativo'}),
      FieldSpec('description','Descrição',kind:FieldKind.multi),
    ]);
    if(result==null)return;
    try{
      await Repository.instance.save('plans',{...result,'active':int.tryParse(textValue(result['active']))??1},id:item==null?null:intValue(item['id']));
      if(!mounted)return;showJrOk(context);setState(reload);
    }catch(e){showJrError(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Planos')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('PLANO')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,100),children:[
        if(s.data!.isEmpty)const JrEmpty(text:'Cadastre os planos oferecidos pelo CT'),
        ...s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(child:ListTile(
          contentPadding:EdgeInsets.zero,title:Text(textValue(r['name']),style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text('${r['modality']} • ${r['duration_months']} mês(es) • ${r['weekly_sessions']} aulas/semana • ${r['active']==1?'Ativo':'Inativo'}'),
          trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(money(intValue(r['fee_cents'])),style:const TextStyle(color:brandGoldLight,fontWeight:FontWeight.w900)),const Icon(Icons.edit_outlined,size:17)]),
          onTap:()=>edit(r),
        )))),
      ]);
    }));
}

const _leadStages=<String,String>{
  'Novo contato':'Novo contato','Em atendimento':'Em atendimento',
  'Aula experimental agendada':'Experimental agendada',
  'Aula experimental realizada':'Experimental realizada',
  'Proposta apresentada':'Proposta apresentada',
  'Matrícula confirmada':'Matrícula confirmada',
  'Desistência':'Desistência',
};
class LeadsPage extends StatefulWidget {const LeadsPage({super.key});@override State<LeadsPage> createState()=>_LeadsPageState();}
class _LeadsPageState extends State<LeadsPage>{
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}void reload() { future=Repository.instance.list('leads'); }
  Future<void> edit([Map<String,Object?>? item])async{
    final result=await editEntity(context,title:item==null?'Novo interessado':'Editar interessado',original:item,fields:const [
      FieldSpec('name','Nome',mandatory:true),FieldSpec('phone','Telefone',kind:FieldKind.phone),
      FieldSpec('email','E-mail'),FieldSpec('modality','Modalidade',initial:'Boxe'),FieldSpec('origin','Origem (indicação, Instagram etc.)'),
      FieldSpec('stage','Etapa',kind:FieldKind.select,initial:'Novo contato',options:_leadStages),
      FieldSpec('followup_date','Próximo contato',kind:FieldKind.date),
      FieldSpec('notes','Observações',kind:FieldKind.multi),
    ]);
    if(result==null)return;
    try{await Repository.instance.save('leads',result,id:item==null?null:intValue(item['id']));if(!mounted)return;showJrOk(context);setState(reload);}catch(e){showJrError(context,e);}
  }
  Future<void> convert(Map<String,Object?> lead)async{
    if(lead['stage']=='Matrícula confirmada'){showJrError(context,'Este interessado já está marcado como matriculado.');return;}
    if(!await askConfirm(context,'Criar um novo aluno com o nome e telefone de ${lead['name']}? Confira duplicidades antes de continuar.'))return;
    try{
      await Repository.instance.save('students',{'name':lead['name'],'phone':lead['phone'],'email':lead['email'],'joined_at':todayIso(),'status':'active'});
      await Repository.instance.save('leads',{'stage':'Matrícula confirmada'},id:intValue(lead['id']));
      if(!mounted)return;showJrOk(context,'Interessado convertido em aluno');setState(reload);
    }catch(e){showJrError(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('CRM • interessados')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('CONTATO')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
        if(s.data!.isEmpty)const JrEmpty(text:'Nenhum interessado cadastrado'),
        ...s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(textValue(r['name']),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text('${r['phone']}  •  ${r['modality']}',style:const TextStyle(color:brandMuted)),
          const SizedBox(height:7),Text(textValue(r['stage']),style:const TextStyle(color:brandGold)),
          if(r['followup_date']!=null)Text('Próximo contato: ${displayDate(textValue(r['followup_date']))}',style:const TextStyle(color:brandMuted,fontSize:12)),
          const SizedBox(height:8),Wrap(spacing:8,children:[
            TextButton.icon(onPressed:()=>edit(r),icon:const Icon(Icons.edit),label:const Text('Editar')),
            if(r['stage']!='Matrícula confirmada')TextButton.icon(onPressed:()=>convert(r),icon:const Icon(Icons.person_add),label:const Text('Matricular')),
          ]),
        ])))),
      ]);
    }));
}

class ProductsPage extends StatefulWidget {const ProductsPage({super.key});@override State<ProductsPage> createState()=>_ProductsPageState();}
class _ProductsPageState extends State<ProductsPage>{
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}void reload() { future=Repository.instance.list('products'); }
  Future<void> edit([Map<String,Object?>? item])async{
    final result=await editEntity(context,title:item==null?'Novo produto':'Editar produto',original:item,fields:const [
      FieldSpec('name','Produto',mandatory:true),FieldSpec('category','Categoria',kind:FieldKind.select,initial:'Uniformes',options:{'Uniformes':'Uniformes','Luvas':'Luvas','Acessórios':'Acessórios','Outros':'Outros'}),
      FieldSpec('price_cents','Preço (R\$)',kind:FieldKind.money,mandatory:true),
      FieldSpec('stock','Estoque',kind:FieldKind.number,initial:'0'),
      FieldSpec('active','Status',kind:FieldKind.select,initial:'1',options:{'1':'Ativo','0':'Inativo'}),
    ]);
    if(result==null)return;
    try{await Repository.instance.save('products',{...result,'active':int.tryParse(textValue(result['active']))??1},id:item==null?null:intValue(item['id']));if(!mounted)return;showJrOk(context);setState(reload);}catch(e){showJrError(context,e);}
  }
  Future<void> sell(Map<String,Object?> item)async{
    final values=await editEntity(context,title:'Venda • ${item['name']}',fields:const [FieldSpec('quantity','Quantidade vendida',kind:FieldKind.number,initial:'1',mandatory:true)]);
    if(values==null)return;
    try{await Repository.instance.sellProduct(intValue(item['id']),intValue(values['quantity']));if(!mounted)return;showJrOk(context,'Venda registrada, estoque atualizado e receita lançada');setState(reload);}catch(e){showJrError(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Produtos e estoque')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('PRODUTO')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
        if(s.data!.isEmpty)const JrEmpty(text:'Nenhum produto cadastrado'),
        ...s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:11),child:JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(textValue(r['name']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
          const SizedBox(height:5),Text('${r['category']}  •  Estoque ${r['stock']}  •  ${money(intValue(r['price_cents']))}',style:const TextStyle(color:brandGoldLight)),
          const SizedBox(height:7),Wrap(spacing:9,children:[TextButton.icon(onPressed:()=>edit(r),icon:const Icon(Icons.edit_outlined),label:const Text('Editar')),
            if(r['active']==1)TextButton.icon(onPressed:()=>sell(r),icon:const Icon(Icons.shopping_bag_outlined),label:const Text('Vender'))]),
        ])))),
      ]);
    }));
}

class AlertsPage extends StatefulWidget {const AlertsPage({super.key});@override State<AlertsPage> createState()=>_AlertsPageState();}
class _AlertsPageState extends State<AlertsPage>{
  late Future<_AlertsData> future;
  @override void initState(){super.initState();reload();}void reload() { future=_AlertsData.load(); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Alertas internos')),
    body:FutureBuilder<_AlertsData>(future:future,builder:(context,s){
      if(s.hasError)return JrEmpty(text:'Erro: ${s.error}');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final data=s.data!;
      return ListView(padding:const EdgeInsets.all(18),children:[
        const Text('Os alertas são calculados com base nos registros existentes. Não há envios por WhatsApp ou SMS.',style:TextStyle(color:brandMuted)),
        const SizedBox(height:18),
        if(data.alerts.isEmpty)const JrEmpty(text:'Sem alertas neste momento',icon:Icons.verified_outlined),
        ...data.alerts.map((a)=>Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(child:Row(children:[
          Icon(a.urgent?Icons.warning_amber:Icons.notifications_none,color:a.urgent?brandRed:brandGold,size:28),
          const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(a.title,style:const TextStyle(fontWeight:FontWeight.w800)),
            const SizedBox(height:4),Text(a.subtitle,style:const TextStyle(color:brandMuted,fontSize:12)),
          ])),
        ])))),
      ]);
    }),
  );
}
class _Alert {
  const _Alert(this.title,this.subtitle,{this.urgent=false});
  final String title,subtitle; final bool urgent;
}
class _AlertsData {
  const _AlertsData(this.alerts);
  final List<_Alert> alerts;
  static Future<_AlertsData> load()async{
    final alerts=<_Alert>[];
    final repo=Repository.instance;
    final invoices=await repo.invoiceList();
    final cutoff=DateTime.now().add(const Duration(days:5)).toIso8601String().substring(0,10);
    for(final i in invoices){
      final status=invoiceStatus(i);
      if(status=='Vencida')alerts.add(_Alert('Mensalidade vencida • ${i['student_name']}',
        '${money(intValue(i['amount_cents'])-intValue(i['discount_cents'])-intValue(i['paid_cents']))} em aberto • ${displayDate(textValue(i['due_date']))}',urgent:true));
      if(status=='Pendente' && textValue(i['due_date']).compareTo(cutoff)<=0)
        alerts.add(_Alert('Vencimento próximo • ${i['student_name']}','Vence em ${displayDate(textValue(i['due_date']))}'));
    }
    final birthdays=await repo.birthdayList();
    for(final s in birthdays){
      alerts.add(_Alert('Aniversariante do mês • ${s['name']}','${displayDate(textValue(s['birth_date']))} • Telefone ${s['phone']}'));
    }
    final frequency=await repo.lowFrequencyStudents();
    for(final r in frequency){
      final count=intValue(r['total']),present=intValue(r['present']);
      alerts.add(_Alert('Baixa frequência • ${r['name']}','$present presenças em $count registros recentes',urgent:true));
    }
    return _AlertsData(alerts);
  }
}

class ReportsPage extends StatefulWidget {const ReportsPage({super.key});@override State<ReportsPage> createState()=>_ReportsPageState();}
class _ReportsPageState extends State<ReportsPage>{
  bool busy=false;
  Future<void> exportJson()async{
    setState(()=>busy=true);
    try{
      final data=await Repository.instance.exportAll();
      final export={'app':'Juan Rocha Boxe','format_version':1,'exported_at':DateTime.now().toIso8601String(),'tables':data};
      final saved=await deliverExport(filename:'backup_juan_rocha_${todayIso()}.json', bytes:utf8.encode(const JsonEncoder.withIndent('  ').convert(export)),message:'Backup JR Boxe Gestão — guarde em local protegido.');
      if(saved!=null && mounted)showJrOk(context,'Backup salvo em: $saved');
    }catch(e){showJrError(context,e);}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> exportCsv()async{
    setState(()=>busy=true);
    try{
      final rows=await Repository.instance.studentList();
      final out=<List<String>>[
        ['ID','Nome','Telefone','CPF','Email','Status','Plano','Turma','Matricula'],
        ...rows.map((r)=>[textValue(r['id']),textValue(r['name']),textValue(r['phone']),textValue(r['cpf']),textValue(r['email']),textValue(r['status']),textValue(r['plan_name']),textValue(r['class_name']),textValue(r['joined_at'])]),
      ];
      String csv(String x) {
        final escaped = x.replaceAll('"', '""');
        return '"$escaped"';
      }
      final csvData='\uFEFF${out.map((row)=>row.map(csv).join(';')).join('\n')}';
      final saved=await deliverExport(filename:'alunos_juan_rocha_${todayIso()}.csv',bytes:utf8.encode(csvData));
      if(saved!=null && mounted)showJrOk(context,'CSV salvo em: $saved');
    }catch(e){showJrError(context,e);}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> exportPdf()async{
    setState(()=>busy=true);
    try{
      final data=await Repository.instance.dashboard();
      final frequency=await Repository.instance.monthlyFrequency();
      final pdf=pw.Document();
      pdf.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(context)=>[
        pw.Text('JUAN ROCHA BOXE',style:pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),
        pw.Text('Relatório gerencial - ${displayDate(todayIso())}'),pw.SizedBox(height:16),
        ...<String,String>{
          'Alunos ativos':'${data['students']}','Alunos inativos':'${data['inactive']}',
          'Mensalidades vencidas':'${data['overdue']}','Presenças hoje':'${data['presences']}',
          'Recebido hoje':money(intValue(data['day_income'])),
          'Recebido no mês':money(intValue(data['month_income'])),
          'Despesas no mês':money(intValue(data['month_expense'])),
          'Resultado do mês':money(intValue(data['month_income'])-intValue(data['month_expense'])),
        }.entries.map((e)=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:5),child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text(e.key),pw.Text(e.value)]))),
        pw.SizedBox(height:20),pw.Text('Frequência registrada por mês',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),
        ...frequency.map((r)=>pw.Text('${r['month']}: ${r['present']} presentes / ${r['total']} registros')),
        pw.SizedBox(height:20),pw.Text('Gerado a partir do banco de dados local deste dispositivo.',style:const pw.TextStyle(fontSize:9)),
      ]));
      final saved=await deliverExport(filename:'relatorio_juan_rocha_${todayIso()}.pdf',bytes:await pdf.save());
      if(saved!=null && mounted)showJrOk(context,'PDF salvo em: $saved');
    }catch(e){showJrError(context,e);}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Relatórios e exportação')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('Relatórios reais',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        ElevatedButton.icon(onPressed:busy?null:exportPdf,icon:const Icon(Icons.picture_as_pdf),label:const Text('RELATÓRIO GERENCIAL PDF')),
        const SizedBox(height:11),OutlinedButton.icon(onPressed:busy?null:exportCsv,icon:const Icon(Icons.table_chart_outlined),label:const Text('EXPORTAR ALUNOS CSV')),
        const SizedBox(height:11),OutlinedButton.icon(onPressed:busy?null:exportJson,icon:const Icon(Icons.save_alt_outlined),label:const Text('EXPORTAR BACKUP JSON')),
        const SizedBox(height:10),const Text('A exportação contém dados pessoais sem criptografia. Guarde os arquivos somente em armazenamento seguro. A restauração automática ainda não está implementada.',style:TextStyle(color:brandMuted,fontSize:12)),
      ])),
      if(busy)const Padding(padding:EdgeInsets.all(20),child:Center(child:CircularProgressIndicator())),
      const SizedBox(height:20),const Text('Persistência local',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
      const SizedBox(height:9),const Text('O banco SQLite guarda alunos, pagamentos, turmas, frequência, produtos e contatos neste dispositivo. A remoção do app pode apagar os dados: faça exportações frequentes.',style:TextStyle(color:brandMuted)),
    ]));
}
class AuditPage extends StatelessWidget {
  const AuditPage({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Auditoria local')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:Repository.instance.audit(),builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.all(18),children:[
        if(s.data!.isEmpty)const JrEmpty(text:'Sem alterações registradas'),
        ...s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:JrPanel(padding:const EdgeInsets.all(10),child:ListTile(
          title:Text('${r['entity']} • ${r['action']}'),subtitle:Text('${r['details']}\n${r['happened_at']}'),
        )))),
      ]);
    }));
}
