import 'package:flutter/material.dart';

const brandGold = Color(0xFFC5A253);
const brandGoldLight = Color(0xFFE0C57A);
const brandBlack = Color(0xFF080808);
const brandSurface = Color(0xFF181818);
const brandMuted = Color(0xFFABABAB);
const brandRed = Color(0xFFFF7777);

ThemeData jrTheme() {
  const scheme = ColorScheme.dark(
    primary: brandGold, onPrimary: brandBlack,
    secondary: brandGoldLight, onSecondary: brandBlack,
    surface: brandSurface, onSurface: Colors.white,
    error: brandRed,
  );
  return ThemeData(
    useMaterial3:true,
    brightness:Brightness.dark,
    scaffoldBackgroundColor:brandBlack,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(backgroundColor: brandBlack, foregroundColor: Colors.white, centerTitle:false),
    inputDecorationTheme: InputDecorationTheme(
      filled:true, fillColor:const Color(0xFF232323),
      contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:BorderSide.none),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:const BorderSide(color:brandGold)),
      labelStyle:const TextStyle(color:brandMuted),
    ),
    cardTheme:CardThemeData(color:brandSurface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),margin:EdgeInsets.zero),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor:brandGold,foregroundColor:brandBlack,
      padding:const EdgeInsets.symmetric(horizontal:18,vertical:15),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13)),
      textStyle:const TextStyle(fontWeight:FontWeight.w800),
    )),
    floatingActionButtonTheme:const FloatingActionButtonThemeData(backgroundColor:brandGold,foregroundColor:brandBlack),
    dividerColor:const Color(0xFF333333),
  );
}

class JrPanel extends StatelessWidget {
  const JrPanel({super.key, required this.child, this.padding=const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override Widget build(BuildContext context) => Container(
    width:double.infinity,padding:padding,
    decoration:BoxDecoration(color:brandSurface,border:Border.all(color:const Color(0xFF282828)),borderRadius:BorderRadius.circular(19)),
    child:child,
  );
}

class JrEmpty extends StatelessWidget {
  const JrEmpty({super.key, required this.text, this.icon=Icons.inbox_outlined});
  final String text; final IconData icon;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:40,color:brandGold),const SizedBox(height:12),Text(text,textAlign:TextAlign.center,style:const TextStyle(color:brandMuted))]));
}

class JrStat extends StatelessWidget {
  const JrStat({super.key,required this.label,required this.value,required this.icon,this.danger=false});
  final String label,value; final IconData icon; final bool danger;
  @override Widget build(BuildContext context)=>JrPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:danger?brandRed:brandGold,size:23),
    const SizedBox(height:13),
    Text(value,style:TextStyle(color:danger?brandRed:Colors.white,fontSize:23,fontWeight:FontWeight.w900),maxLines:1),
    const SizedBox(height:5),Text(label,style:const TextStyle(color:brandMuted,fontSize:12)),
  ]));
}

void showJrError(BuildContext context, Object error) {
  if(!context.mounted)return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$error'),backgroundColor:const Color(0xFF7B3030),behavior:SnackBarBehavior.floating));
}
void showJrOk(BuildContext context, [String text='Salvo com sucesso']) {
  if(!context.mounted)return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text),backgroundColor:const Color(0xFF365138),behavior:SnackBarBehavior.floating));
}
Future<bool> askConfirm(BuildContext context, String message) async =>
  await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
    title:const Text('Confirmar ação'),content:Text(message),actions:[
      TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Confirmar')),
    ])) ?? false;
