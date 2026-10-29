import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RiyadhFactoryApp());
}

class RiyadhFactoryApp extends StatelessWidget {
  const RiyadhFactoryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'نظام محاسبة مصنع الرياض',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2463A6)),
          scaffoldBackgroundColor: const Color(0xFFF4F7FB),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF142B4A), foregroundColor: Colors.white),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const FactoryHome(),
      );
}

class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();
  SharedPreferences? _prefs;
  bool ready = false;
  final Map<String, List<Map<String, dynamic>>> data = {
    'products': [], 'sales': [], 'production': [], 'expenses': [],
    'customers': [], 'suppliers': [], 'purchases': [], 'payments': [],
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final key in data.keys) {
      final raw = _prefs!.getString('erp_$key');
      if (raw != null) {
        try { data[key] = List<Map<String, dynamic>>.from((jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e))); }
        catch (_) { data[key] = []; }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _save(String key) async {
    await _prefs?.setString('erp_$key', jsonEncode(data[key]));
    notifyListeners();
  }

  Future<void> add(String key, Map<String, dynamic> item) async {
    item['id'] = DateTime.now().microsecondsSinceEpoch.toString();
    item['createdAt'] = DateTime.now().toIso8601String();
    data[key]!.insert(0, item);
    await _save(key);
  }

  Future<void> remove(String key, String id) async {
    data[key]!.removeWhere((e) => e['id'] == id);
    await _save(key);
  }

  Future<void> update(String key, Map<String, dynamic> item) async {
    final i = data[key]!.indexWhere((e) => e['id'] == item['id']);
    if (i >= 0) data[key]![i] = item;
    await _save(key);
  }

  double sum(String key, String field, {bool todayOnly = false}) => data[key]!.where((e) {
    if (!todayOnly) return true;
    final d = DateTime.tryParse('${e['createdAt'] ?? ''}');
    final now = DateTime.now();
    return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
  }).fold<double>(0, (s, e) => s + ((e[field] as num?)?.toDouble() ?? 0));

  double get stockTotal => data['products']!.fold<double>(0, (s, p) => s + (((p['stock'] as num?)?.toDouble() ?? 0)));
  double get todaySales => sum('sales', 'total', todayOnly: true);
  double get totalSales => sum('sales', 'total');
  double get totalExpenses => sum('expenses', 'amount') + sum('purchases', 'total');
  double get receivables => data['sales']!.fold<double>(0, (s, e) => s + (((e['total'] as num?)?.toDouble() ?? 0) - ((e['paid'] as num?)?.toDouble() ?? 0)));
}

const moduleTitles = ['لوحة التحكم','المنتجات والمخزون','الإنتاج اليومي','المبيعات والفواتير','المصروفات','العملاء','الموردون والمشتريات','التقارير','الإعدادات'];
const moduleIcons = [Icons.dashboard_outlined, Icons.inventory_2_outlined, Icons.factory_outlined, Icons.point_of_sale_outlined, Icons.payments_outlined, Icons.people_outline, Icons.local_shipping_outlined, Icons.assessment_outlined, Icons.settings_outlined];

class FactoryHome extends StatefulWidget {
  const FactoryHome({super.key});
  @override State<FactoryHome> createState() => _FactoryHomeState();
}
class _FactoryHomeState extends State<FactoryHome> {
  int selected = 0;
  final store = Store.instance;
  @override void initState() { super.initState(); store.addListener(_refresh); store.init(); }
  void _refresh() { if (mounted) setState(() {}); }
  @override void dispose() { store.removeListener(_refresh); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (!store.ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = <Widget>[
      DashboardPage(onGo: (i) => setState(() => selected = i)),
      ProductsPage(),
      ProductionPage(),
      SalesPage(),
      ExpensesPage(),
      GenericRecordsPage(title: 'العملاء', storeKey: 'customers', fields: const [('اسم العميل','name'),('رقم الهاتف','phone'),('العنوان','note')], icon: Icons.person_add_alt_1),
      PurchasesPage(),
      ReportsPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(moduleTitles[selected]), actions: [IconButton(onPressed: () => setState(() => selected = 8), icon: const Icon(Icons.settings))]),
      drawer: Drawer(child: SafeArea(child: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.all(22), color: const Color(0xFF142B4A), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.factory, size: 42, color: Color(0xFFD5A742)), SizedBox(height: 12), Text('مصنع الرياض للبلك الأوتوماتيكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)), Text('نظام الإدارة والمحاسبة', style: TextStyle(color: Colors.white70))])), Expanded(child: ListView.builder(itemCount: moduleTitles.length, itemBuilder: (_, i) => ListTile(leading: Icon(moduleIcons[i]), title: Text(moduleTitles[i]), selected: selected == i, onTap: () { setState(() => selected = i); Navigator.pop(context); }))) ]))),
      body: IndexedStack(index: selected, children: pages),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onGo;
  const DashboardPage({super.key, required this.onGo});
  @override Widget build(BuildContext context) {
    final s = Store.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) => ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF142B4A), Color(0xFF2463A6)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.factory, size: 42, color: Color(0xFFD5A742)), SizedBox(height: 12), Text('مصنع الرياض للبلك الأوتوماتيكي', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('صنعاء، المطار، خط العروق', style: TextStyle(color: Colors.white70)), Text('هاتف التواصل: 773766177', style: TextStyle(color: Colors.white70))]),),
      const SizedBox(height: 18), const Text('ملخص النشاط المسجل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)), const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [MetricCard('مبيعات اليوم', money(s.todaySales), Icons.point_of_sale), MetricCard('إجمالي المبيعات', money(s.totalSales), Icons.payments), MetricCard('المصروفات والمشتريات', money(s.totalExpenses), Icons.money_off), MetricCard('ديون العملاء', money(s.receivables), Icons.people), MetricCard('عدد المنتجات', '${s.data['products']!.length}', Icons.inventory), MetricCard('إجمالي رصيد البلك', '${s.stockTotal.toStringAsFixed(0)} قطعة', Icons.factory)]),
      const SizedBox(height: 18), const Text('اختصارات العمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [quickButton(context, 'إضافة منتج', Icons.add_box, () => onGo(1)), quickButton(context, 'تسجيل إنتاج', Icons.factory, () => onGo(2)), quickButton(context, 'فاتورة بيع', Icons.receipt_long, () => onGo(3)), quickButton(context, 'تسجيل مصروف', Icons.payments, () => onGo(4))]),
      const SizedBox(height: 16), const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('الأرقام هنا محسوبة من السجلات التي تدخلها فقط. احتفظ بنسخة احتياطية دورية من بيانات الجهاز.')))
    ]));
  }
}
Widget quickButton(BuildContext context, String title, IconData icon, VoidCallback onTap) => FilledButton.tonalIcon(onPressed: onTap, icon: Icon(icon), label: Text(title));
class MetricCard extends StatelessWidget { final String title, value; final IconData icon; const MetricCard(this.title, this.value, this.icon, {super.key}); @override Widget build(BuildContext context) => SizedBox(width: MediaQuery.of(context).size.width / 2 - 25, height: 112, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: const Color(0xFF2463A6)), Text(title, style: const TextStyle(fontSize: 12)), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))])))); }

String money(double v) => '${v.toStringAsFixed(2)} ر.ي';

class ProductsPage extends StatelessWidget {
  ProductsPage({super.key}); final s = Store.instance;
  Future<void> _form(BuildContext context, [Map<String, dynamic>? old]) async {
    final name = TextEditingController(text: old?['name']?.toString() ?? '');
    final size = TextEditingController(text: old?['size']?.toString() ?? '');
    final price = TextEditingController(text: old?['price']?.toString() ?? '');
    final stock = TextEditingController(text: old?['stock']?.toString() ?? '0');
    final result = await showDialog<Map<String, String>>(context: context, builder: (ctx) => AlertDialog(title: Text(old == null ? 'إضافة منتج' : 'تعديل المنتج'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [field(name, 'اسم المنتج *'), const SizedBox(height: 10), field(size, 'المقاس / النوع'), const SizedBox(height: 10), field(price, 'سعر القطعة (ريال) *', numeric: true), const SizedBox(height: 10), field(stock, 'الرصيد الحالي بالقطعة', numeric: true)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(name.text.trim().isEmpty || number(price.text) < 0 || number(stock.text) < 0) return; Navigator.pop(ctx, {'name':name.text.trim(),'size':size.text.trim(),'price':price.text.trim(),'stock':stock.text.trim()}); }, child: const Text('حفظ'))]));
    if (result == null) return;
    final item = <String, dynamic>{'name':result['name'],'size':result['size'],'price':number(result['price']),'stock':number(result['stock'])};
    if (old == null) { await s.add('products', item); } else { item['id'] = old['id']; item['createdAt'] = old['createdAt']; await s.update('products', item); }
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _form(context), icon: const Icon(Icons.add), label: const Text('إضافة منتج')), body: s.data['products']!.isEmpty ? const EmptyState(icon: Icons.inventory_2, text: 'لا توجد منتجات. اضغط «إضافة منتج» لتسجيل أول نوع بلك ومقاسه وسعره.') : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), itemCount: s.data['products']!.length, itemBuilder: (_, i) { final p = s.data['products']![i]; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.view_module)), title: Text('${p['name']} ${p['size'] ?? ''}'), subtitle: Text('السعر: ${money((p['price'] as num).toDouble())}\nالمخزون: ${p['stock']} قطعة'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) async { if(v == 'edit') await _form(context, p); if(v == 'delete') await confirmDelete(context, () => s.remove('products', '${p['id']}')); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]))); })));
}

class ProductionPage extends StatelessWidget {
  ProductionPage({super.key}); final s = Store.instance;
  Future<void> _add(BuildContext context) async {
    if (s.data['products']!.isEmpty) { snack(context, 'أضف منتجًا أولًا من قسم المنتجات.'); return; }
    String? productId; final qty = TextEditingController(); final waste = TextEditingController(text: '0'); final note = TextEditingController();
    final r = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('تسجيل إنتاج يومي'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: productId, decoration: const InputDecoration(labelText: 'المنتج'), items: s.data['products']!.map((p) => DropdownMenuItem(value: '${p['id']}', child: Text('${p['name']} ${p['size'] ?? ''}'))).toList(), onChanged: (v) => setD(() => productId = v)), const SizedBox(height: 10), field(qty, 'الكمية السليمة (قطعة)', numeric: true), const SizedBox(height: 10), field(waste, 'التالف (قطعة)', numeric: true), const SizedBox(height: 10), field(note, 'ملاحظات')])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(productId == null || number(qty.text) <= 0 || number(waste.text) < 0) return; Navigator.pop(ctx, {'productId':productId,'qty':number(qty.text),'waste':number(waste.text),'note':note.text}); }, child: const Text('تسجيل'))])));
    if (r == null) return;
    final p = s.data['products']!.firstWhere((e) => e['id'] == r['productId']);
    p['stock'] = ((p['stock'] as num).toDouble() + (r['qty'] as num).toDouble()); await s.update('products', p);
    await s.add('production', {'productId':p['id'],'productName':p['name'],'qty':r['qty'],'waste':r['waste'],'note':r['note']});
    if(context.mounted) snack(context, 'تم حفظ الإنتاج وإضافة الكمية السليمة إلى المخزون.');
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('تسجيل إنتاج')), body: s.data['production']!.isEmpty ? const EmptyState(icon: Icons.factory, text: 'سجّل الإنتاج اليومي هنا. الكمية السليمة تُضاف إلى مخزون المنتج.') : ListView(children: s.data['production']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.factory), title: Text('${e['productName']} — ${e['qty']} قطعة'), subtitle: Text('تالف: ${e['waste']} | ${dateLabel(e['createdAt'])}\n${e['note'] ?? ''}'), isThreeLine: true))).toList())));
}

class SalesPage extends StatelessWidget {
  SalesPage({super.key}); final s = Store.instance;
  Future<void> _add(BuildContext context) async {
    if (s.data['products']!.isEmpty) { snack(context, 'أضف منتجًا أولًا قبل تسجيل البيع.'); return; }
    String? pid; final qty = TextEditingController(text: '1'); final paid = TextEditingController(text: '0'); final customer = TextEditingController(); final price = TextEditingController();
    final r = await showDialog<Map<String,dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('فاتورة بيع جديدة'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: pid, decoration: const InputDecoration(labelText: 'المنتج'), items: s.data['products']!.map((p) => DropdownMenuItem(value: '${p['id']}', child: Text('${p['name']} (متوفر ${p['stock']})'))).toList(), onChanged: (v) { setD(() { pid = v; final p = s.data['products']!.firstWhere((e) => e['id'] == v); price.text = '${p['price']}'; }); }), const SizedBox(height: 10), field(qty, 'الكمية المباعة', numeric: true), const SizedBox(height: 10), field(price, 'سعر القطعة', numeric: true), const SizedBox(height: 10), field(paid, 'المبلغ المدفوع', numeric: true), const SizedBox(height: 10), field(customer, 'اسم العميل (اختياري)')])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(pid == null || number(qty.text) <= 0 || number(price.text) < 0 || number(paid.text) < 0) return; Navigator.pop(ctx, {'pid':pid,'qty':number(qty.text),'price':number(price.text),'paid':number(paid.text),'customer':customer.text.trim()}); }, child: const Text('حفظ الفاتورة'))])));
    if (r == null) return;
    final p = s.data['products']!.firstWhere((e) => e['id'] == r['pid']); final q = (r['qty'] as num).toDouble(); final available = (p['stock'] as num).toDouble();
    if (q > available) { if(context.mounted) snack(context, 'الكمية غير كافية في المخزون. المتوفر: ${available.toStringAsFixed(0)}'); return; }
    final total = q * (r['price'] as num).toDouble(); final paidValue = (r['paid'] as num).toDouble();
    if (paidValue > total) { if(context.mounted) snack(context, 'المبلغ المدفوع أكبر من قيمة الفاتورة.'); return; }
    p['stock'] = available - q; await s.update('products', p);
    await s.add('sales', {'productId':p['id'],'productName':p['name'],'qty':q,'price':r['price'],'total':total,'paid':paidValue,'customer':r['customer']});
    if(context.mounted) snack(context, 'تم حفظ الفاتورة وتحديث المخزون.');
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('فاتورة بيع')), body: s.data['sales']!.isEmpty ? const EmptyState(icon: Icons.point_of_sale, text: 'لا توجد فواتير. أضف منتجًا ومخزونًا ثم سجّل أول عملية بيع.') : ListView(padding: const EdgeInsets.all(8), children: s.data['sales']!.map((e) { final due = ((e['total'] as num).toDouble() - (e['paid'] as num).toDouble()); return Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text('${e['productName']} × ${e['qty']}'), subtitle: Text('العميل: ${((e['customer'] ?? '').toString().isEmpty) ? 'نقدي / غير محدد' : e['customer']}\nالإجمالي: ${money((e['total'] as num).toDouble())} | مدفوع: ${money((e['paid'] as num).toDouble())}\nالمتبقي: ${money(due)} — ${dateLabel(e['createdAt'])}'), isThreeLine: true)); }).toList())));
}

class ExpensesPage extends StatelessWidget {
  ExpensesPage({super.key}); final s = Store.instance;
  Future<void> _add(BuildContext context) async {
    final title = TextEditingController(); final amount = TextEditingController(); final note = TextEditingController();
    final r = await showDialog<Map<String,String>>(context: context, builder: (ctx) => AlertDialog(title: const Text('تسجيل مصروف'), content: Column(mainAxisSize: MainAxisSize.min, children: [field(title, 'نوع المصروف *'), const SizedBox(height: 10), field(amount, 'المبلغ بالريال *', numeric: true), const SizedBox(height: 10), field(note, 'ملاحظات')]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(title.text.trim().isEmpty || number(amount.text) <= 0) return; Navigator.pop(ctx, {'title':title.text.trim(),'amount':amount.text,'note':note.text}); }, child: const Text('حفظ'))]));
    if(r != null) await s.add('expenses', {'title':r['title'],'amount':number(r['amount']),'note':r['note']});
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('تسجيل مصروف')), body: s.data['expenses']!.isEmpty ? const EmptyState(icon: Icons.payments, text: 'سجّل الإيجار والرواتب والوقود والكهرباء وغيرها من المصروفات الفعلية.') : ListView(children: s.data['expenses']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.money_off), title: Text('${e['title']}'), subtitle: Text('${money((e['amount'] as num).toDouble())} — ${dateLabel(e['createdAt'])}\n${e['note'] ?? ''}'), isThreeLine: true, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => confirmDelete(context, () => s.remove('expenses', '${e['id']}')))))).toList())));
}

class PurchasesPage extends StatelessWidget {
  PurchasesPage({super.key}); final s = Store.instance;
  Future<void> _add(BuildContext context) async {
    final title = TextEditingController(); final qty = TextEditingController(text:'1'); final amount = TextEditingController(); final supplier = TextEditingController();
    final r = await showDialog<Map<String,String>>(context: context, builder: (ctx) => AlertDialog(title: const Text('تسجيل مشتريات / مواد خام'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [field(title, 'الصنف أو المادة *'), const SizedBox(height: 10), field(qty, 'الكمية', numeric: true), const SizedBox(height: 10), field(amount, 'إجمالي التكلفة بالريال *', numeric: true), const SizedBox(height: 10), field(supplier, 'اسم المورد')])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(title.text.trim().isEmpty || number(amount.text) <= 0 || number(qty.text) <= 0) return; Navigator.pop(ctx, {'title':title.text.trim(),'qty':qty.text,'amount':amount.text,'supplier':supplier.text.trim()}); }, child: const Text('حفظ'))]));
    if(r != null) await s.add('purchases', {'title':r['title'],'qty':number(r['qty']),'total':number(r['amount']),'supplier':r['supplier']});
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('إضافة مشتريات')), body: ListView(padding: const EdgeInsets.all(8), children: [Card(child: ListTile(title: const Text('الموردون'), subtitle: Text('${s.data['suppliers']!.length} مورد مسجل'), trailing: IconButton(icon: const Icon(Icons.person_add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StandaloneSuppliersPage()))))), if(s.data['purchases']!.isEmpty) const EmptyState(icon: Icons.local_shipping, text: 'سجّل مشتريات الإسمنت والرمل والبحص وقطع الغيار. لا تُضاف تلقائيًا لمخزون منتج البلك.'), ...s.data['purchases']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.shopping_cart), title: Text('${e['title']} — ${e['qty']}'), subtitle: Text('المورد: ${e['supplier']}\nالتكلفة: ${money((e['total'] as num).toDouble())} — ${dateLabel(e['createdAt'])}'), isThreeLine: true)))])));
}

class StandaloneSuppliersPage extends StatelessWidget {
  const StandaloneSuppliersPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('إدارة الموردين')), body: GenericRecordsPage(title:'الموردون', storeKey:'suppliers', fields: const [('اسم المورد','name'),('رقم الهاتف','phone'),('ملاحظات','note')], icon: Icons.local_shipping));
}

class GenericRecordsPage extends StatelessWidget {
  final String title, storeKey; final List<(String,String)> fields; final IconData icon;
  const GenericRecordsPage({super.key, required this.title, required this.storeKey, required this.fields, required this.icon});
  Future<void> _add(BuildContext context) async {
    final controllers = fields.map((e) => TextEditingController()).toList();
    final r = await showDialog<Map<String,String>>(context: context, builder: (ctx) => AlertDialog(title: Text('إضافة $title'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [for (var i=0;i<fields.length;i++) ...[field(controllers[i], fields[i].$1), const SizedBox(height: 10)]])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), FilledButton(onPressed: () { if(controllers.first.text.trim().isEmpty) return; Navigator.pop(ctx, {for(var i=0;i<fields.length;i++) fields[i].$2:controllers[i].text.trim()}); }, child: const Text('حفظ'))]));
    if(r != null) await Store.instance.add(storeKey, r);
  }
  @override Widget build(BuildContext context) { final s = Store.instance; return AnimatedBuilder(animation:s, builder: (_, __) => Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: Text('إضافة ${title == 'العملاء' ? 'عميل' : 'مورد'}')), body: s.data[storeKey]!.isEmpty ? EmptyState(icon: icon, text: 'لا توجد سجلات. أضف أول سجل من الزر أدناه.') : ListView(children: s.data[storeKey]!.map((e) => Card(child: ListTile(leading: Icon(icon), title: Text('${e[fields.first.$2] ?? ''}'), subtitle: Text(fields.skip(1).map((f) => '${f.$1}: ${e[f.$2] ?? ''}').join('\n')), isThreeLine: fields.length > 2, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => confirmDelete(context, () => s.remove(storeKey, '${e['id']}')))))).toList()))); }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override Widget build(BuildContext context) { final s=Store.instance; return AnimatedBuilder(animation:s, builder: (_, __) => ListView(padding: const EdgeInsets.all(14), children: [const Text('التقارير الأولية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const SizedBox(height: 10), reportLine('إجمالي المبيعات المسجلة', money(s.totalSales)), reportLine('إجمالي المصروفات والمشتريات', money(s.totalExpenses)), reportLine('الفرق قبل تكلفة الإنتاج والالتزامات الأخرى', money(s.totalSales-s.totalExpenses)), reportLine('المبالغ المتبقية من فواتير البيع', money(s.receivables)), reportLine('عدد فواتير البيع', '${s.data['sales']!.length}'), reportLine('سجلات الإنتاج', '${s.data['production']!.length}'), const SizedBox(height: 12), const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('تنبيه محاسبي: الفرق المعروض ليس صافي ربح محاسبيًا؛ إذ يلزم إدخال تكلفة المواد والأجور والمخزون الافتتاحي والإهلاك والالتزامات لحساب الربح بدقة.')))])); }
}
Widget reportLine(String a, String b) => Card(child: ListTile(title: Text(a), trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.bold))));

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: const [Card(child: ListTile(leading: Icon(Icons.factory), title: Text('اسم المصنع'), subtitle: Text('مصنع الرياض للبلك الأوتوماتيكي'))), Card(child: ListTile(leading: Icon(Icons.location_on), title: Text('العنوان'), subtitle: Text('صنعاء، المطار، خط العروق'))), Card(child: ListTile(leading: Icon(Icons.phone), title: Text('رقم التواصل'), subtitle: Text('773766177'))), Card(child: ListTile(leading: Icon(Icons.currency_exchange), title: Text('العملة'), subtitle: Text('الريال اليمني'))), Card(child: ListTile(leading: Icon(Icons.storage), title: Text('التخزين'), subtitle: Text('حفظ محلي على هذا الجهاز باستخدام SharedPreferences. لا يوجد تزامن سحابي حتى الآن.'))), Card(child: Padding(padding: EdgeInsets.all(14), child: Text('مهم: احفظ نسخة من المشروع واحتفظ بالجهاز آمنًا. لا تستخدم هذه النسخة وحدها لإغلاق حسابات قانونية نهائية قبل مراجعة التقارير والتسويات.')))]);
}

class EmptyState extends StatelessWidget { final IconData icon; final String text; const EmptyState({super.key, required this.icon, required this.text}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: Colors.blueGrey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center), const SizedBox(height: 70)]))); }
Widget field(TextEditingController c, String label, {bool numeric=false}) => TextField(controller:c, keyboardType:numeric ? const TextInputType.numberWithOptions(decimal:true) : TextInputType.text, decoration:InputDecoration(labelText:label));
double number(String? s) => double.tryParse((s ?? '').trim()) ?? -1;
String dateLabel(dynamic value) { final d=DateTime.tryParse('$value'); if(d==null) return ''; return '${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; }
void snack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
Future<void> confirmDelete(BuildContext context, Future<void> Function() action) async { final ok=await showDialog<bool>(context:context, builder:(ctx)=>AlertDialog(title:const Text('تأكيد الحذف'),content:const Text('هل تريد حذف هذا السجل؟'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('حذف'))])); if(ok==true) await action(); }
