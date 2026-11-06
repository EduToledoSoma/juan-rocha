import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  Database? _db;
  Future<Database>? _opening;

  /// On Linux and Windows sqflite uses the system SQLite via FFI.
  /// Android/iOS keep the existing native sqflite implementation.
  static void configurePlatform() {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database => _db != null
      ? Future.value(_db!)
      : (_opening ??= _openDatabase().catchError((Object error) {
          _opening = null;
          throw error;
        }));

  Future<Database> _openDatabase() async {
    final String dir;
    if (Platform.isLinux || Platform.isWindows) {
      final support = await getApplicationSupportDirectory();
      dir = p.join(support.path, 'JuanRochaBoxe', 'databases');
    } else {
      dir = await getDatabasesPath();
    }
    await Directory(dir).create(recursive: true);
    _db = await openDatabase(
      p.join(dir, 'juan_rocha_boxe.sqlite'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys=ON');
      },
      onCreate: (db, version) async {
        for (final sql in schema) {
          await db.execute(sql);
        }
      },
    );
    return _db!;
  }

  static const schema = <String>[
    '''CREATE TABLE plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, modality TEXT NOT NULL DEFAULT 'Boxe',
      fee_cents INTEGER NOT NULL CHECK(fee_cents>=0),
      duration_months INTEGER NOT NULL DEFAULT 1 CHECK(duration_months>0),
      weekly_sessions INTEGER NOT NULL DEFAULT 3,
      description TEXT NOT NULL DEFAULT '', active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE classes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, coach TEXT NOT NULL DEFAULT '',
      modality TEXT NOT NULL DEFAULT 'Boxe',
      weekdays TEXT NOT NULL DEFAULT '', start_time TEXT NOT NULL DEFAULT '18:00',
      capacity INTEGER NOT NULL DEFAULT 20 CHECK(capacity>0),
      active INTEGER NOT NULL DEFAULT 1
    )''',
    '''CREATE TABLE students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '',
      birth_date TEXT, cpf TEXT NOT NULL DEFAULT '', email TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT '', emergency_phone TEXT NOT NULL DEFAULT '',
      guardian_name TEXT NOT NULL DEFAULT '', guardian_phone TEXT NOT NULL DEFAULT '',
      joined_at TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive','suspended','cancelled')),
      plan_id INTEGER REFERENCES plans(id) ON DELETE SET NULL,
      class_id INTEGER REFERENCES classes(id) ON DELETE SET NULL,
      notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    'CREATE INDEX idx_students_name ON students(name)',
    'CREATE INDEX idx_students_plan ON students(plan_id)',
    '''CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
      plan_id INTEGER REFERENCES plans(id) ON DELETE SET NULL,
      competency TEXT NOT NULL, due_date TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK(amount_cents>=0),
      discount_cents INTEGER NOT NULL DEFAULT 0 CHECK(discount_cents>=0),
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','cancelled','waived')),
      notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(student_id, competency), CHECK(discount_cents <= amount_cents)
    )''',
    '''CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
      amount_cents INTEGER NOT NULL CHECK(amount_cents>0),
      paid_at TEXT NOT NULL, method TEXT NOT NULL,
      notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE finance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      direction TEXT NOT NULL CHECK(direction IN ('income','expense')),
      category TEXT NOT NULL, description TEXT NOT NULL,
      amount_cents INTEGER NOT NULL CHECK(amount_cents>0),
      occurred_at TEXT NOT NULL,
      source_type TEXT, source_id INTEGER,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(source_type, source_id)
    )''',
    'CREATE INDEX idx_finance_occurred ON finance(occurred_at)',
    '''CREATE TABLE attendance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
      class_id INTEGER REFERENCES classes(id) ON DELETE SET NULL,
      lesson_date TEXT NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('present','absent','justified')),
      notes TEXT NOT NULL DEFAULT '',
      UNIQUE(student_id, lesson_date)
    )''',
    '''CREATE TABLE leads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '', email TEXT NOT NULL DEFAULT '',
      modality TEXT NOT NULL DEFAULT 'Boxe', origin TEXT NOT NULL DEFAULT '',
      stage TEXT NOT NULL DEFAULT 'Novo contato',
      followup_date TEXT, notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, category TEXT NOT NULL DEFAULT 'Uniformes',
      price_cents INTEGER NOT NULL CHECK(price_cents>=0),
      stock INTEGER NOT NULL DEFAULT 0 CHECK(stock>=0),
      active INTEGER NOT NULL DEFAULT 1
    )''',
    '''CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
      quantity INTEGER NOT NULL CHECK(quantity>0),
      unit_price_cents INTEGER NOT NULL CHECK(unit_price_cents>=0),
      total_cents INTEGER NOT NULL CHECK(total_cents>=0),
      sold_at TEXT NOT NULL
    )''',
    '''CREATE TABLE audit_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity TEXT NOT NULL, action TEXT NOT NULL, details TEXT NOT NULL DEFAULT '',
      happened_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE settings (
      key TEXT PRIMARY KEY, value TEXT NOT NULL
    )''',
  ];
}
