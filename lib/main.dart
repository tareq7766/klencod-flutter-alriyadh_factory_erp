import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color navy = Color(0xFF142B4A);
const Color blue = Color(0xFF2463A6);
const Color gold = Color(0xFFD5A742);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(RiyadhFactoryApp(prefs: prefs));
}

class RiyadhFactoryApp extends StatelessWidget {
  final SharedPreferences prefs;

  const RiyadhFactoryApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام محاسبة مصنع الرياض',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: FactoryHome(prefs: prefs),
    );
  }
}

class FactoryProduct {
  final String id;
  final String name;
  final String size;
  final double price;
  final int stock;

  const FactoryProduct({
    required this.id,
    required this.name,
    required this.size,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'price': price,
        'stock': stock,
      };

  factory FactoryProduct.fromJson(Map<String, dynamic> json) {
    return FactoryProduct(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class FactoryHome extends StatefulWidget {
  final SharedPreferences prefs;

  const FactoryHome({super.key, required this.prefs});

  @override
  State<FactoryHome> createState() => _FactoryHomeState();
}

class _FactoryHomeState extends State<FactoryHome> {
  int selectedIndex = 0;

  late List<FactoryProduct> products;
  late String factoryName;
  late String address;
  late String phone;

  String currencyCode = 'YER';
  bool ready = false;

  final Map<String, String> currencies = const {
    'YER': 'ريال يمني',
    'SAR': 'ريال سعودي',
    'USD': 'دولار أمريكي',
  };

  String get currencyName =>
      currencies[currencyCode] ?? 'ريال يمني';

  final List<String> titles = const [
    'لوحة التحكم',
    'المنتجات',
    'الإنتاج',
    'المبيعات',
    'المخزون',
    'العملاء',
    'الموردون',
    'المصروفات',
    'الحسابات',
    'التقارير',
    'الإعدادات',
  ];

  final List<IconData> icons = const [
    Icons.dashboard_outlined,
    Icons.view_module_outlined,
    Icons.precision_manufacturing_outlined,
    Icons.point_of_sale_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
    Icons.local_shipping_outlined,
    Icons.payments_outlined,
    Icons.account_balance_outlined,
    Icons.assessment_outlined,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();

    products = _loadProducts();

    factoryName = widget.prefs.getString('factory_name') ??
        'مصنع الرياض للبلك الأوتوماتيكي';

    address = widget.prefs.getString('factory_address') ??
        'صنعاء، المطار، خط العروق';

    phone = widget.prefs.getString('factory_phone') ?? '773766177';

    final savedCurrency =
        widget.prefs.getString('factory_currency') ?? 'YER';

    currencyCode =
        currencies.containsKey(savedCurrency) ? savedCurrency : 'YER';

    ready = true;
  }

  List<FactoryProduct> _loadProducts() {
    final raw = widget.prefs.getString('factory_products');

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => FactoryProduct.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveProducts() async {
    await widget.prefs.setString(
      'factory_products',
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeCurrency(String? value) async {
    if (value == null || !currencies.containsKey(value)) {
      return;
    }

    final saved = await widget.prefs.setString(
      'factory_currency',
      value,
    );

    if (!mounted) {
      return;
    }

    if (!saved) {
      _message('تعذر حفظ العملة. حاول مرة أخرى.');
      return;
    }

    setState(() {
      currencyCode = value;
    });

    _message('تم تغيير العملة إلى ${currencies[value]}');
  }

  Future<void> _editProduct([FactoryProduct? existing]) async {
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: existing?.name ?? '');

    final sizeController =
        TextEditingController(text: existing?.size ?? '');

    final priceController = TextEditingController(
      text: existing == null ? '' : _number(existing.price),
    );

    final stockController = TextEditingController(
      text: existing == null ? '0' : existing.stock.toString(),
    );

    final result = await showDialog<FactoryProduct>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          existing == null ? 'إضافة منتج' : 'تعديل المنتج',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج *',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'أدخل اسم المنتج'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: sizeController,
                  decoration: const InputDecoration(
                    labelText: 'المقاس / النوع',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'سعر الوحدة ($currencyName) *',
                  ),
                  validator: (value) {
                    final price = _parseDouble(value);

                    if (price == null ||
                        !price.isFinite ||
                        price < 0) {
                      return 'أدخل سعراً صحيحاً';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية المتوفرة *',
                  ),
                  validator: (value) {
                    final stock = _parseInt(value);

                    if (stock == null || stock < 0) {
                      return 'أدخل كمية صحيحة';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'العملة الحالية: $currencyName',
                  style: const TextStyle(color: blue),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              Navigator.pop(
                dialogContext,
                FactoryProduct(
                  id: existing?.id ??
                      DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                  name: nameController.text.trim(),
                  size: sizeController.text.trim(),
                  price: _parseDouble(priceController.text)!,
                  stock: _parseInt(stockController.text)!,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    nameController.dispose();
    sizeController.dispose();
    priceController.dispose();
    stockController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      final index = products.indexWhere(
        (product) => product.id == result.id,
      );

      if (index < 0) {
        products.add(result);
      } else {
        products[index] = result;
      }
    });

    await _saveProducts();

    if (mounted) {
      _message(
        existing == null ? 'تم حفظ المنتج' : 'تم تحديث المنتج',
      );
    }
  }

  Future<void> _deleteProduct(FactoryProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المنتج «${product.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      products.removeWhere((p) => p.id == product.id);
    });

    await _saveProducts();

    if (mounted) {
      _message('تم حذف المنتج');
    }
  }

  Future<void> _editSettings() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: factoryName);
    final addressController = TextEditingController(text: address);
    final phoneController = TextEditingController(text: phone);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بيانات المصنع'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المصنع',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'أدخل اسم المصنع'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم التواصل',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final newName = nameController.text.trim();
      final newAddress = addressController.text.trim();
      final newPhone = phoneController.text.trim();

      final nameSaved =
          await widget.prefs.setString('factory_name', newName);

      final addressSaved = await widget.prefs.setString(
        'factory_address',
        newAddress,
      );

      final phoneSaved =
          await widget.prefs.setString('factory_phone', newPhone);

      if (mounted) {
        if (nameSaved && addressSaved && phoneSaved) {
          setState(() {
            factoryName = newName;
            address = newAddress;
            phone = newPhone;
          });

          _message('تم حفظ بيانات المصنع');
        } else {
          _message('تعذر حفظ بعض البيانات. تحقق وحاول مجدداً.');
        }
      }
    }

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedIndex = 10;
              });
            },
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                color: navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: gold,
                      child: Icon(
                        Icons.factory,
                        size: 34,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      factoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'نظام الإدارة والمحاسبة',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: titles.length,
                  itemBuilder: (ctx, index) => ListTile(
                    leading: Icon(icons[index]),
                    title: Text(titles[index]),
                    selected: selectedIndex == index,
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });

                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _dashboard(),
          _productsPage(),
          _placeholder(
            'الإنتاج اليومي',
            'تسجيل الإنتاج واستهلاك المواد والتكلفة غير مفعّل بعد.',
            Icons.precision_manufacturing,
          ),
          _placeholder(
            'المبيعات والفواتير',
            'تسجيل فواتير البيع والتحصيل والمرتجعات غير مفعّل بعد.',
            Icons.point_of_sale,
          ),
          _placeholder(
            'المخزون',
            'إدارة البلك الجاهز والمواد الخام وحركات المخزون غير مفعّلة بعد.',
            Icons.inventory_2,
          ),
          _placeholder(
            'العملاء والديون',
            'سجل العملاء والأرصدة وسندات القبض غير مفعّل بعد.',
            Icons.people,
          ),
          _placeholder(
            'الموردون والمشتريات',
            'سجل الموردين والمشتريات والمدفوعات غير مفعّل بعد.',
            Icons.local_shipping,
          ),
          _placeholder(
            'المصروفات والإيرادات',
            'تسجيل المصروفات والإيرادات الفعلية غير مفعّل بعد.',
            Icons.payments,
          ),
          _placeholder(
            'الحسابات العامة',
            'الصندوق والقيود المحاسبية والأستاذ غير مفعّلة بعد.',
            Icons.account_balance,
          ),
          _placeholder(
            'التقارير',
            'ستعرض التقارير أرقاماً ناتجة عن العمليات المسجلة فعلياً.',
            Icons.assessment,
          ),
          _settingsPage(),
        ],
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _editProduct(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج'),
            )
          : null,
    );
  }

  Widget _dashboard() {
    final totalStock = products.fold<int>(
      0,
      (sum, product) => sum + product.stock,
    );

    final stockValue = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.stock,
    );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [navy, blue],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.factory,
                size: 40,
                color: gold,
              ),
              const SizedBox(height: 12),
              Text(
                factoryName,
                style: const TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                address,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                'هاتف التواصل: $phone',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                'العملة الأساسية: $currencyName',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ملخص البيانات المسجلة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metric(
              'عدد المنتجات',
              products.length.toString(),
              Icons.view_module,
            ),
            _metric(
              'إجمالي الكميات المسجلة',
              totalStock.toString(),
              Icons.inventory_2,
            ),
            _metric(
              'قيمة المخزون التقديرية',
              '${_number(stockValue)} $currencyCode',
              Icons.account_balance_wallet,
            ),
            _metric(
              'المبيعات المسجلة',
              'غير مسجلة',
              Icons.point_of_sale,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'العملة المختارة: $currencyName.\n'
              'يتم حفظ المنتجات وبيانات المصنع والعملة على هذا الجهاز. '
              'قيمة المخزون تقديرية، محسوبة من السعر والكمية المسجلين '
              'للمنتجات، وليست تقريراً محاسبياً معتمداً.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            setState(() {
              selectedIndex = 1;
            });
          },
          icon: const Icon(Icons.view_module),
          label: const Text('إدارة المنتجات'),
        ),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      height: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: blue, size: 25),
              Text(title, style: const TextStyle(fontSize: 13)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productsPage() {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: blue,
              ),
              const SizedBox(height: 12),
              const Text(
                'لا توجد منتجات حتى الآن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اضغط «إضافة منتج» لتسجيل نوع البلك ومقاسه وسعره وكميته.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _editProduct(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة أول منتج'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'المنتجات المسجلة: ${products.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...products.map(
          (product) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5EDF7),
                child: Icon(
                  Icons.view_module,
                  color: navy,
                ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'المقاس: ${product.size.isEmpty ? 'غير محدد' : product.size}\n'
                'السعر: ${_number(product.price)} $currencyName\n'
                'الكمية: ${product.stock}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProduct(product);
                  }

                  if (value == 'delete') {
                    _deleteProduct(product);
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('تعديل'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.factory, color: blue),
            title: const Text('اسم المصنع'),
            subtitle: Text(factoryName),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: blue),
            title: const Text('العنوان'),
            subtitle: Text(
              address.isEmpty ? 'غير محدد' : address,
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone, color: blue),
            title: const Text('رقم التواصل'),
            subtitle: Text(
              phone.isEmpty ? 'غير محدد' : phone,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: currencyCode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'العملة الأساسية',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              items: currencies.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: _changeCurrency,
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage, color: blue),
            title: const Text('التخزين'),
            subtitle: const Text(
              'حفظ محلي على هذا الجهاز',
            ),
          ),
        ),
        Card(
          color: const Color(0xFFFFF4D9),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'تنبيه: تغيير العملة يغيّر العملة المعروضة فقط، '
              'ولا يحوّل الأسعار القديمة إلى سعر صرف جديد. '
              'لا تستخدم هذه النسخة وحدها لإعداد حسابات مالية نهائية.',
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _editSettings,
          icon: const Icon(Icons.edit),
          label: const Text('تعديل بيانات المصنع'),
        ),
      ],
    );
  }

  Widget _placeholder(
    String title,
    String description,
    IconData icon,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 60, color: blue),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                const Text(
                  'هذا القسم لم يُفعّل محاسبياً بعد. '
                  'لا تسجل فيه عمليات فعلية حتى اكتمال تنفيذه.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double? _parseDouble(String? value) {
  if (value == null) return null;

  return double.tryParse(
    value.trim().replaceAll(',', '.'),
  );
}

int? _parseInt(String? value) {
  if (value == null) return null;

  return int.tryParse(value.trim());
}

String _number(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
