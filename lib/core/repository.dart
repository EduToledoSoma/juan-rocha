import 'package:sqflite/sqflite.dart';
import 'db.dart';
import 'utils.dart';

class Repository {
  Repository._();
  static final Repository instance = Repository._();

  Future<Database> get db => AppDb.instance.database;

  static const editableTables = {'students','plans','classes','leads','products'};
  Future<List<Map<String, Object?>>> list(String table, {String orderBy='id DESC'}) async {
    if (!editableTables.contains(table)) throw ArgumentError('Tabela inválida');
    return (await db).query(table, orderBy: orderBy);
  }

  Future<int> save(String table, Map<String, Object?> record, {int? id}) async {
    if (!editableTables.contains(table)) throw ArgumentError('Tabela inválida');
    final d = await db;
    final values = Map<String,Object?>.from(record)..remove('id');
    if (id == null) {
      final newId = await d.insert(table, values);
      await _audit(d, table,'insert', '$newId');
      return newId;
    }
    await d.update(table,values,where:'id=?',whereArgs:[id]);
    await _audit(d,table,'update','$id');
    return id;
  }

  Future<void> _audit(DatabaseExecutor db, String entity, String action, String details) async {
    await db.insert('audit_log', {'entity':entity,'action':action,'details':details});
  }

  Future<List<Map<String, Object?>>> studentList() async => (await db).rawQuery('''
    SELECT s.*, p.name AS plan_name, p.fee_cents AS plan_fee, c.title AS class_name
    FROM students s LEFT JOIN plans p ON p.id=s.plan_id
    LEFT JOIN classes c ON c.id=s.class_id ORDER BY s.name COLLATE NOCASE''');

  Future<List<Map<String, Object?>>> invoiceList({int? studentId}) async {
    final where = studentId == null ? '' : 'WHERE i.student_id=?';
    return (await db).rawQuery('''
      SELECT i.*, s.name AS student_name,
        COALESCE((SELECT SUM(p.amount_cents) FROM payments p WHERE p.invoice_id=i.id),0) AS paid_cents
      FROM invoices i JOIN students s ON s.id=i.student_id $where
      ORDER BY i.due_date DESC,i.id DESC
    ''', studentId == null ? [] : [studentId]);
  }

  Future<void> createInvoice({required int studentId,required String competency,required String dueDate,required int amountCents,required int? planId, int discountCents=0}) async {
    final d = await db;
    await d.transaction((txn) async {
      final active = await txn.query('students',columns:['id'],where:'id=? AND status=?',whereArgs:[studentId,'active']);
      if(active.isEmpty) throw StateError('Somente alunos ativos podem receber uma nova mensalidade.');
      if(amountCents <= 0 || discountCents<0 || discountCents>=amountCents) throw StateError('Valor ou desconto inválido.');
      final newId=await txn.insert('invoices',{
        'student_id':studentId,'plan_id':planId,'competency':competency,
        'due_date':dueDate,'amount_cents':amountCents,'discount_cents':discountCents,
      });
      await _audit(txn,'invoices','insert','$newId aluno=$studentId competência=$competency');
    });
  }

  Future<void> payInvoice({required int invoiceId,required int amountCents,required String method, String notes=''}) async {
    final d=await db;
    await d.transaction((txn) async {
      final rows=await txn.rawQuery('''SELECT i.*,
        COALESCE((SELECT SUM(p.amount_cents) FROM payments p WHERE p.invoice_id=i.id),0) AS paid_cents
        FROM invoices i WHERE i.id=?''',[invoiceId]);
      if(rows.isEmpty) throw StateError('Mensalidade não encontrada');
      final invoice=rows.first;
      if(invoice['status']!='pending') throw StateError('Mensalidade cancelada ou isenta');
      final remaining=intValue(invoice['amount_cents'])-intValue(invoice['discount_cents'])-intValue(invoice['paid_cents']);
      if(amountCents<=0 || amountCents>remaining) throw StateError('Pagamento maior que o saldo ou inválido');
      final paymentId=await txn.insert('payments',{'invoice_id':invoiceId,'amount_cents':amountCents,'method':method,'paid_at':todayIso(),'notes':notes});
      await txn.insert('finance',{
        'direction':'income','category':'Mensalidade','description':'Pagamento mensalidade #$invoiceId',
        'amount_cents':amountCents,'occurred_at':todayIso(),'source_type':'payment','source_id':paymentId,
      });
      await _audit(txn,'payments','insert','$paymentId mensalidade=$invoiceId valor=$amountCents');
    });
  }

  Future<void> changeInvoiceStatus(int invoiceId, String status) async {
    if(!['cancelled','waived'].contains(status)) throw StateError('Estado inválido');
    final d=await db;
    await d.transaction((txn) async {
      final paid = Sqflite.firstIntValue(await txn.rawQuery('SELECT COUNT(*) FROM payments WHERE invoice_id=?',[invoiceId])) ?? 0;
      if(paid>0) throw StateError('Há pagamentos registrados. Não é possível cancelar ou isentar sem estorno auditado.');
      await txn.update('invoices',{'status':status},where:'id=? AND status=?',whereArgs:[invoiceId,'pending']);
      await _audit(txn,'invoices','status','$invoiceId $status');
    });
  }

  Future<List<Map<String,Object?>>> paymentHistory(int invoiceId) async => (await db).query('payments',where:'invoice_id=?',whereArgs:[invoiceId],orderBy:'paid_at DESC,id DESC');

  Future<List<Map<String,Object?>>> financeList() async => (await db).query('finance',orderBy:'occurred_at DESC,id DESC');

  Future<void> addFinance({required String direction,required String category,required String description,required int amountCents,required String occurredAt}) async {
    if(!['income','expense'].contains(direction) || amountCents<=0) throw StateError('Movimentação inválida');
    final d=await db;
    await d.transaction((txn) async {
      final id=await txn.insert('finance',{'direction':direction,'category':category,'description':description,'amount_cents':amountCents,'occurred_at':occurredAt});
      await _audit(txn,'finance','insert','$id $direction $amountCents');
    });
  }

  Future<void> recordAttendance({required int studentId,required int? classId,required String date,required String status}) async {
    if(!['present','absent','justified'].contains(status)) throw StateError('Presença inválida');
    final d=await db;
    await d.transaction((txn) async {
      await txn.insert('attendance',{'student_id':studentId,'class_id':classId,'lesson_date':date,'status':status},conflictAlgorithm:ConflictAlgorithm.replace);
      await _audit(txn,'attendance','upsert','aluno=$studentId $date $status');
    });
  }

  Future<List<Map<String,Object?>>> attendanceList({String? date,int? studentId}) async {
    final filters=<String>[]; final args=<Object>[];
    if(date!=null) { filters.add('a.lesson_date=?');args.add(date); }
    if(studentId!=null) { filters.add('a.student_id=?');args.add(studentId); }
    final where=filters.isEmpty?'':'WHERE ${filters.join(' AND ')}';
    return (await db).rawQuery('''SELECT a.*,s.name AS student_name, c.title AS class_name
      FROM attendance a JOIN students s ON s.id=a.student_id
      LEFT JOIN classes c ON c.id=a.class_id $where ORDER BY a.lesson_date DESC,s.name''',args);
  }

  Future<void> sellProduct(int productId,int quantity) async {
    if(quantity<1) throw StateError('Quantidade inválida');
    final d=await db;
    await d.transaction((txn) async {
      final rows=await txn.query('products',where:'id=?',whereArgs:[productId]);
      if(rows.isEmpty) throw StateError('Produto não encontrado');
      final product=rows.first;
      if(product['active']!=1) throw StateError('Produto inativo');
      if(intValue(product['stock'])<quantity) throw StateError('Estoque insuficiente');
      final unit=intValue(product['price_cents']);
      if(unit<=0) throw StateError('Preço precisa ser maior que zero');
      final total=unit*quantity;
      await txn.rawUpdate('UPDATE products SET stock=stock-? WHERE id=? AND stock>=?',[quantity,productId,quantity]);
      final saleId=await txn.insert('sales',{'product_id':productId,'quantity':quantity,'unit_price_cents':unit,'total_cents':total,'sold_at':todayIso()});
      await txn.insert('finance',{'direction':'income','category':'Venda de produtos','description':'${product['name']} × $quantity','amount_cents':total,'occurred_at':todayIso(),'source_type':'sale','source_id':saleId});
      await _audit(txn,'sales','insert','$saleId produto=$productId qty=$quantity');
    });
  }

  Future<Map<String,Object?>> dashboard() async {
    final d=await db;
    final students=Sqflite.firstIntValue(await d.rawQuery("SELECT COUNT(*) FROM students WHERE status='active'"))??0;
    final inactive=Sqflite.firstIntValue(await d.rawQuery("SELECT COUNT(*) FROM students WHERE status!='active'"))??0;
    final month=monthKey();
    final today=todayIso();
    final current=await d.rawQuery('''SELECT direction, COALESCE(SUM(amount_cents),0) AS total
      FROM finance WHERE occurred_at LIKE ? GROUP BY direction''',['$month%']);
    final daily=await d.rawQuery("SELECT COALESCE(SUM(amount_cents),0) AS total FROM finance WHERE direction='income' AND occurred_at=?",[today]);
    final presences=Sqflite.firstIntValue(await d.rawQuery("SELECT COUNT(*) FROM attendance WHERE lesson_date=? AND status='present'",[today]))??0;
    final invoices=await invoiceList();
    final overdue=invoices.where((i)=>invoiceStatus(i)=='Vencida').length;
    final expiring=invoices.where((i)=>invoiceStatus(i)=='Pendente' && textValue(i['due_date']).compareTo(today)>=0 && textValue(i['due_date']).compareTo(DateTime.now().add(const Duration(days:5)).toIso8601String().substring(0,10))<=0).length;
    final birthdays=await birthdayList();
    return {
      'students':students,'inactive':inactive,'overdue':overdue,'expiring':expiring,
      'day_income':intValue(daily.first['total']),
      'month_income':current.where((r)=>r['direction']=='income').fold<int>(0,(a,r)=>a+intValue(r['total'])),
      'month_expense':current.where((r)=>r['direction']=='expense').fold<int>(0,(a,r)=>a+intValue(r['total'])),
      'presences':presences,'birthdays':birthdays.length,
    };
  }

  Future<List<Map<String,Object?>>> birthdayList() async {
    final rows=await studentList();
    final now=DateTime.now();
    return rows.where((r){
      final date=DateTime.tryParse(textValue(r['birth_date']));
      return r['status']=='active' && date!=null && date.month==now.month;
    }).toList()..sort((a,b) {
      final aa=DateTime.tryParse(textValue(a['birth_date']));
      final bb=DateTime.tryParse(textValue(b['birth_date']));
      return (aa?.day??0).compareTo(bb?.day??0);
    });
  }

  Future<List<Map<String,Object?>>> monthlyFrequency() async {
    return (await db).rawQuery('''SELECT substr(lesson_date,1,7) AS month,
      SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) AS present,
      COUNT(*) AS total FROM attendance GROUP BY substr(lesson_date,1,7)
      ORDER BY month DESC LIMIT 6''');
  }

  Future<List<Map<String,Object?>>> overdueStudents() async {
    final invoices=await invoiceList();
    return invoices.where((i)=>invoiceStatus(i)=='Vencida').toList();
  }

  Future<List<Map<String,Object?>>> lowFrequencyStudents() async {
    final d=await db;
    final cutoff=DateTime.now().subtract(const Duration(days:30)).toIso8601String().substring(0,10);
    return d.rawQuery('''SELECT s.id,s.name,s.phone,COUNT(a.id) AS total,
      SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END) AS present
      FROM students s JOIN attendance a ON a.student_id=s.id AND a.lesson_date>=?
      WHERE s.status='active' GROUP BY s.id
      HAVING COUNT(a.id)>=3 AND SUM(CASE WHEN a.status='present' THEN 1 ELSE 0 END)*100 < COUNT(a.id)*60
      ORDER BY present ASC''',[cutoff]);
  }

  Future<List<Map<String,Object?>>> audit() async => (await db).query('audit_log',orderBy:'id DESC',limit:100);
  Future<Map<String,List<Map<String,Object?>>>> exportAll() async {
    final d=await db;
    final out=<String,List<Map<String,Object?>>>{};
    for(final table in ['students','plans','classes','attendance','invoices','payments','finance','leads','products','sales','audit_log','settings']) {
      out[table]=await d.query(table);
    }
    return out;
  }
}
