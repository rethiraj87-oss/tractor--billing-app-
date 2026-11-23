import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() => runApp(const TractorApp());

class Job {
  final String id, customer, phone, place, work, note;
  final double quantity, rate, total, paid;
  final DateTime date;
  Job({required this.id, required this.customer, required this.phone,
    required this.place, required this.work, required this.note,
    required this.quantity, required this.rate, required this.total,
    required this.paid, required this.date});
  double get balance => total - paid;
  Map<String,dynamic> toJson() => {
    'id':id,'customer':customer,'phone':phone,'place':place,'work':work,
    'note':note,'quantity':quantity,'rate':rate,'total':total,'paid':paid,
    'date':date.toIso8601String()
  };
  factory Job.fromJson(Map<String,dynamic> j) => Job(
    id:j['id'], customer:j['customer'], phone:j['phone']??'',
    place:j['place']??'', work:j['work'], note:j['note']??'',
    quantity:(j['quantity'] as num).toDouble(),
    rate:(j['rate'] as num).toDouble(), total:(j['total'] as num).toDouble(),
    paid:(j['paid'] as num).toDouble(), date:DateTime.parse(j['date']));
}

class Cost {
  final String id, category, note;
  final double amount;
  final DateTime date;
  Cost({required this.id,required this.category,required this.note,
    required this.amount,required this.date});
  Map<String,dynamic> toJson()=>{'id':id,'category':category,'note':note,
    'amount':amount,'date':date.toIso8601String()};
  factory Cost.fromJson(Map<String,dynamic> j)=>Cost(
    id:j['id'],category:j['category'],note:j['note']??'',
    amount:(j['amount'] as num).toDouble(),date:DateTime.parse(j['date']));
}


class LandMeasure {
  final String id, owner, phone, village, survey, unit, note;
  final double quantity, rate, paid;
  final DateTime date;
  LandMeasure({required this.id,required this.owner,required this.phone,required this.village,required this.survey,required this.unit,required this.quantity,required this.rate,required this.paid,required this.note,required this.date});
  double get total=>quantity*rate;
  double get balance=>total-paid;
  Map<String,dynamic> toJson()=>{'id':id,'owner':owner,'phone':phone,'village':village,'survey':survey,'unit':unit,'quantity':quantity,'rate':rate,'paid':paid,'note':note,'date':date.toIso8601String()};
  factory LandMeasure.fromJson(Map<String,dynamic> j)=>LandMeasure(id:j['id'],owner:j['owner'],phone:j['phone']??'',village:j['village']??'',survey:j['survey']??'',unit:j['unit']??'ஏக்கர்',quantity:(j['quantity'] as num).toDouble(),rate:(j['rate'] as num).toDouble(),paid:(j['paid'] as num).toDouble(),note:j['note']??'',date:DateTime.parse(j['date']));
}

class PersonalEntry {
  final String id, person, type, note;
  final double amount, monthlyRate;
  final DateTime date;
  PersonalEntry({required this.id,required this.person,required this.type,required this.amount,required this.monthlyRate,required this.date,required this.note});
  bool get isLoan=>type=='கடன் கொடுத்தது'||type=='கடன் வாங்கியது';
  double interestAsOf(DateTime now){if(!isLoan||monthlyRate<=0)return 0;final days=now.difference(date).inDays.clamp(0,1000000).toDouble();return amount*monthlyRate/100*days/30;}
  Map<String,dynamic> toJson()=>{'id':id,'person':person,'type':type,'amount':amount,'monthlyRate':monthlyRate,'date':date.toIso8601String(),'note':note};
  factory PersonalEntry.fromJson(Map<String,dynamic> j)=>PersonalEntry(id:j['id'],person:j['person'],type:j['type'],amount:(j['amount'] as num).toDouble(),monthlyRate:(j['monthlyRate'] as num? ?? 0).toDouble(),date:DateTime.parse(j['date']),note:j['note']??'');
}

class TractorApp extends StatelessWidget {
  const TractorApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false, title:'டிராக்டர் வாடகை கணக்கு',
    theme:ThemeData(colorSchemeSeed:Colors.teal,useMaterial3:true),
    home:const TractorHome());
}

class TractorHome extends StatefulWidget {
  const TractorHome({super.key});
  @override State<TractorHome> createState()=>_TractorHomeState();
}

class _TractorHomeState extends State<TractorHome> with SingleTickerProviderStateMixin {
  final jobs=<Job>[];
  final costs=<Cost>[];
  final measures=<LandMeasure>[];
  final personal=<PersonalEntry>[];
  late final TabController tabs=TabController(length:6,vsync:this);
  final fmt=NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:2);
  final dayFmt=DateFormat('dd-MM-yyyy');
  String period='மொத்தம்';
  bool loading=true;
  final costTypes=['டீசல்','டிரைவர் கூலி','பழுதுபார்ப்பு','சர்வீஸ்','டயர் / உதிரிபாகம்','கடன் தவணை','காப்பீடு','மற்றவை'];

  @override void initState(){
    super.initState();
    tabs.addListener(() { if (mounted) setState(() {}); });
    load();
  }
  @override void dispose(){tabs.dispose();super.dispose();}

  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final a=(jsonDecode(p.getString('jobs')??'[]') as List)
      .map((x)=>Job.fromJson(Map<String,dynamic>.from(x))).toList();
    final b=(jsonDecode(p.getString('costs')??'[]') as List)
      .map((x)=>Cost.fromJson(Map<String,dynamic>.from(x))).toList();
    final m=(jsonDecode(p.getString('measures')??'[]') as List).map((x)=>LandMeasure.fromJson(Map<String,dynamic>.from(x))).toList();
    final pe=(jsonDecode(p.getString('personal')??'[]') as List).map((x)=>PersonalEntry.fromJson(Map<String,dynamic>.from(x))).toList();
    if(!mounted)return;
    setState((){jobs..clear()..addAll(a);costs..clear()..addAll(b);measures..clear()..addAll(m);personal..clear()..addAll(pe);loading=false;});
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('jobs',jsonEncode(jobs.map((x)=>x.toJson()).toList()));
    await p.setString('costs',jsonEncode(costs.map((x)=>x.toJson()).toList()));
    await p.setString('measures',jsonEncode(measures.map((x)=>x.toJson()).toList()));
    await p.setString('personal',jsonEncode(personal.map((x)=>x.toJson()).toList()));
  }
  bool inPeriod(DateTime d){
    final n=DateTime.now();
    if(period=='இன்று')return d.year==n.year&&d.month==n.month&&d.day==n.day;
    if(period=='இந்த மாதம்')return d.year==n.year&&d.month==n.month;
    if(period=='இந்த ஆண்டு')return d.year==n.year;
    return true;
  }
  List<Job> get fj=>jobs.where((x)=>inPeriod(x.date)).toList();
  List<Cost> get fc=>costs.where((x)=>inPeriod(x.date)).toList();
  double get income=>fj.fold(0,(s,x)=>s+x.total);
  double get received=>fj.fold(0,(s,x)=>s+x.paid);
  double get pending=>fj.fold(0,(s,x)=>s+x.balance);
  double get expense=>fc.fold(0,(s,x)=>s+x.amount);
  double get profit=>income-expense;

  Future<void> addJob({Job? old}) async {
    final v=await showDialog<Job>(context:context,builder:(_)=>JobDialog(old:old));
    if(v==null)return;
    setState((){if(old!=null)jobs.removeWhere((x)=>x.id==old.id);jobs.add(v);});
    await save();
  }
  Future<void> addCost({Cost? old}) async {
    final v=await showDialog<Cost>(context:context,builder:(_)=>CostDialog(types:costTypes,old:old));
    if(v==null)return;
    setState((){if(old!=null)costs.removeWhere((x)=>x.id==old.id);costs.add(v);});
    await save();
  }
  Future<void> addMeasure({LandMeasure? old}) async {
    final v=await showDialog<LandMeasure>(context:context,builder:(_)=>MeasureDialog(old:old));
    if(v==null)return;setState((){if(old!=null)measures.removeWhere((x)=>x.id==old.id);measures.add(v);});await save();
  }
  Future<void> addPersonal({PersonalEntry? old}) async {
    final v=await showDialog<PersonalEntry>(context:context,builder:(_)=>PersonalDialog(old:old));
    if(v==null)return;setState((){if(old!=null)personal.removeWhere((x)=>x.id==old.id);personal.add(v);});await save();
  }
  Future<void> deleteMeasure(LandMeasure x) async {if(await confirmDelete()){setState(()=>measures.removeWhere((m)=>m.id==x.id));await save();}}
  Future<void> deletePersonal(PersonalEntry x) async {if(await confirmDelete()){setState(()=>personal.removeWhere((e)=>e.id==x.id));await save();}}
  Future<void> deleteJob(Job x) async {
    final ok=await confirmDelete();
    if(ok){setState(()=>jobs.removeWhere((j)=>j.id==x.id));await save();}
  }
  Future<void> deleteCost(Cost x) async {
    final ok=await confirmDelete();
    if(ok){setState(()=>costs.removeWhere((c)=>c.id==x.id));await save();}
  }
  Future<bool> confirmDelete() async => await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:const Text('நீக்க வேண்டுமா?'),content:const Text('இந்தப் பதிவை நீக்கவா?'),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('வேண்டாம்')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('நீக்கு'))]))??false;

  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(
      appBar:AppBar(title:const Text('டிராக்டர் வாடகை கணக்கு'),bottom:TabBar(isScrollable:true,controller:tabs,tabs:const[
        Tab(text:'முகப்பு',icon:Icon(Icons.dashboard)),
        Tab(text:'வாடகை வேலை',icon:Icon(Icons.agriculture)),
        Tab(text:'செலவுகள்',icon:Icon(Icons.receipt_long)),
        Tab(text:'வாடிக்கையாளர் பாக்கி',icon:Icon(Icons.people_alt)),
        Tab(text:'நில அளவீடு',icon:Icon(Icons.straighten)),
        Tab(text:'தனிநபர் கணக்கு',icon:Icon(Icons.account_balance_wallet)),
      ])),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,10,12,0),child:DropdownButtonFormField<String>(
          value:period,decoration:const InputDecoration(labelText:'கணக்கு காலம்',border:OutlineInputBorder()),
          items:['மொத்தம்','இன்று','இந்த மாதம்','இந்த ஆண்டு'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:(v)=>setState(()=>period=v!))),
        Expanded(child:TabBarView(controller:tabs,children:[
          dashboard(),jobList(),costList(),customerBalances(),measureList(),personalList()
        ]))
      ]),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:()=>tabs.index==2?addCost():tabs.index==3?null:tabs.index==4?addMeasure():tabs.index==5?addPersonal():addJob(),
        icon:const Icon(Icons.add),
        label:Text(tabs.index==2?'செலவு பதிவு':tabs.index==3?'பாக்கி விவரம்':tabs.index==4?'நில அளவீடு பதிவு':tabs.index==5?'தனிநபர் பதிவு':'வாடகை பதிவு')),
    );
  }

  Widget metric(String label,double value,Color color)=>Card(child:Padding(
    padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(label,style:const TextStyle(fontSize:12)),const SizedBox(height:5),
      FittedBox(child:Text(fmt.format(value),style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:color)))
    ])));

  Map<String, List<Job>> get customerGroups {
    final map = <String, List<Job>>{};
    for (final j in fj) {
      final key = j.customer.trim().isEmpty ? 'பெயர் இல்லை' : j.customer.trim();
      map.putIfAbsent(key, () => []).add(j);
    }
    return map;
  }

  Future<void> receiveCustomerPayment(String customerName, List<Job> customerJobs) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(context: context, builder: (_) => AlertDialog(
      title: Text('$customerName - பணம் பெறுதல்'),
      content: TextField(controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'பெற்ற தொகை ₹', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ரத்து')),
        FilledButton(onPressed: () {
          final v = double.tryParse(controller.text.trim());
          final due = customerJobs.fold<double>(0, (s, j) => s + j.balance);
          if (v == null || v <= 0 || v > due) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('சரியான தொகையை உள்ளிடவும். அதிகபட்ச பாக்கி ${fmt.format(due)}')));
            return;
          }
          Navigator.pop(context, v);
        }, child: const Text('பெற்றதைச் சேமி')),
      ],
    ));
    controller.dispose();
    if (amount == null) return;

    // Allocate the received amount to this customer's oldest unpaid jobs first.
    var remaining = amount;
    final ordered = [...customerJobs]..sort((a, b) => a.date.compareTo(b.date));
    setState(() {
      for (final oldJob in ordered) {
        if (remaining <= 0) break;
        final due = oldJob.balance;
        if (due <= 0) continue;
        final applied = remaining < due ? remaining : due;
        final index = jobs.indexWhere((x) => x.id == oldJob.id);
        if (index >= 0) {
          final j = jobs[index];
          jobs[index] = Job(id:j.id, customer:j.customer, phone:j.phone,
            place:j.place, work:j.work, note:j.note, quantity:j.quantity,
            rate:j.rate, total:j.total, paid:j.paid+applied, date:j.date);
        }
        remaining -= applied;
      }
    });
    await save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${fmt.format(amount)} பெறப்பட்டதாக பதிவு செய்யப்பட்டது')));
  }

  Widget customerBalances() {
    final groups = customerGroups;
    if (groups.isEmpty) return const Center(child: Text('வாடிக்கையாளர் பாக்கி எதுவும் இல்லை'));
    final rows = groups.entries.where((e) =>
      e.value.fold<double>(0, (s, j) => s + j.balance) > 0).toList()
      ..sort((a, b) => b.value.fold<double>(0, (s,j)=>s+j.balance)
        .compareTo(a.value.fold<double>(0, (s,j)=>s+j.balance)));
    if (rows.isEmpty) return const Center(child: Text('அனைத்து வாடிக்கையாளர்களும் பணம் செலுத்திவிட்டனர்'));
    return ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 90), children: [
      Card(child: ListTile(
        title: const Text('மொத்த வாடிக்கையாளர் பாக்கி'),
        trailing: Text(fmt.format(rows.fold<double>(0, (s,e) =>
          s + e.value.fold<double>(0, (a,j)=>a+j.balance))),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)))),
      ...rows.map((entry) {
        final list = entry.value;
        final due = list.fold<double>(0, (s,j)=>s+j.balance);
        final total = list.fold<double>(0, (s,j)=>s+j.total);
        final got = list.fold<double>(0, (s,j)=>s+j.paid);
        return Card(child: ExpansionTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('மொத்த வாடகை: ${fmt.format(total)}  |  பெற்றது: ${fmt.format(got)}'),
          trailing: Text(fmt.format(due), style: const TextStyle(color: Colors.deepOrange,
            fontWeight: FontWeight.bold)),
          children: [
            ...list.where((j)=>j.balance>0).map((j)=>ListTile(
              dense:true, title:Text('${j.work} • ${dayFmt.format(j.date)}'),
              subtitle:Text('இடம்: ${j.place.isEmpty ? '-' : j.place}'),
              trailing:Text('பாக்கி ${fmt.format(j.balance)}'))),
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: ()=>receiveCustomerPayment(entry.key, list),
                icon: const Icon(Icons.payments), label: const Text('இந்த வாடிக்கையாளரிடமிருந்து பணம் பெற'))))
          ],
        ));
      })
    ]);
  }

  Widget measureList()=>measures.isEmpty?const Center(child:Text('நில அளவீடு பதிவு இல்லை')):ListView.builder(padding:const EdgeInsets.only(bottom:90),itemCount:measures.length,itemBuilder:(_,i){final x=measures.reversed.toList()[i];return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:ListTile(leading:const CircleAvatar(child:Icon(Icons.straighten)),title:Text(x.owner,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${x.village} • சர்வே எண்: ${x.survey}\n${x.quantity} ${x.unit} × ${fmt.format(x.rate)} | மொத்தம் ${fmt.format(x.total)}\nபெற்றது ${fmt.format(x.paid)} | பாக்கி ${fmt.format(x.balance)}'),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')addMeasure(old:x);else deleteMeasure(x);},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('திருத்து')),PopupMenuItem(value:'del',child:Text('நீக்கு'))])));});

  Widget personalList(){if(personal.isEmpty)return const Center(child:Text('தனிநபர் கணக்கு பதிவு இல்லை'));final now=DateTime.now();return ListView(padding:const EdgeInsets.only(bottom:90),children:[Card(child:ListTile(title:const Text('தனிநபர் பதிவுகள்'),subtitle:Text('மொத்தம் ${personal.length} பதிவுகள்'))),...personal.reversed.map((x){final interest=x.interestAsOf(now);final due=x.isLoan?x.amount+interest:0.0;return Card(child:ListTile(leading:CircleAvatar(child:Icon(x.isLoan?Icons.account_balance:Icons.person)),title:Text('${x.person} • ${x.type}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${dayFmt.format(x.date)} | ${x.note}\n${x.isLoan?'அசல் ${fmt.format(x.amount)} + வட்டி ${fmt.format(interest)} = ${fmt.format(due)}':'தொகை ${fmt.format(x.amount)}'}${x.isLoan?' • மாத வட்டி ${x.monthlyRate}%':''}'),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')addPersonal(old:x);else deletePersonal(x);},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('திருத்து')),PopupMenuItem(value:'del',child:Text('நீக்கு'))])));})]);}

  Widget dashboard()=>ListView(padding:const EdgeInsets.fromLTRB(12,8,12,90),children:[
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,
      childAspectRatio:2.0,crossAxisSpacing:8,mainAxisSpacing:4,children:[
        metric('மொத்த வாடகை வரவு',income,Colors.green),
        metric('பெற்ற தொகை',received,Colors.teal),
        metric('பாக்கி தொகை',pending,Colors.orange),
        metric('மொத்த செலவு',expense,Colors.red),
      ]),
    Card(child:ListTile(title:const Text('செலவுக்குப் பின் மீதம் (மதிப்பீடு)'),
      subtitle:const Text('மொத்த வாடகை − பதிவு செய்த செலவுகள்'),
      trailing:Text(fmt.format(profit),style:TextStyle(fontWeight:FontWeight.bold,fontSize:18,
        color:profit>=0?Colors.green:Colors.red)))),
    Card(child:ListTile(title:const Text('மொத்த வேலைகள்'),trailing:Text('${fj.length}'))),
    Card(child:ListTile(title:const Text('செலவு பதிவுகள்'),trailing:Text('${fc.length}'))),
    const Padding(padding:EdgeInsets.all(8),child:Text('குறிப்பு: கடன் தவணை உட்பட நீங்கள் பதிவு செய்த செலவுகள் அனைத்தும் செலவாகக் கணக்கிடப்படும்.')),
  ]);

  Widget jobList()=>fj.isEmpty?const Center(child:Text('வாடகை வேலை பதிவு இல்லை')):ListView.builder(
    padding:const EdgeInsets.only(bottom:90),itemCount:fj.length,itemBuilder:(_,i){
      final x=fj.reversed.toList()[i];
      return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:ListTile(
        title:Text(x.customer.isEmpty?'பெயர் இல்லை':x.customer,style:const TextStyle(fontWeight:FontWeight.bold)),
        subtitle:Text('${x.work} • ${dayFmt.format(x.date)}\n${x.place} • அளவு: ${x.quantity} • விலை: ${fmt.format(x.rate)}\nபெற்றது: ${fmt.format(x.paid)} | பாக்கி: ${fmt.format(x.balance)}'),
        isThreeLine:true,
        trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')addJob(old:x);else deleteJob(x);},
          itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('திருத்து')),PopupMenuItem(value:'del',child:Text('நீக்கு'))]),
        leading:CircleAvatar(child:Text('${i+1}')),
        onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(
          title:Text(x.customer),content:Text('மொத்த வாடகை: ${fmt.format(x.total)}\nபெற்றது: ${fmt.format(x.paid)}\nபாக்கி: ${fmt.format(x.balance)}\nதொலைபேசி: ${x.phone}\nகுறிப்பு: ${x.note}'),
          actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('சரி'))])),
      ));
    });

  Widget costList()=>fc.isEmpty?const Center(child:Text('செலவு பதிவு இல்லை')):ListView.builder(
    padding:const EdgeInsets.only(bottom:90),itemCount:fc.length,itemBuilder:(_,i){
      final x=fc.reversed.toList()[i];
      return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.money_off)),
        title:Text(x.category),subtitle:Text('${dayFmt.format(x.date)}${x.note.isEmpty?'':'\n${x.note}'}'),
        isThreeLine:x.note.isNotEmpty,trailing:PopupMenuButton<String>(
          onSelected:(v){if(v=='edit')addCost(old:x);else deleteCost(x);},
          itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('திருத்து')),PopupMenuItem(value:'del',child:Text('நீக்கு'))]),
      ));
    });
}

class JobDialog extends StatefulWidget {
  final Job? old; const JobDialog({super.key,this.old});
  @override State<JobDialog> createState()=>_JobDialogState();
}
class _JobDialogState extends State<JobDialog>{
  final customer=TextEditingController(),phone=TextEditingController(),place=TextEditingController(),
    work=TextEditingController(text:'உழவு'),quantity=TextEditingController(text:'1'),
    rate=TextEditingController(),paid=TextEditingController(),note=TextEditingController();
  DateTime date=DateTime.now();
  final money=NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:2);
  double get total=>(double.tryParse(quantity.text)??0)*(double.tryParse(rate.text)??0);
  @override void initState(){super.initState();final x=widget.old;if(x!=null){
    customer.text=x.customer;phone.text=x.phone;place.text=x.place;work.text=x.work;
    quantity.text=x.quantity.toString();rate.text=x.rate.toString();paid.text=x.paid.toString();
    note.text=x.note;date=x.date;}}
  @override void dispose(){for(final c in [customer,phone,place,work,quantity,rate,paid,note]){c.dispose();}super.dispose();}
  Widget field(TextEditingController c,String label,{bool number=false})=>Padding(
    padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,
      keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,
      onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Text(widget.old==null?'வாடகை வேலை பதிவு':'வேலையைத் திருத்து'),
    content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      field(customer,'வாடிக்கையாளர் பெயர்'),field(phone,'தொலைபேசி எண்',number:true),
      field(place,'வேலை செய்த இடம்'),field(work,'வேலை வகை (உழவு / டிரெய்லர் / மற்றவை)'),
      Row(children:[Expanded(child:field(quantity,'அளவு (மணி / ஏக்கர்)',number:true)),
        const SizedBox(width:8),Expanded(child:field(rate,'ஒரு அளவுக்கான வாடகை ₹',number:true))]),
      Card(child:ListTile(title:const Text('மொத்த வாடகை'),trailing:Text(money.format(total)))),
      field(paid,'இதுவரை பெற்ற தொகை ₹',number:true),field(note,'குறிப்பு'),
      OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},
        icon:const Icon(Icons.calendar_month),label:Text(DateFormat('dd-MM-yyyy').format(date))),
    ]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ரத்து')),
      FilledButton(onPressed:(){
        final q=double.tryParse(quantity.text),r=double.tryParse(rate.text),p=double.tryParse(paid.text.isEmpty?'0':paid.text);
        if(customer.text.trim().isEmpty||q==null||r==null||q<=0||r<0||p==null||p<0||p>q*r){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('பெயர், அளவு, வாடகை மற்றும் பெற்ற தொகையை சரியாக உள்ளிடவும். பெற்ற தொகை மொத்தத்தை விட அதிகமாக இருக்கக்கூடாது.')));return;}
        Navigator.pop(context,Job(id:widget.old?.id??DateTime.now().microsecondsSinceEpoch.toString(),
          customer:customer.text.trim(),phone:phone.text.trim(),place:place.text.trim(),
          work:work.text.trim().isEmpty?'வேலை':work.text.trim(),note:note.text.trim(),
          quantity:q,rate:r,total:q*r,paid:p,date:date));
      },child:const Text('சேமி'))]);
}

class CostDialog extends StatefulWidget{
  final List<String> types;final Cost? old;
  const CostDialog({super.key,required this.types,this.old});
  @override State<CostDialog> createState()=>_CostDialogState();
}
class _CostDialogState extends State<CostDialog>{
  final amount=TextEditingController(),note=TextEditingController();
  late String category;DateTime date=DateTime.now();
  @override void initState(){super.initState();category=widget.old?.category??widget.types.first;
    if(widget.old!=null){amount.text=widget.old!.amount.toString();note.text=widget.old!.note;date=widget.old!.date;}}
  @override void dispose(){amount.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Text(widget.old==null?'செலவு பதிவு':'செலவைத் திருத்து'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'செலவு வகை',border:OutlineInputBorder()),
        items:widget.types.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>category=v!)),
      const SizedBox(height:10),
      TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),
        decoration:const InputDecoration(labelText:'தொகை ₹',border:OutlineInputBorder())),
      const SizedBox(height:10),
      TextField(controller:note,decoration:const InputDecoration(labelText:'குறிப்பு',border:OutlineInputBorder())),
      OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},
        icon:const Icon(Icons.calendar_month),label:Text(DateFormat('dd-MM-yyyy').format(date))),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ரத்து')),
      FilledButton(onPressed:(){final a=double.tryParse(amount.text);if(a==null||a<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('சரியான தொகையை உள்ளிடவும்')));return;}
        Navigator.pop(context,Cost(id:widget.old?.id??DateTime.now().microsecondsSinceEpoch.toString(),
          category:category,note:note.text.trim(),amount:a,date:date));},child:const Text('சேமி'))]);
}


class MeasureDialog extends StatefulWidget{final LandMeasure? old;const MeasureDialog({super.key,this.old});@override State<MeasureDialog> createState()=>_MeasureDialogState();}
class _MeasureDialogState extends State<MeasureDialog>{final owner=TextEditingController(),phone=TextEditingController(),village=TextEditingController(),survey=TextEditingController(),quantity=TextEditingController(text:'1'),rate=TextEditingController(),paid=TextEditingController(text:'0'),note=TextEditingController();String unit='ஏக்கர்';DateTime date=DateTime.now();@override void initState(){super.initState();final x=widget.old;if(x!=null){owner.text=x.owner;phone.text=x.phone;village.text=x.village;survey.text=x.survey;quantity.text=x.quantity.toString();rate.text=x.rate.toString();paid.text=x.paid.toString();note.text=x.note;unit=x.unit;date=x.date;}}@override void dispose(){for(final c in [owner,phone,village,survey,quantity,rate,paid,note]){c.dispose();}super.dispose();}Widget f(TextEditingController c,String l,{bool n=false})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:n?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,onChanged:(_)=>setState((){}),decoration:InputDecoration(labelText:l,border:const OutlineInputBorder())));@override Widget build(BuildContext context){final q=double.tryParse(quantity.text)??0,r=double.tryParse(rate.text)??0;return AlertDialog(title:Text(widget.old==null?'நில அளவீடு பதிவு':'நில அளவீட்டைத் திருத்து'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[f(owner,'நில உரிமையாளர் பெயர்'),f(phone,'தொலைபேசி',n:true),f(village,'கிராமம்'),f(survey,'சர்வே எண்'),DropdownButtonFormField<String>(value:unit,decoration:const InputDecoration(labelText:'அளவு அலகு',border:OutlineInputBorder()),items:['ஏக்கர்','சென்ட்','குழி','சதுர அடி'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>unit=v!)),const SizedBox(height:8),f(quantity,'நில அளவு',n:true),f(rate,'ஒரு அலகுக்கான அளவீட்டுக் கட்டணம் ₹',n:true),f(paid,'பெற்ற தொகை ₹',n:true),Text('மொத்தம்: ₹${(q*r).toStringAsFixed(2)}'),f(note,'குறிப்பு'),OutlinedButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},child:Text(DateFormat('dd-MM-yyyy').format(date)))]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ரத்து')),FilledButton(onPressed:(){final qv=double.tryParse(quantity.text),rv=double.tryParse(rate.text),pv=double.tryParse(paid.text.isEmpty?'0':paid.text);if(owner.text.trim().isEmpty||qv==null||rv==null||pv==null||qv<=0||rv<0||pv<0||pv>qv*rv){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('விவரங்களைச் சரியாக உள்ளிடவும்')));return;}Navigator.pop(context,LandMeasure(id:widget.old?.id??DateTime.now().microsecondsSinceEpoch.toString(),owner:owner.text.trim(),phone:phone.text.trim(),village:village.text.trim(),survey:survey.text.trim(),unit:unit,quantity:qv,rate:rv,paid:pv,note:note.text.trim(),date:date));},child:const Text('சேமி'))];}}

class PersonalDialog extends StatefulWidget{final PersonalEntry? old;const PersonalDialog({super.key,this.old});@override State<PersonalDialog> createState()=>_PersonalDialogState();}
class _PersonalDialogState extends State<PersonalDialog>{final person=TextEditingController(),amount=TextEditingController(),rate=TextEditingController(text:'0'),note=TextEditingController();final types=['பணம் கொடுத்தது','பணம் பெற்றது','கடன் கொடுத்தது','கடன் வாங்கியது','கடன் திருப்பிச் செலுத்தியது','பொருள் வாங்கியது','இதர வரவு','இதர செலவு'];late String type;DateTime date=DateTime.now();@override void initState(){super.initState();type=widget.old?.type??types.first;if(widget.old!=null){person.text=widget.old!.person;amount.text=widget.old!.amount.toString();rate.text=widget.old!.monthlyRate.toString();note.text=widget.old!.note;date=widget.old!.date;}}@override void dispose(){person.dispose();amount.dispose();rate.dispose();note.dispose();super.dispose();}@override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.old==null?'தனிநபர் கணக்கு பதிவு':'பதிவைத் திருத்து'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:person,decoration:const InputDecoration(labelText:'நபர் பெயர்',border:OutlineInputBorder())),const SizedBox(height:8),DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'கணக்கு வகை',border:OutlineInputBorder()),items:types.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v!)),const SizedBox(height:8),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'தொகை ₹',border:OutlineInputBorder())),if(type=='கடன் கொடுத்தது'||type=='கடன் வாங்கியது')Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:rate,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'மாத வட்டி % (எளிய வட்டி)',border:OutlineInputBorder()))),const SizedBox(height:8),TextField(controller:note,decoration:const InputDecoration(labelText:'குறிப்பு',border:OutlineInputBorder())),OutlinedButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},child:Text(DateFormat('dd-MM-yyyy').format(date)))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('ரத்து')),FilledButton(onPressed:(){final a=double.tryParse(amount.text),r=double.tryParse(rate.text.isEmpty?'0':rate.text);if(person.text.trim().isEmpty||a==null||a<=0||r==null||r<0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('பெயர் மற்றும் தொகையைச் சரியாக உள்ளிடவும்')));return;}Navigator.pop(context,PersonalEntry(id:widget.old?.id??DateTime.now().microsecondsSinceEpoch.toString(),person:person.text.trim(),type:type,amount:a,monthlyRate:r,date:date,note:note.text.trim()));},child:const Text('சேமி'))];}
