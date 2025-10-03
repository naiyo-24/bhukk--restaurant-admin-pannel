// screens/dining/table_grid_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/table_model.dart';
import '../../controller/dining/table_controller.dart';
import '../../controller/dining/payment_controller.dart';

class TableGridView extends StatefulWidget {
  const TableGridView({super.key});
  @override
  State<TableGridView> createState() => _TableGridViewState();
}

class _TableGridViewState extends State<TableGridView> {
  final TableController controller = Get.put(TableController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(builder: (context, cons) {
                final isNarrow = cons.maxWidth < 640;
                final title = Text('Table Management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800));
                final addBtn = ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Table'),
                  onPressed: () async {
                    final result = await showDialog<TableModel>(
                      context: context,
                      builder: (context) => const AddTableDialog(),
                    );
                    if (result != null) {
                      controller.addTable(result);
                      Get.snackbar('Table added', 'Table ${result.tableNumber} added', snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                );
                return isNarrow
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 12), addBtn])
                    : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [title, addBtn]);
              }),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, cons) {
                  final width = cons.maxWidth;
                  final count = (width / 260).floor().clamp(1, 6);
                  final aspect = width < 500 ? 1.0 : 1.2;
                  return Obx(() => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: aspect,
                        ),
                        itemCount: controller.tables.length,
                        itemBuilder: (_, i) => _TableCard(
                          table: controller.tables[i],
                          onDetails: () => _showDetails(controller.tables[i]),
                        ),
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(TableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        // Staged values (only applied when Save pressed)
        final original = table; // snapshot for change detection
        final txtWaiter = TextEditingController(text: table.waiter);
        final txtGuests = TextEditingController(text: table.currentGuestsSafe.toString());
        final txtNotes = TextEditingController(text: table.notesSafe);
        String status = table.status;
        String waiterVal = table.waiter;
        int guestsVal = table.currentGuestsSafe;
        String notesVal = table.notesSafe;
        int capacityVal = table.capacity;
        final Set<int> tablesToRemove = {}; // merged tables
        TableModel? tableToAdd; // split new table
        final List<String> pendingBilling = []; // descriptions
        final List<VoidCallback> billingApply = []; // actions
        return StatefulBuilder(builder: (ctx, setState) {
          void stageStatus(String s) => setState(() => status = s);
          Duration occupiedDur() => table.occupiedSince==null? Duration.zero : DateTime.now().difference(table.occupiedSince!);
          String occupiedText(){
            final d = occupiedDur();
            if(d==Duration.zero) return '—';
            String two(int n)=> n.toString().padLeft(2,'0');
            return '${two(d.inHours)}:${two(d.inMinutes%60)}:${two(d.inSeconds%60)}';
          }
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (_, scrollCtl) => SingleChildScrollView(
              controller: scrollCtl,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Table ${table.tableNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  Chip(label: Text(status)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 12),
                _kv('Capacity', capacityVal.toString()),
                _kv('Current Guests', guestsVal.toString()),
                _kv('Waiter', waiterVal.isEmpty ? 'Unassigned' : waiterVal),
                _kv('Occupied For', occupiedText()),
                if (table.orderId.isNotEmpty) _kv('Linked Order/Reservation', table.orderId),
                const Divider(height: 32),
                Text('Update', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _statusBtn('Available', status == 'Available', () => stageStatus('Available')),
                  _statusBtn('Occupied', status == 'Occupied', () => stageStatus('Occupied')),
                  _statusBtn('Reserved', status == 'Reserved', () => stageStatus('Reserved')),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: txtWaiter,
                  decoration: const InputDecoration(labelText: 'Assign / Change Waiter'),
                  onChanged: (v) => setState(() => waiterVal = v.trim()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txtGuests,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Guests'),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim());
                    if (parsed != null) setState(() => guestsVal = parsed.clamp(0, capacityVal));
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txtNotes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes / Special'),
                  onChanged: (v) => setState(() => notesVal = v.trim()),
                ),
                const SizedBox(height: 24),
                Text('Structure', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.merge_type),
                    label: const Text('Merge With...'),
                    onPressed: () async {
                      final c = Get.find<TableController>();
                      // Only show AVAILABLE tables not already staged & not the current one
                      final candidates = c.tables.where((t) => t.tableNumber != table.tableNumber && t.status == 'Available' && !tablesToRemove.contains(t.tableNumber)).toList();
                      if (candidates.isEmpty) {
                        Get.snackbar('Merge', 'No available tables to merge', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final selected = await showDialog<List<int>>(
                        context: ctx,
                        builder: (d) {
                          final sel = <int>{};
                          return StatefulBuilder(builder: (dCtx, setD) {
                            return AlertDialog(
                              title: const Text('Select tables to merge'),
                              content: SizedBox(
                                width: 360,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    ...candidates.map((t) => CheckboxListTile(
                                          dense: true,
                                          value: sel.contains(t.tableNumber),
                                          title: Text('Table ${t.tableNumber} (cap ${t.capacity})'),
                                          onChanged: (v) {
                                            setD(() {
                                              if (v == true) {
                                                sel.add(t.tableNumber);
                                              } else {
                                                sel.remove(t.tableNumber);
                                              }
                                            });
                                          },
                                        )),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, null), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: sel.isEmpty ? null : () => Navigator.pop(d, sel.toList()),
                                  child: const Text('Add Merge'),
                                ),
                              ],
                            );
                          });
                        },
                      );
                      if (selected != null && selected.isNotEmpty) {
                        setState(() {
                          for (final num in selected) {
                            final t = c.tables.firstWhereOrNull((e) => e.tableNumber == num);
                            if (t != null) {
                              capacityVal += t.capacity;
                              tablesToRemove.add(t.tableNumber);
                            }
                          }
                          notesVal = '$notesVal${notesVal.isEmpty ? '' : ' | '}Merged ${selected.map((e)=>e.toString()).join(', ')}';
                          txtNotes.text = notesVal;
                        });
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.call_split),
                    label: const Text('Split Table'),
                    onPressed: () async {
                      if (capacityVal <= 2) {
                        Get.snackbar('Split', 'Too small to split', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final half = (capacityVal / 2).floor();
                      final capCtl = TextEditingController(text: half.toString());
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          title: const Text('Split Table'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Capacity $capacityVal will be split.'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: capCtl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Capacity for original table'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Split')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final firstCap = int.tryParse(capCtl.text.trim()) ?? half;
                        if (firstCap < 1 || firstCap >= capacityVal) {
                          Get.snackbar('Split', 'Invalid capacity', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        final secondCap = capacityVal - firstCap;
                        final c = Get.find<TableController>();
                        int newNum = c.tables.length + 1;
                        while (!c.isTableNumberAvailable(newNum) || newNum == table.tableNumber) {
                          newNum++;
                        }
                        setState(() {
                          capacityVal = firstCap;
                          tableToAdd = TableModel(
                              tableNumber: newNum,
                              capacity: secondCap,
                              status: 'Available',
                              waiter: 'Unassigned',
                              orderId: '',
                              notes: 'Split from ${table.tableNumber}',
                              currentGuests: 0);
                          notesVal = '$notesVal${notesVal.isEmpty ? '' : ' | '}Split -> $newNum';
                          txtNotes.text = notesVal;
                        });
                      }
                    },
                  ),
                ]),
                if (tablesToRemove.isNotEmpty || tableToAdd != null) const SizedBox(height: 12),
                if (tablesToRemove.isNotEmpty || tableToAdd != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Staged Structure Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (tablesToRemove.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing:8,
                          runSpacing:8,
                          children: tablesToRemove.map((e)=> Chip(
                            label: Text('Table $e'),
                            deleteIcon: const Icon(Icons.close, size:16),
                            onDeleted: (){
                              setState((){
                                capacityVal = capacityVal - (Get.find<TableController>().tables.firstWhereOrNull((t)=> t.tableNumber==e)?.capacity ?? 0);
                                tablesToRemove.remove(e);
                              });
                            },
                          )).toList(),
                        ),
                      ],
                      if (tableToAdd != null) ...[
                        const SizedBox(height: 6),
                        Chip(
                          label: Text('New Table ${tableToAdd!.tableNumber} (cap ${tableToAdd!.capacity})'),
                          deleteIcon: const Icon(Icons.close, size:16),
                          onDeleted: (){
                            setState((){
                              capacityVal += tableToAdd!.capacity; 
                              final removedNum = tableToAdd!.tableNumber; 
                              tableToAdd = null; 
                              notesVal = notesVal.replaceAll('Split -> $removedNum', '');
                              txtNotes.text = notesVal; 
                            });
                          },
                        ),
                      ],
                    ]),
                  ),
                const SizedBox(height: 24),
                Text('Billing', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.call_split),
                    label: const Text('Split Bill (Even)'),
                    onPressed: () {
                      setState(() {
                        pendingBilling.add('Split bill (even)');
                        billingApply.add(() {
                          final pay = Get.isRegistered<PaymentController>() ? Get.find<PaymentController>() : Get.put(PaymentController());
                          pay.splitBill('Table ${table.tableNumber}', even: true);
                        });
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.merge_type),
                    label: const Text('Merge Bill With...'),
                    onPressed: () async {
                      final pay = Get.isRegistered<PaymentController>() ? Get.find<PaymentController>() : Get.put(PaymentController());
                      final others = pay.payments.where((p) => p.table != 'Table ${table.tableNumber}').map((p) => p.table).toList();
                      if (others.isEmpty) {
                        Get.snackbar('Billing', 'No other bills to merge', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final selected = await showDialog<List<String>>(
                        context: ctx,
                        builder: (d) {
                          final sel = <String>{};
                          return StatefulBuilder(builder: (dCtx, setD) {
                            return AlertDialog(
                              title: const Text('Select bills to merge'),
                              content: SizedBox(
                                width: 360,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    ...others.map((t) => CheckboxListTile(
                                          dense: true,
                                          value: sel.contains(t),
                                          title: Text(t),
                                          onChanged: (v) {
                                            setD(() {
                                              if (v == true) {
                                                sel.add(t);
                                              } else {
                                                sel.remove(t);
                                              }
                                            });
                                          },
                                        )),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, null), child: const Text('Cancel')),
                                ElevatedButton(onPressed: sel.isEmpty ? null : () => Navigator.pop(d, sel.toList()), child: const Text('Add Merge')),
                              ],
                            );
                          });
                        },
                      );
                      if (selected != null && selected.isNotEmpty) {
                        setState(() {
                          pendingBilling.add('Merge bills: ${selected.join(', ')}');
                          billingApply.add(() {
                            final pay2 = Get.isRegistered<PaymentController>() ? Get.find<PaymentController>() : Get.put(PaymentController());
                            for(final bill in selected){ pay2.mergeBills('Table ${table.tableNumber}', bill); }
                          });
                        });
                      }
                    },
                  ),
                ]),
                if (pendingBilling.isNotEmpty) const SizedBox(height: 12),
                if (pendingBilling.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Staged Billing Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Wrap(spacing:8, runSpacing:8, children: [
                        for (int i=0;i<pendingBilling.length;i++) Chip(label: Text(pendingBilling[i]), deleteIcon: const Icon(Icons.close, size:16), onDeleted: (){ setState((){ pendingBilling.removeAt(i); billingApply.removeAt(i); }); })
                      ])
                    ]),
                  ),
                const SizedBox(height: 24),
                Builder(builder: (btnCtx){
                  bool hasChanges(){
                    return status != original.status || waiterVal.trim() != original.waiter.trim() || guestsVal != original.currentGuestsSafe || notesVal != original.notesSafe || capacityVal != original.capacity || tablesToRemove.isNotEmpty || tableToAdd!=null || pendingBilling.isNotEmpty;
                  }
                  final changed = hasChanges();
                  return Wrap(spacing:12, runSpacing:12, children:[
                    if(changed) ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:20, vertical:14), backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        try{
                          final c = Get.find<TableController>();
                          c.beginBatch();
                          // compute occupiedSince handling
                          DateTime? occupiedSince = original.occupiedSince;
                          if(status == 'Occupied' && original.status != 'Occupied') { occupiedSince = DateTime.now(); }
                          if(status == 'Available') { occupiedSince = null; }
                          final updated = original.copyWith(
                            status: status,
                            waiter: waiterVal,
                            currentGuests: guestsVal,
                            notes: notesVal,
                            capacity: capacityVal,
                            occupiedSince: occupiedSince,
                          );
                          c.editTable(updated);
                          for (final r in tablesToRemove) { c.removeTable(r); }
                          if (tableToAdd != null) { c.addTable(tableToAdd!); }
                          for (final fn in billingApply) { fn(); }
                          c.endBatch();
                          Navigator.pop(ctx);
                          Get.snackbar('Saved', 'Changes applied', snackPosition: SnackPosition.BOTTOM);
                        } catch(e){
                          Get.find<TableController>().endBatch();
                          Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ) else FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.block),
                      label: const Text('No Changes'),
                      style: FilledButton.styleFrom(disabledBackgroundColor: Colors.grey.shade300, disabledForegroundColor: Colors.grey.shade700, padding: const EdgeInsets.symmetric(horizontal:20, vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.find<TableController>().removeTable(original.tableNumber); Navigator.pop(ctx); Get.snackbar('Removed', 'Table removed', snackPosition: SnackPosition.BOTTOM);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Table'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:16, vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), foregroundColor: Colors.red.shade700),
                    ),
                    OutlinedButton.icon(
                      onPressed: () { final c = Get.find<TableController>(); if(c.canUndo){ c.undo(); Get.snackbar('Undo', 'Reverted last change', snackPosition: SnackPosition.BOTTOM); Navigator.pop(ctx);} },
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:16, vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ]);
                }),
                const SizedBox(height: 28),
                Text('Suggested Future Features', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  '• Real-time waiter assignment & push notifications\n'
                  '• Combine/split bill management\n'
                  '• Live timer since Occupied for turnover analytics\n'
                  '• QR code for self-ordering & digital menu\n'
                  '• Cleaning countdown after table vacated',
                ),
                const SizedBox(height: 32),
              ]),
            ),
          );
        }); // StatefulBuilder
      },
    ); // showModalBottomSheet
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(children: [SizedBox(width: 160, child: Text(k, style: const TextStyle(color: Colors.black54))), Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)))]),
      );

  Widget _statusBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.red.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.red : Colors.grey.shade400),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onDetails;
  const _TableCard({required this.table, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final statusColors = <String, Color>{
      'Available': Colors.green,
      'Occupied': Colors.red,
      'Reserved': Colors.orange,
    };
    final color = statusColors[table.status] ?? Colors.grey;
    return InkWell(
      onTap: onDetails,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          border: Border.all(color: color, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Table ${table.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w800))),
              _statusChip(table.status, color),
            ]),
            const SizedBox(height: 8),
            Text('Capacity: ${table.capacity}') ,
            const SizedBox(height: 8),
            Text('Waiter: ${table.waiter}'),
            const SizedBox(height: 8),
            Text('Order ID: ${table.orderId}'),
            if (table.currentGuestsSafe > 0) const SizedBox(height: 8),
            if (table.currentGuestsSafe > 0) Text('Guests: ${table.currentGuestsSafe}'),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.edit_note),
                label: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// Removed local TableModel versions (using imported)

class EditTableDialog extends StatefulWidget {
  final TableModel table;
  const EditTableDialog({super.key, required this.table});
  @override
  State<EditTableDialog> createState() => _EditTableDialogState();
}

class _EditTableDialogState extends State<EditTableDialog> {
  late int tableNumber;
  late int capacity;
  late String status;
  late String waiter;

  @override
  void initState() {
    super.initState();
    tableNumber = widget.table.tableNumber;
    capacity = widget.table.capacity;
    status = widget.table.status;
    waiter = widget.table.waiter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Table ${widget.table.tableNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: tableNumber.toString(),
            decoration: const InputDecoration(labelText: 'Table Number'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => tableNumber = int.tryParse(v) ?? tableNumber),
          ),
          TextFormField(
            initialValue: capacity.toString(),
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => capacity = int.tryParse(v) ?? capacity),
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['Available', 'Occupied', 'Reserved']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => status = v ?? status),
          ),
          TextFormField(
            initialValue: waiter,
            decoration: const InputDecoration(labelText: 'Waiter'),
            onChanged: (v) => setState(() => waiter = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, widget.table.copyWith(
              tableNumber: tableNumber,
              capacity: capacity,
              status: status,
              waiter: waiter,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddTableDialog extends StatefulWidget {
  const AddTableDialog({super.key});
  @override
  State<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends State<AddTableDialog> {
  int tableNumber = 1;
  int capacity = 4;
  String status = 'Available';
  String waiter = 'Unassigned';

  @override
  void initState() {
    super.initState();
    final c = Get.find<TableController>();
    int n = c.tables.length + 1;
    while (!c.isTableNumberAvailable(n)) {
      n++;
    }
    tableNumber = n;
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TableController>();
    return AlertDialog(
      title: const Text('Add Table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: tableNumber.toString(),
            decoration: const InputDecoration(labelText: 'Table Number'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => tableNumber = int.tryParse(v) ?? tableNumber),
          ),
          const SizedBox(height: 12),
            TextFormField(
            initialValue: capacity.toString(),
            decoration: const InputDecoration(labelText: 'Capacity'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => capacity = int.tryParse(v) ?? capacity),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const ['Available', 'Occupied', 'Reserved']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => status = v ?? status),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: waiter,
            decoration: const InputDecoration(labelText: 'Waiter'),
            onChanged: (v) => setState(() => waiter = v),
          ),
          const SizedBox(height: 8),
          if (!c.isTableNumberAvailable(tableNumber))
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Table number already exists. Will pick next free number.', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, TableModel(
              tableNumber: tableNumber,
              capacity: capacity,
              status: status,
              waiter: waiter,
              orderId: '',
            ));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
