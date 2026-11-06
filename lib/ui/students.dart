import 'package:flutter/material.dart';
import '../core/repository.dart';
import '../core/utils.dart';
import 'forms.dart';
import 'style.dart';

const _studentStatus={'active':'Ativo','inactive':'Inativo','suspended':'Suspenso','cancelled':'Cancelado'};

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});
  @override State<StudentsTab> createState()=>_StudentsTabState();
}
class _StudentsTabState extends State<StudentsTab> {
  String query=''; String filter='all';
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}
  void reload() { future=Repository.instance.studentList(); }

  Future<void> editor([Map<String,Object?>? student]) async {
    try {
      final plans=await Repository.instance.list('plans');
      final classes=await Repository.instance.list('classes');
      if(!mounted)return;
      final selected=await editEntity(context,title:student==null?'Novo aluno':'Editar aluno',original:student,fields:[
        const FieldSpec('name','Nome completo',mandatory:true),
        const FieldSpec('phone','Telefone / WhatsApp',kind:FieldKind.phone),
        const FieldSpec('birth_date','Nascimento',kind:FieldKind.date),
        const FieldSpec('cpf','CPF (opcional)'),
        const FieldSpec('email','E-mail'),const FieldSpec('address','Endereço'),
        const FieldSpec('emergency_phone','Contato de emergência',kind:FieldKind.phone),
        const FieldSpec('guardian_name','Responsável'),
        const FieldSpec('guardian_phone','Telefone do responsável',kind:FieldKind.phone),
        FieldSpec('joined_at','Matrícula',kind:FieldKind.date,mandatory:true,initial:todayIso()),
        const FieldSpec('status','Situação',kind:FieldKind.select,initial:'active',options:_studentStatus),
        FieldSpec('plan_id','Plano',kind:FieldKind.foreign,values:{for(final p in plans)intValue(p['id']):textValue(p['name'])}),
        FieldSpec('class_id','Turma',kind:FieldKind.foreign,values:{for(final c in classes)intValue(c['id']):textValue(c['title'])}),
        const FieldSpec('notes','Observações administrativas',kind:FieldKind.multi),
      ]);
      if(selected==null)return;
      await Repository.instance.save('students',selected,id:student==null?null:intValue(student['id']));
      if(!mounted)return;showJrOk(context);setState(reload);
    } catch(e){showJrError(context,e);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:Colors.transparent,
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>editor(),icon:const Icon(Icons.add),label:const Text('ALUNO')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(s.hasError)return JrEmpty(text:'Erro ao ler alunos: ${s.error}');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final filtered=s.data!.where((r){
        final text='${r['name']} ${r['phone']} ${r['cpf']}'.toLowerCase();
        return text.contains(query.toLowerCase()) && (filter=='all'||r['status']==filter);
      }).toList();
      return ListView(padding:const EdgeInsets.fromLTRB(18,16,18,110),children:[
        Text('Alunos  •  ${s.data!.length}',style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),
        const SizedBox(height:14),TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Buscar nome, CPF ou telefone')),
        const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          for(final item in {'all':'Todos',..._studentStatus}.entries)Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(item.value),selected:filter==item.key,onSelected:(_)=>setState(()=>filter=item.key))),
        ])),
        const SizedBox(height:15),
        if(filtered.isEmpty)const JrEmpty(text:'Nenhum aluno encontrado. Toque em + ALUNO para cadastrar.',icon:Icons.group_add_outlined),
        ...filtered.map((r)=>Padding(padding:const EdgeInsets.only(bottom:11),child:JrPanel(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:ListTile(
          leading:CircleAvatar(backgroundColor:const Color(0xFF554722),child:Text(textValue(r['name']).isEmpty?'?':textValue(r['name'])[0].toUpperCase(),style:const TextStyle(color:brandGoldLight,fontWeight:FontWeight.bold))),
          title:Text(textValue(r['name']),style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Text('${r['plan_name']??'Sem plano'}  •  ${_studentStatus[r['status']]??'—'}\n${r['phone']??''}'),
          isThreeLine:true,trailing:const Icon(Icons.chevron_right,color:brandGold),
          onTap:()async{await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>StudentDetails(studentId:intValue(r['id']),onEdit:()=>editor(r))));if(mounted)setState(reload);},
        )))),
      ]);
    }),
  );
}

class StudentDetails extends StatefulWidget {
  const StudentDetails({super.key,required this.studentId,required this.onEdit});
  final int studentId;
  final Future<void> Function() onEdit;
  @override State<StudentDetails> createState()=>_StudentDetailsState();
}
class _StudentDetailsState extends State<StudentDetails> {
  late Future<_StudentInfo> future;
  @override void initState(){super.initState();reload();}
  void reload() { future=_StudentInfo.load(widget.studentId); }

  Future<void> generateInvoice(Map<String,Object?> student) async {
    try {
      final fee=intValue(student['plan_fee']);
      if(fee<=0){showJrError(context,'Cadastre um plano com valor para este aluno.');return;}
      final result=await editEntity(context,title:'Gerar mensalidade',fields:[
        FieldSpec('competency','Competência (AAAA-MM)',initial:monthKey(),mandatory:true),
        FieldSpec('due_date','Vencimento',kind:FieldKind.date,initial:'${monthKey()}-10',mandatory:true),
        FieldSpec('amount_cents','Valor (R\$)',kind:FieldKind.money,initial:editMoney(fee),mandatory:true),
        const FieldSpec('discount_cents','Desconto (R\$)',kind:FieldKind.money,initial:'0'),
      ]);
      if(result==null)return;
      final competency=textValue(result['competency']);
      if(!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(competency)) throw StateError('Competência deve ser AAAA-MM.');
      await Repository.instance.createInvoice(studentId:widget.studentId,competency:competency,dueDate:textValue(result['due_date']),amountCents:intValue(result['amount_cents']),discountCents:intValue(result['discount_cents']),planId:student['plan_id'] as int?);
      if(!mounted)return;showJrOk(context,'Mensalidade gerada');setState(reload);
    }catch(e){showJrError(context,e);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Ficha do aluno')),
    body:FutureBuilder<_StudentInfo>(future:future,builder:(context,s){
      if(s.hasError)return JrEmpty(text:'Falha: ${s.error}');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final d=s.data!, student=d.student;
      return ListView(padding:const EdgeInsets.all(18),children:[
        JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(textValue(student['name']),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
          const SizedBox(height:5),Text('${_studentStatus[student['status']]} • ${student['plan_name']??'Sem plano'}',style:const TextStyle(color:brandGoldLight)),
          const SizedBox(height:15),
          _detail('Telefone',student['phone']),_detail('Nascimento',displayDate(textValue(student['birth_date']))),
          _detail('CPF',student['cpf']),_detail('E-mail',student['email']),_detail('Endereço',student['address']),
          _detail('Emergência',student['emergency_phone']),_detail('Responsável',student['guardian_name']),
          _detail('Turma',student['class_name']),_detail('Matrícula',displayDate(textValue(student['joined_at']))),
          if(textValue(student['notes']).isNotEmpty)_detail('Observações',student['notes']),
          const SizedBox(height:10),ElevatedButton.icon(onPressed:()async{await widget.onEdit();if(mounted)setState(reload);},icon:const Icon(Icons.edit),label:const Text('EDITAR CADASTRO')),
          const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>generateInvoice(student),icon:const Icon(Icons.add_card),label:const Text('GERAR MENSALIDADE')),
        ])),
        const SizedBox(height:19),const Text('Histórico de mensalidades',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        if(d.invoices.isEmpty)const JrEmpty(text:'Nenhuma mensalidade cadastrada')
        else ...d.invoices.map((i)=>Padding(padding:const EdgeInsets.only(bottom:8),child:JrPanel(padding:const EdgeInsets.all(12),child:ListTile(
          title:Text('${friendlyMonth(textValue(i['competency']))} • ${money(intValue(i['amount_cents'])-intValue(i['discount_cents']))}'),
          subtitle:Text('${invoiceStatus(i)}  •  Recebido ${money(intValue(i['paid_cents']))}'),
        )))),
        const SizedBox(height:17),const Text('Últimas presenças',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),
        if(d.attendance.isEmpty)const JrEmpty(text:'Sem presença registrada')
        else ...d.attendance.take(20).map((r)=>ListTile(
          leading:Icon(r['status']=='present'?Icons.check_circle:r['status']=='justified'?Icons.info_outline:Icons.cancel_outlined,color:r['status']=='present'?brandGold:brandRed),
          title:Text(displayDate(textValue(r['lesson_date']))),subtitle:Text('${r['status']=='present'?'Presente':r['status']=='justified'?'Justificada':'Falta'} • ${r['class_name']??'Sem turma'}'),
        )),
      ]);
    }),
  );
}
Widget _detail(String label,Object? value)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
  SizedBox(width:107,child:Text(label,style:const TextStyle(color:brandMuted,fontSize:12))),
  Expanded(child:Text(textValue(value).isEmpty?'—':textValue(value),style:const TextStyle(fontSize:13))),
]));
class _StudentInfo {
  const _StudentInfo(this.student,this.invoices,this.attendance);
  final Map<String,Object?> student;
  final List<Map<String,Object?>> invoices,attendance;
  static Future<_StudentInfo> load(int id) async{
    final students=await Repository.instance.studentList();
    final row=students.firstWhere((s)=>intValue(s['id'])==id);
    return _StudentInfo(row,await Repository.instance.invoiceList(studentId:id),await Repository.instance.attendanceList(studentId:id));
  }
}
