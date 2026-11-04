import 'package:flutter/material.dart';
import '../core/utils.dart';
import 'style.dart';

enum FieldKind { text, multi, money, number, date, select, foreign, phone }

class FieldSpec {
  const FieldSpec(this.key,this.label,{this.kind=FieldKind.text,this.mandatory=false,this.initial='',this.options=const {},this.values=const {}});
  final String key,label,initial;
  final FieldKind kind;
  final bool mandatory;
  final Map<String,String> options;
  final Map<int,String> values;
}

Future<Map<String,Object?>?> editEntity(BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  Map<String,Object?>? original,
}) async {
  return showModalBottomSheet<Map<String,Object?>>(
    context:context,isScrollControlled:true,useSafeArea:true,
    backgroundColor:brandSurface,showDragHandle:true,
    builder:(ctx)=>_EntityForm(title:title,fields:fields,original:original??{}),
  );
}

class _EntityForm extends StatefulWidget {
  const _EntityForm({required this.title,required this.fields,required this.original});
  final String title;
  final List<FieldSpec> fields;
  final Map<String,Object?> original;
  @override State<_EntityForm> createState()=>_EntityFormState();
}

class _EntityFormState extends State<_EntityForm> {
  final _formKey=GlobalKey<FormState>();
  final Map<String,TextEditingController> controllers={};
  final Map<String,Object?> selected={};
  @override void initState(){super.initState();
    for(final f in widget.fields) {
      final init=widget.original[f.key];
      if(f.kind==FieldKind.foreign || f.kind==FieldKind.select){
        selected[f.key]=init??(f.kind==FieldKind.select? f.initial:null);
      } else {
        controllers[f.key]=TextEditingController(text:init==null?f.initial:(f.kind==FieldKind.money?editMoney(intValue(init)):init.toString()));
      }
    }
  }
  @override void dispose(){for(final c in controllers.values){c.dispose();}super.dispose();}

  void save(){
    if(!_formKey.currentState!.validate())return;
    final out=<String,Object?>{};
    for(final f in widget.fields){
      if(f.kind==FieldKind.foreign){out[f.key]=selected[f.key];continue;}
      if(f.kind==FieldKind.select){out[f.key]=selected[f.key];continue;}
      final value=controllers[f.key]!.text.trim();
      if(f.kind==FieldKind.money)out[f.key]=parseMoney(value);
      else if(f.kind==FieldKind.number)out[f.key]=int.tryParse(value)??0;
      else out[f.key]=value.isEmpty && f.kind==FieldKind.date?null:value;
    }
    Navigator.pop(context,out);
  }

  @override Widget build(BuildContext context){
    final insets=MediaQuery.viewInsetsOf(context).bottom;
    return Padding(padding:EdgeInsets.fromLTRB(20,8,20,insets+24),child:SafeArea(top:false,child:SingleChildScrollView(child:Form(key:_formKey,child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
        Text(widget.title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
        const SizedBox(height:20),
        ...widget.fields.map((f)=>Padding(padding:const EdgeInsets.only(bottom:14),child:_field(f))),
        const SizedBox(height:8),ElevatedButton.icon(onPressed:save,icon:const Icon(Icons.check),label:const Text('SALVAR')),
      ],
    )))));
  }

  Widget _field(FieldSpec f){
    if(f.kind==FieldKind.foreign){
      final choices=<DropdownMenuItem<int?>>[
        const DropdownMenuItem<int?>(value:null,child:Text('Não vinculado')),
        ...f.values.entries.map((e)=>DropdownMenuItem<int?>(value:e.key,child:Text(e.value,overflow:TextOverflow.ellipsis))),
      ];
      final current=selected[f.key] is int ? selected[f.key] as int : (int.tryParse('${selected[f.key]}'));
      return DropdownButtonFormField<int?>(
        value:f.values.containsKey(current)?current:null,
        decoration:InputDecoration(labelText:f.label),
        isExpanded:true,items:choices,
        onChanged:(v)=>setState(()=>selected[f.key]=v),
      );
    }
    if(f.kind==FieldKind.select){
      final values=f.options.keys.toList();
      final current=selected[f.key]?.toString();
      return DropdownButtonFormField<String>(
        value:values.contains(current)?current:values.isEmpty?null:values.first,
        decoration:InputDecoration(labelText:f.label),isExpanded:true,
        items:f.options.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),
        onChanged:(v)=>setState(()=>selected[f.key]=v),
      );
    }
    final c=controllers[f.key]!;
    return TextFormField(controller:c,
      maxLines:f.kind==FieldKind.multi?3:1,
      readOnly:f.kind==FieldKind.date,
      keyboardType:f.kind==FieldKind.phone?TextInputType.phone:
        f.kind==FieldKind.money?const TextInputType.numberWithOptions(decimal:true):
        f.kind==FieldKind.number?TextInputType.number:TextInputType.text,
      decoration:InputDecoration(labelText:f.label, suffixIcon:f.kind==FieldKind.date?const Icon(Icons.calendar_month,color:brandGold):null),
      onTap:f.kind!=FieldKind.date?null:() async {
        final existing=DateTime.tryParse(c.text);
        final day=await showDatePicker(context:context,initialDate:existing??DateTime.now(),firstDate:DateTime(1920),lastDate:DateTime(2100));
        if(day!=null) c.text=day.toIso8601String().substring(0,10);
      },
      validator:(v){
        if(f.mandatory && (v==null||v.trim().isEmpty))return 'Campo obrigatório';
        if(f.kind==FieldKind.money && f.mandatory && parseMoney(v??'')<=0)return 'Informe valor maior que zero';
        if(f.kind==FieldKind.number && f.mandatory && (int.tryParse(v??'')??0)<=0)return 'Informe número maior que zero';
        return null;
      },
    );
  }
}

Future<DateTime?> pickDay(BuildContext context, DateTime initial) => showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2020),lastDate:DateTime(2100));
