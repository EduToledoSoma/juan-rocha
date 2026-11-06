import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'students.dart';
import 'agenda.dart';
import 'finance.dart';
import 'management.dart';
import 'style.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState()=>_AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index=0;
  int generation=0;

  void selectTab(int target)=>setState(() { index=target; generation++; });

  Future<void> openInvoices() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder:(_)=>const InvoicesPage()));
    if(mounted)setState(() => generation++);
  }

  Future<void> openCheckin() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder:(_)=>const CheckinPage()));
    if(mounted)setState(() => generation++);
  }

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.sizeOf(context).width;
    final desktop=width>=900;
    final screens=<Widget>[
      DashboardTab(key:ValueKey('home$generation'),onNavigate:selectTab,
        onOpenInvoices:openInvoices,onOpenCheckin:openCheckin),
      StudentsTab(key:ValueKey('students$generation')),
      AgendaTab(key:ValueKey('agenda$generation')),
      FinanceTab(key:ValueKey('finance$generation')),
      ManagementTab(key:ValueKey('manage$generation')),
    ];
    const destinations=<NavigationDestination>[
      NavigationDestination(icon:Icon(Icons.dashboard_outlined),
        selectedIcon:Icon(Icons.dashboard,color:brandGoldLight),label:'Início'),
      NavigationDestination(icon:Icon(Icons.people_outline),
        selectedIcon:Icon(Icons.people,color:brandGoldLight),label:'Alunos'),
      NavigationDestination(icon:Icon(Icons.event_note_outlined),
        selectedIcon:Icon(Icons.event_note,color:brandGoldLight),label:'Agenda'),
      NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),
        selectedIcon:Icon(Icons.account_balance_wallet,color:brandGoldLight),label:'Financeiro'),
      NavigationDestination(icon:Icon(Icons.tune_outlined),
        selectedIcon:Icon(Icons.tune,color:brandGoldLight),label:'Gestão'),
    ];
    final content=Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:1180),
      child:KeyedSubtree(key:ValueKey(index),child:screens[index]),
    ));
    return Scaffold(
      appBar:AppBar(
        title:Row(children:[
          ClipRRect(borderRadius:BorderRadius.circular(5),
            child:Image.asset('assets/brand/logo_original.jpg',height:42,width:42,fit:BoxFit.cover)),
          const SizedBox(width:12),
          const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('JUAN ROCHA BOXE',maxLines:1,overflow:TextOverflow.ellipsis,
              style:TextStyle(fontWeight:FontWeight.w900,fontSize:16,letterSpacing:.6)),
            Text('JR BOXE GESTÃO',style:TextStyle(color:brandGold,fontSize:10,letterSpacing:1.5)),
          ])),
        ]),
        actions:[IconButton(tooltip:'Atualizar dados',
          onPressed:()=>setState(()=>generation++),icon:const Icon(Icons.refresh))],
      ),
      body:SafeArea(child:desktop
        ? Row(children:[
            NavigationRail(
              backgroundColor:brandSurface,
              selectedIndex:index,
              extended:width>=1300,
              labelType:width>=1300?NavigationRailLabelType.none:NavigationRailLabelType.all,
              useIndicator:true,
              indicatorColor:const Color(0xFF554722),
              selectedIconTheme:const IconThemeData(color:brandGoldLight),
              selectedLabelTextStyle:const TextStyle(color:brandGoldLight,fontWeight:FontWeight.w800),
              onDestinationSelected:selectTab,
              destinations:const [
                NavigationRailDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:Text('Início')),
                NavigationRailDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:Text('Alunos')),
                NavigationRailDestination(icon:Icon(Icons.event_note_outlined),selectedIcon:Icon(Icons.event_note),label:Text('Agenda')),
                NavigationRailDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet),label:Text('Financeiro')),
                NavigationRailDestination(icon:Icon(Icons.tune_outlined),selectedIcon:Icon(Icons.tune),label:Text('Gestão')),
              ],
            ),
            const VerticalDivider(width:1,thickness:1,color:Color(0xFF363022)),
            Expanded(child:content),
          ])
        : content),
      bottomNavigationBar:desktop?null:NavigationBar(
        selectedIndex:index,
        onDestinationSelected:selectTab,
        backgroundColor:brandSurface,
        indicatorColor:const Color(0xFF554722),
        height:72,
        labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,
        destinations:destinations,
      ),
    );
  }
}
