import 'package:flutter/material.dart';
import '../core/repository.dart';
import '../core/utils.dart';
import 'style.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key,required this.onNavigate});
  final void Function(int) onNavigate;
  @override State<DashboardTab> createState()=>_DashboardTabState();
}
class _DashboardTabState extends State<DashboardTab> {
  late Future<_DashboardModel> future;
  @override void initState(){super.initState();refresh();}
  void refresh(){future=_DashboardModel.load();}
  @override Widget build(BuildContext context)=>FutureBuilder<_DashboardModel>(
    future:future,builder:(context,s){
      if(s.hasError)return JrEmpty(text:'Não foi possível carregar: ${s.error}',icon:Icons.error_outline);
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final m=s.data!;final t=m.stats;
      return RefreshIndicator(onRefresh:()async{setState(refresh);await future;},child:ListView(padding:const EdgeInsets.fromLTRB(18,17,18,28),children:[
        const Text('CENTRAL DO CT',style:TextStyle(color:brandGold,fontSize:12,fontWeight:FontWeight.w900,letterSpacing:2)),
        const SizedBox(height:7),
        const Text('Visão geral',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),
        Text('Dados reais deste iPhone • ${displayDate(todayIso())}',style:const TextStyle(color:brandMuted,fontSize:12)),
        const SizedBox(height:20),
        GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
          crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.36,children:[
            JrStat(label:'Alunos ativos',value:'${t['students']}',icon:Icons.groups_2_outlined),
            JrStat(label:'Inadimplências',value:'${t['overdue']}',icon:Icons.warning_amber_rounded,danger:intValue(t['overdue'])>0),
            JrStat(label:'Recebido hoje',value:money(intValue(t['day_income'])),icon:Icons.payments_outlined),
            JrStat(label:'Recebido no mês',value:money(intValue(t['month_income'])),icon:Icons.trending_up),
            JrStat(label:'Despesas do mês',value:money(intValue(t['month_expense'])),icon:Icons.receipt_long_outlined),
            JrStat(label:'Presenças hoje',value:'${t['presences']}',icon:Icons.how_to_reg_outlined),
          ]),
        const SizedBox(height:20),
        JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Resultado mensal',style:TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:9),Text(money(intValue(t['month_income'])-intValue(t['month_expense'])),style:const TextStyle(color:brandGoldLight,fontWeight:FontWeight.w900,fontSize:30)),
          const Text('Receitas efetivamente registradas menos despesas',style:TextStyle(fontSize:12,color:brandMuted)),
        ])),
        const SizedBox(height:18),
        Row(children:[const Expanded(child:Text('Acesso rápido',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18))),
          TextButton(onPressed:()=>widget.onNavigate(4),child:const Text('Ver gestão'))]),
        Wrap(spacing:9,runSpacing:9,children:[
          ActionChip(label:const Text('Alunos'),avatar:const Icon(Icons.person_add_alt_1,size:19),onPressed:()=>widget.onNavigate(1)),
          ActionChip(label:const Text('Presenças'),avatar:const Icon(Icons.task_alt,size:19),onPressed:()=>widget.onNavigate(2)),
          ActionChip(label:const Text('Mensalidades'),avatar:const Icon(Icons.payments,size:19),onPressed:()=>widget.onNavigate(3)),
        ]),
        const SizedBox(height:20),
        const Text('Aniversariantes do mês',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
        const SizedBox(height:10),
        if(m.birthdays.isEmpty)const JrEmpty(text:'Nenhum aniversariante cadastrado neste mês',icon:Icons.cake_outlined)
        else ...m.birthdays.map((r)=>JrPanel(padding:const EdgeInsets.all(13),child:ListTile(
          contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:brandGold,child:Icon(Icons.cake_outlined,color:brandBlack)),
          title:Text(textValue(r['name'])),subtitle:Text('${displayDate(textValue(r['birth_date']))}  •  ${textValue(r['phone'])}'),
        ))).expand((x)=>[x,const SizedBox(height:9)]),
        const SizedBox(height:14),
        const Text('Frequência dos últimos meses',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
        const SizedBox(height:10),
        if(m.frequency.isEmpty)const JrEmpty(text:'Registre presenças para ver o gráfico',icon:Icons.bar_chart)
        else JrPanel(child:Column(children:m.frequency.reversed.map((r){
          final total=intValue(r['total']); final present=intValue(r['present']);
          return Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Column(children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(textValue(r['month'])),Text('$present / $total',style:const TextStyle(color:brandGold))]),
            const SizedBox(height:6),LinearProgressIndicator(value:total==0?0:present/total,color:brandGold,backgroundColor:const Color(0xFF3B3B3B),minHeight:7,borderRadius:BorderRadius.circular(9)),
          ]));
        }).toList())),
      ]));
    },
  );
}
class _DashboardModel {
  const _DashboardModel(this.stats,this.birthdays,this.frequency);
  final Map<String,Object?> stats;
  final List<Map<String,Object?>> birthdays,frequency;
  static Future<_DashboardModel> load()async=>_DashboardModel(
    await Repository.instance.dashboard(),await Repository.instance.birthdayList(),await Repository.instance.monthlyFrequency());
}
