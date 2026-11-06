import 'package:flutter/material.dart';
import '../core/repository.dart';
import '../core/utils.dart';
import 'forms.dart';
import 'style.dart';

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key});
  @override State<AgendaTab> createState()=>_AgendaTabState();
}
class _AgendaTabState extends State<AgendaTab> {
  late Future<List<Map<String,Object?>>> future;
  @override void initState(){super.initState();reload();}
  void reload() { future=Repository.instance.list('classes',orderBy:'start_time, id'); }

  Future<void> editor([Map<String,Object?>? row]) async {
    final values=await editEntity(context,title:row==null?'Nova turma':'Editar turma',original:row,fields:const [
      FieldSpec('title','Nome da turma',mandatory:true),FieldSpec('coach','Professor'),
      FieldSpec('modality','Modalidade',initial:'Boxe'),
      FieldSpec('weekdays','Dias da semana (ex.: Seg, Qua, Sex)'),
      FieldSpec('start_time','Horário (HH:MM)',initial:'18:00',mandatory:true),
      FieldSpec('capacity','Vagas',kind:FieldKind.number,initial:'20',mandatory:true),
      FieldSpec('active','Status',kind:FieldKind.select,initial:'1',options:{'1':'Ativa','0':'Inativa'}),
    ]);
    if(values==null)return;
    try {
      final data={...values,'active':int.tryParse(textValue(values['active']))??1};
      if(!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(textValue(data['start_time']))) throw StateError('Horário precisa ser HH:MM');
      await Repository.instance.save('classes',data,id:row==null?null:intValue(row['id']));
      if(!mounted)return;showJrOk(context);setState(reload);
    }catch(e){showJrError(context,e);}
  }

  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.transparent,
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>editor(),icon:const Icon(Icons.add),label:const Text('TURMA')),
    body:FutureBuilder<List<Map<String,Object?>>>(future:future,builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,110),children:[
        const Text('Agenda de aulas',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900)),
        const SizedBox(height:4),const Text('Turmas, horários e controle de presença',style:TextStyle(color:brandMuted)),
        const SizedBox(height:16),ElevatedButton.icon(onPressed:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const CheckinPage()));if(mounted)setState(reload);},icon:const Icon(Icons.how_to_reg),label:const Text('REGISTRAR FREQUÊNCIA')),
        const SizedBox(height:18),
        if(s.data!.isEmpty)const JrEmpty(text:'Cadastre a primeira turma usando + TURMA',icon:Icons.event_note_outlined),
        ...s.data!.map((r)=>Padding(padding:const EdgeInsets.only(bottom:10),child:JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const Icon(Icons.sports_mma,color:brandGold),const SizedBox(width:8),Expanded(child:Text(textValue(r['title']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17))),
            IconButton(onPressed:()=>editor(r),icon:const Icon(Icons.edit_outlined,color:brandGold))]),
          Text('${r['weekdays']}   •   ${r['start_time']}',style:const TextStyle(color:brandGoldLight)),
          const SizedBox(height:6),Text('Professor: ${r['coach']}  •  Vagas: ${r['capacity']} ${r['active']==1?'':'• INATIVA'}',style:const TextStyle(color:brandMuted,fontSize:12)),
        ])))),
      ]);
    }),
  );
}

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});
  @override State<CheckinPage> createState()=>_CheckinPageState();
}
class _CheckinPageState extends State<CheckinPage> {
  DateTime date=DateTime.now();
  int? classId;
  late Future<_CheckinData> future;
  @override void initState(){super.initState();reload();}
  void reload() { future=_CheckinData.load(date); }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Controle de frequência')),
    body:FutureBuilder<_CheckinData>(future:future,builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final d=s.data!;
      final students=d.students.where((r)=>r['status']=='active' && (classId==null||r['class_id']==classId)).toList();
      final recorded={for(final r in d.attendance)intValue(r['student_id']):textValue(r['status'])};
      return ListView(padding:const EdgeInsets.all(18),children:[
        OutlinedButton.icon(onPressed:()async{final picked=await pickDay(context,date);if(picked!=null){setState((){date=picked;reload();});}},icon:const Icon(Icons.calendar_month),label:Text('Data: ${displayDate(date.toIso8601String())}')),
        const SizedBox(height:13),DropdownButtonFormField<int?>(
          value:classId,decoration:const InputDecoration(labelText:'Turma'),isExpanded:true,
          items:[const DropdownMenuItem<int?>(value:null,child:Text('Todos os alunos ativos')),...d.classes.map((r)=>DropdownMenuItem<int?>(value:intValue(r['id']),child:Text(textValue(r['title']))))],
          onChanged:(v)=>setState(()=>classId=v),
        ),const SizedBox(height:15),
        Text('Alunos: ${students.length} • presença por aluno e dia',style:const TextStyle(color:brandMuted,fontSize:12)),const SizedBox(height:12),
        if(students.isEmpty)const JrEmpty(text:'Não há alunos ativos nesta turma'),
        ...students.map((r)=>Padding(padding:const EdgeInsets.only(bottom:9),child:JrPanel(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(textValue(r['name']),style:const TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(height:8),Wrap(spacing:8,children:[
            for(final option in const {'present':'Presente','absent':'Falta','justified':'Justificada'}.entries)
              ChoiceChip(label:Text(option.value),selected:recorded[intValue(r['id'])]==option.key,
                onSelected:(_)async{
                  try{
                    await Repository.instance.recordAttendance(studentId:intValue(r['id']),classId:r['class_id'] as int?,date:date.toIso8601String().substring(0,10),status:option.key);
                    if(mounted)setState(reload);
                  }catch(e){showJrError(context,e);}
                }),
          ]),
        ])))),
      ]);
    }),
  );
}
class _CheckinData {
  const _CheckinData(this.students,this.classes,this.attendance);
  final List<Map<String,Object?>> students,classes,attendance;
  static Future<_CheckinData> load(DateTime date) async=>_CheckinData(
    await Repository.instance.studentList(),await Repository.instance.list('classes'),
    await Repository.instance.attendanceList(date:date.toIso8601String().substring(0,10)),
  );
}
