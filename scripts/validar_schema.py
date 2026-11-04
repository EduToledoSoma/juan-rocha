#!/usr/bin/env python3
"""Teste independente das constraints SQLite usando as declarações do app Flutter."""
from pathlib import Path
import re, sqlite3

source = (Path(__file__).resolve().parents[1] / 'lib/core/db.dart').read_text()
section = source.split('static const schema = <String>[', 1)[1].split('\n  ];', 1)[0]
sqls = re.findall(r"'''(.*?)'''|'([^']*)'", section, re.S)
statements = [a or b for a,b in sqls]
assert len(statements)>=13, f'Schema incompleto: {len(statements)}'

conn=sqlite3.connect(':memory:')
conn.execute('PRAGMA foreign_keys=ON')
for stmt in statements:
    conn.execute(stmt)

conn.execute("INSERT INTO plans(name,fee_cents) VALUES('Boxe 3x',15900)")
conn.execute("INSERT INTO classes(title,coach) VALUES('Boxe Noite','Juan')")
conn.execute("INSERT INTO students(name,phone,joined_at,plan_id,class_id) VALUES('Aluno Teste','000','2026-11-04',1,1)")
conn.execute("INSERT INTO invoices(student_id,plan_id,competency,due_date,amount_cents) VALUES(1,1,'2026-11','2026-11-10',15900)")
try:
    conn.execute("INSERT INTO invoices(student_id,plan_id,competency,due_date,amount_cents) VALUES(1,1,'2026-11','2026-11-10',15900)")
    raise AssertionError('Duplicata da competência foi permitida')
except sqlite3.IntegrityError: pass
conn.execute("INSERT INTO payments(invoice_id,amount_cents,paid_at,method) VALUES(1,5900,'2026-11-04','PIX')")
conn.execute("INSERT INTO finance(direction,category,description,amount_cents,occurred_at,source_type,source_id) VALUES('income','Mensalidade','Parcial',5900,'2026-11-04','payment',1)")
try:
    conn.execute("INSERT INTO finance(direction,category,description,amount_cents,occurred_at,source_type,source_id) VALUES('income','Mensalidade','Duplicata',5900,'2026-11-04','payment',1)")
    raise AssertionError('Duplo lançamento financeiro foi permitido')
except sqlite3.IntegrityError: pass
conn.execute("INSERT INTO attendance(student_id,lesson_date,status) VALUES(1,'2026-11-04','present')")
try:
    conn.execute("INSERT INTO attendance(student_id,lesson_date,status) VALUES(1,'2026-11-04','absent')")
    raise AssertionError('Duas presenças no mesmo dia foram permitidas')
except sqlite3.IntegrityError: pass
conn.execute("INSERT INTO products(name,price_cents,stock) VALUES('Luvas',20000,2)")
try:
    conn.execute("UPDATE products SET stock=stock-3 WHERE id=1")
    raise AssertionError('Estoque negativo foi permitido')
except sqlite3.IntegrityError: pass
conn.execute("INSERT INTO leads(name,stage) VALUES('Contato Teste','Novo contato')")
assert conn.execute('SELECT COUNT(*) FROM sqlite_master WHERE type="table"').fetchone()[0]>=12
print(f'Schema SQLite OK • {len(statements)} declarações • 5 restrições verificadas • sem banco real')
