// controller/dining/table_controller.dart
import 'package:get/get.dart';
import '../../models/table_model.dart';

class TableController extends GetxController {
  var tables = <TableModel>[].obs;
  final List<List<TableModel>> _history = <List<TableModel>>[]; // simple snapshot stack
  static const int _maxHistory = 20;
  int _batchDepth = 0; // when >0 we suppress intermediate history pushes

  void beginBatch(){ _batchDepth++; }
  void endBatch(){ if(_batchDepth>0){ _batchDepth--; if(_batchDepth==0){ _pushHistory(force:true); } } }

  void _pushHistory({bool force=false}){
    if(_batchDepth>0 && !force) return; // skip until batch ends
    _history.add(tables.map((t)=> t.copyWith()).toList());
    if(_history.length>_maxHistory){ _history.removeAt(0);}    
  }

  bool get canUndo => _history.isNotEmpty;
  void undo(){
    if(!canUndo) return;
    final last = _history.removeLast();
    tables.value = last;
  }

  @override
  void onInit() {
    super.onInit();
    // Load initial data (could be from API or local)
    tables.value = List.generate(12, (i) => TableModel(
      tableNumber: i + 1,
      capacity: 4,
  status: ['Available', 'Occupied', 'Reserved'][i % 3],
      waiter: 'John',
      orderId: '#1234',
  notes: '',
  currentGuests: 0,
    ));
  }

  void editTable(TableModel updated) {
  _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == updated.tableNumber);
    if (idx != -1) {
      tables[idx] = updated;
    } else {
      // If table number changed and doesn't exist, replace by matching old record via other fields
      final altIdx = tables.indexWhere((t) => t.orderId == updated.orderId && t.waiter == updated.waiter && t.capacity == updated.capacity);
      if (altIdx != -1) tables[altIdx] = updated;
    }
  }

  void updateTable(int oldNumber, TableModel updated) {
    final idx = tables.indexWhere((t) => t.tableNumber == oldNumber);
    if (idx == -1) return;
    // If the number changed and collides with another table, pick next available
    int desired = updated.tableNumber;
    if (desired != oldNumber && !isTableNumberAvailable(desired)) {
      while (!isTableNumberAvailable(desired)) {
        desired++;
      }
      updated = updated.copyWith(tableNumber: desired);
    }
    tables[idx] = updated;
  }

  bool isTableNumberAvailable(int number) {
    return !tables.any((t) => t.tableNumber == number);
  }

  void addTable(TableModel table) {
  _pushHistory();
    if (isTableNumberAvailable(table.tableNumber)) {
      tables.add(table);
    } else {
      // auto-pick next available number
      int n = table.tableNumber;
      while (!isTableNumberAvailable(n)) {
        n++;
      }
      tables.add(table.copyWith(tableNumber: n));
    }
  }

  void removeTable(int tableNumber) {
  _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx != -1) {
      tables.removeAt(idx);
    }
  }

  // Reserve or occupy a table for a reservation or order
  void ensureTable(int tableNumber, {required String status, String waiter = 'Unassigned', String orderId = ''}) {
    _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx == -1) {
  tables.add(TableModel(tableNumber: tableNumber, capacity: 4, status: status, waiter: waiter, orderId: orderId, notes: '', currentGuests: 0, occupiedSince: status=='Occupied'? DateTime.now(): null));
    } else {
      tables[idx] = tables[idx].copyWith(status: status, orderId: orderId, occupiedSince: status=='Occupied'? (tables[idx].isOccupied? tables[idx].occupiedSince : DateTime.now()): tables[idx].occupiedSince);
    }
  }

  // Free a table associated with a reservation or order
  void freeTablesByOrderId(String orderId) {
    for (int i = 0; i < tables.length; i++) {
      if (tables[i].orderId == orderId) {
        tables[i] = tables[i].copyWith(status: 'Available', orderId: '');
      }
    }
  }

  void removeTablesByReservation(String reservationId) {
  tables.removeWhere((t) => t.orderId == reservationId);
  }

  int? firstAvailableTable() {
    final t = tables.firstWhereOrNull((e) => e.status == 'Available');
    return t?.tableNumber;
  }

  void setStatus(int tableNumber, String status) {
    _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx != -1) {
      final cur = tables[idx];
      tables[idx] = cur.copyWith(status: status, occupiedSince: status=='Occupied'? (cur.isOccupied? cur.occupiedSince : DateTime.now()) : (status=='Available'? null : cur.occupiedSince));
    }
  }

  void assignWaiter(int tableNumber, String waiter) {
  _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx != -1) tables[idx] = tables[idx].copyWith(waiter: waiter);
  }

  void updateGuests(int tableNumber, int guests) {
  _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx != -1) tables[idx] = tables[idx].copyWith(currentGuests: guests);
  }

  void updateNotes(int tableNumber, String notes) {
  _pushHistory();
    final idx = tables.indexWhere((t) => t.tableNumber == tableNumber);
    if (idx != -1) tables[idx] = tables[idx].copyWith(notes: notes);
  }

  // Add more actions: merge, split, assign staff, etc.
}
