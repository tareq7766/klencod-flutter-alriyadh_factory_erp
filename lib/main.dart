import 'package:flutter/material.dart';

void main() {
  runApp(const RiyadhFactoryApp());
}

class RiyadhFactoryApp extends StatelessWidget {
  const RiyadhFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142B4A);
    const blue = Color(0xFF2463A6);
    const gold = Color(0xFFD5A742);

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
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const FactoryHome(),
    );
  }
}

class FactoryHome extends StatefulWidget {
  const FactoryHome({super.key});

  @override
  State<FactoryHome> createState() => _FactoryHomeState();
}

class _FactoryHomeState extends State<FactoryHome> {
  int selectedIndex = 0;

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
  Widget build(BuildContext context) {
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
                color: const Color(0xFF142B4A),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFD5A742),
                      child: Icon(
                        Icons.factory,
                        size: 34,
                        color: Color(0xFF142B4A),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'مصنع الرياض للبلك الأوتوماتيكي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'نظام الإدارة والمحاسبة',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(icons[index]),
                      title: Text(titles[index]),
                      selected: selectedIndex == index,
                      onTap: () {
                        setState(() => selectedIndex = index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          const DashboardPage(),
          const ModulePage(
            title: 'إدارة المنتجات',
            description: 'إضافة أنواع البلك والمقاسات والرموز والأسعار.',
            icon: Icons.view_module,
          ),
          const ModulePage(
            title: 'الإنتاج اليومي',
            description: 'تسجيل الإنتاج السليم والتالف واستهلاك المواد وتكلفة الإنتاج.',
            icon: Icons.precision_manufacturing,
          ),
          const ModulePage(
            title: 'المبيعات والفواتير',
            description: 'فواتير البيع النقدي والآجل والجزئي والمرتجعات.',
            icon: Icons.point_of_sale,
          ),
          const ModulePage(
            title: 'المخزون',
            description: 'إدارة البلك الجاهز والإسمنت والرمل والبحص وحركات المخزون.',
            icon: Icons.inventory_2,
          ),
          const ModulePage(
            title: 'العملاء والديون',
            description: 'حسابات العملاء والأرصدة والفواتير وسندات القبض.',
            icon: Icons.people,
          ),
          const ModulePage(
            title: 'الموردون والمشتريات',
            description: 'تسجيل مشتريات المواد الخام وأرصدة الموردين والمدفوعات.',
            icon: Icons.local_shipping,
          ),
          const ModulePage(
            title: 'المصروفات والإيرادات',
            description: 'تسجيل المصروفات التشغيلية والإيرادات الفعلية.',
            icon: Icons.payments,
          ),
          const ModulePage(
            title: 'الحسابات العامة',
            description: 'الصندوق والقيود المحاسبية والأستاذ والميزانية.',
            icon: Icons.account_balance,
          ),
          const ModulePage(
            title: 'التقارير',
            description: 'تقارير المبيعات والأرباح والمخزون والإنتاج والديون.',
            icon: Icons.assessment,
          ),
          const SettingsPage(),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF142B4A),
                Color(0xFF2463A6),
              ],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.factory,
                size: 40,
                color: Color(0xFFD5A742),
              ),
              SizedBox(height: 12),
              Text(
                'مصنع الرياض للبلك الأوتوماتيكي',
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'صنعاء، المطار، خط العروق',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 6),
              Text(
                'هاتف التواصل: 773766177',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'المؤشرات المالية',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Wrap(
          children: [
            MetricCard(
              title: 'مبيعات اليوم',
              value: '—',
              icon: Icons.point_of_sale,
            ),
            MetricCard(
              title: 'المقبوضات',
              value: '—',
              icon: Icons.account_balance_wallet,
            ),
            MetricCard(
              title: 'المصروفات',
              value: '—',
              icon: Icons.payments,
            ),
            MetricCard(
              title: 'ديون العملاء',
              value: '—',
              icon: Icons.people,
            ),
            MetricCard(
              title: 'الإنتاج اليومي',
              value: '—',
              icon: Icons.factory,
            ),
            MetricCard(
              title: 'المخزون',
              value: '—',
              icon: Icons.inventory_2,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'تنبيه: هذه واجهة التأسيس. ستظهر الأرقام بعد ربط قاعدة البيانات '
              'وتسجيل العمليات الفعلية، ولن نعرض بيانات وهمية على أنها حسابات حقيقية.',
            ),
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: const Color(0xFF2463A6), size: 25),
              Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModulePage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ModulePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 60,
                  color: const Color(0xFF2463A6),
                ),
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
                  'سيتم تنفيذ وظائف هذه الصفحة وربطها بقاعدة البيانات في المراحل التالية.',
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.factory),
            title: Text('اسم المصنع'),
            subtitle: Text('مصنع الرياض للبلك الأوتوماتيكي'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.location_on),
            title: Text('العنوان'),
            subtitle: Text('صنعاء، المطار، خط العروق'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text('رقم التواصل'),
            subtitle: Text('773766177'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.currency_exchange),
            title: Text('العملة الأساسية'),
            subtitle: Text('الريال اليمني'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.storage),
            title: Text('قاعدة البيانات'),
            subtitle: Text(
              'سيتم إعداد التخزين المحلي الدائم في المرحلة التالية.',
            ),
          ),
        ),
      ],
    );
  }
}