import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'students.dart';
import 'agenda.dart';
import 'finance.dart';
import 'management.dart';
import 'style.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState()=>_AppShellState();
}
class _AppShellState extends State<AppShell> {
  int index=0;
  int generation=0;
  @override Widget build(BuildContext context){
    final screens=<Widget>[
      DashboardTab(key:ValueKey('home$generation'),onNavigate:(i)=>setState(()=>index=i)),
      StudentsTab(key:ValueKey('students$generation')),
      AgendaTab(key:ValueKey('agenda$generation')),
      FinanceTab(key:ValueKey('finance$generation')),
      ManagementTab(key:ValueKey('manage$generation')),
    ];
    return Scaffold(
      appBar:AppBar(title:Row(children:[
        Image.asset('assets/brand/logo_original.jpg',height:42,width:42,fit:BoxFit.cover),
        const SizedBox(width:10),
        const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('JUAN ROCHA BOXE',style:TextStyle(fontWeight:FontWeight.w900,fontSize:16,letterSpacing:.6)),
          Text('JR BOXE GESTÃO',style:TextStyle(color:brandGold,fontSize:10,letterSpacing:1.5)),
        ])),
      ]),actions:[IconButton(tooltip:'Atualizar',onPressed:()=>setState(()=>generation++),icon:const Icon(Icons.refresh))]),
      body:SafeArea(child:screens[index]),
      bottomNavigationBar:NavigationBar(
        selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),
        backgroundColor:brandSurface,indicatorColor:const Color(0xFF554722),height:72,
        labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,
        destinations:const [
          NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard,color:brandGoldLight),label:'Início'),
          NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people,color:brandGoldLight),label:'Alunos'),
          NavigationDestination(icon:Icon(Icons.event_note_outlined),selectedIcon:Icon(Icons.event_note,color:brandGoldLight),label:'Agenda'),
          NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet,color:brandGoldLight),label:'Financeiro'),
          NavigationDestination(icon:Icon(Icons.tune_outlined),selectedIcon:Icon(Icons.tune,color:brandGoldLight),label:'Gestão'),
        ],
      ),
    );
  }
}
