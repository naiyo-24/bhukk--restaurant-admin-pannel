// screens/account/edit_account_screen.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
// file picking via controller (file_selector backend)
import 'package:get/get.dart';
import '../../controller/common/file_picker_controller.dart';
import '../../widgets/main_scaffold.dart';
import '../../controller/account/account_controller.dart';
import '../../models/account_model.dart';
import '../../routes/app_routes.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final AccountController controller = Get.find<AccountController>();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtr;
  late final TextEditingController _addressCtr;
  late final TextEditingController _phoneCtr;
  late final TextEditingController _emailCtr;
  late final TextEditingController _hoursCtr;

  // For native platforms we may store a File; for web we keep bytes from XFile
  File? _pickedLogoFile;
  Uint8List? _pickedLogoBytes;

  // documents picked but not yet uploaded
  final List<XFile> _pickedDocs = [];

  @override
  void initState() {
    super.initState();
    final acct = controller.account.value;
    _nameCtr = TextEditingController(text: acct.name);
    _addressCtr = TextEditingController(text: acct.address);
    _phoneCtr = TextEditingController(text: acct.phone);
    _emailCtr = TextEditingController(text: acct.email);
    _hoursCtr = TextEditingController(text: acct.operatingHours);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _addressCtr.dispose();
    _phoneCtr.dispose();
    _emailCtr.dispose();
    _hoursCtr.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      // Ensure controller is available
      if (!Get.isRegistered<FilePickerController>()) {
        Get.put(FilePickerController());
      }
      final xf = await FilePickerController.to.pickImage();
  if (xf == null) return;
      if (!kIsWeb) {
        final f = FilePickerController.to.toNativeFile(xf);
        _pickedLogoFile = f;
        _pickedLogoBytes = null;
      } else {
        _pickedLogoFile = null;
        _pickedLogoBytes = await FilePickerController.to.readBytes(xf);
      }
      setState(() {});
    } catch (e) {
      Get.snackbar('Logo', 'Failed to pick logo: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickDocument() async {
    try {
      if (!Get.isRegistered<FilePickerController>()) Get.put(FilePickerController());
  final res = await FilePickerController.to.pickFiles(allowMultiple: true);
      if (res == null) return;
      for (final pf in res) {
        _pickedDocs.add(pf);
      }
      setState(() {});
    } catch (e) {
      Get.snackbar('Files', 'Failed to pick file(s): $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickTimeRange() async {
    // Pick start time first. Check mounted before using context for formatting.
  final start = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
  if (start == null) return;
  if (!mounted) return;
  final end = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 21, minute: 0));
    if (end == null) return;
    if (!mounted) return;
    // Now safe to use context synchronously.
    setState(() {
      _hoursCtr.text = '${start.format(context)} - ${end.format(context)}';
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = controller.account.value.copyWith(
      name: _nameCtr.text,
      email: _emailCtr.text,
      phone: _phoneCtr.text,
      address: _addressCtr.text,
      operatingHours: _hoursCtr.text,
      // If native file picked, persist path. For web, leave existing path.
      logoPath: _pickedLogoFile != null ? _pickedLogoFile!.path : controller.account.value.logoPath,
    );

    controller.updateAccount(updated);

  // Upload any picked docs (stub). Pass XFile (contains name/path; use controller.readBytes when needed).
    for (final pf in _pickedDocs) {
      await controller.uploadDocument(pf.name, pf);
    }

    Get.offNamed(AppRoutes.ACCOUNT);
  }

  void _onCancel() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Edit Account',
      child: LayoutBuilder(builder: (ctx, cons) {
        final isSmall = cons.maxWidth < 900;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Obx(() {
              final missing = controller.documents.any((d) => d.status != DocumentStatus.verified);
              if (!missing) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade300)),
                child: Row(children: [
                  const Icon(Icons.assignment_late, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Some documents are missing or not verified. Submit an application to build required documents.')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) {
                        // lightweight inline form to avoid cross-file dependency
                        final formKey = GlobalKey<FormState>();
                        String doc = controller.documents.firstWhereOrNull((d) => d.status != DocumentStatus.verified)?.name ?? 'Other';
                        String name = controller.account.value.name;
                        String email = controller.account.value.email;
                        String phone = controller.account.value.phone;
                        String notes = '';
                        final options = controller.documents.where((d) => d.status != DocumentStatus.verified).map((d) => d.name).toList();
                        final opts = options.isEmpty ? ['Other'] : options;
                        return Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Apply to Build Document', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: opts.contains(doc) ? doc : opts.first,
                                    items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                    onChanged: (v) => doc = v ?? opts.first,
                                    decoration: const InputDecoration(labelText: 'Document'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(initialValue: name, decoration: const InputDecoration(labelText: 'Applicant Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null, onChanged: (v) => name = v),
                                  const SizedBox(height: 8),
                                  TextFormField(initialValue: email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v == null || !RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(v)) ? 'Invalid email' : null, onChanged: (v) => email = v),
                                  const SizedBox(height: 8),
                                  TextFormField(initialValue: phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => (v == null || v.trim().length < 7) ? 'Invalid phone' : null, onChanged: (v) => phone = v),
                                  const SizedBox(height: 8),
                                  TextFormField(decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 3, onChanged: (v) => notes = v),
                                  const SizedBox(height: 12),
                                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (!(formKey.currentState?.validate() ?? false)) return;
                                        await controller.applyForDocument(documentName: doc, applicantName: name, email: email, phone: phone, notes: notes);
                                        if (ctx.mounted) Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Submit Application'),
                                    ),
                                  ])
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    icon: const Icon(Icons.description),
                    label: const Text('Apply'),
                  ),
                ]),
              );
            }),
            Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back())),
            Expanded(child: isSmall ? _buildMobile() : _buildDesktop()),
          ]),
        );
      }),
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _profileCard(),
          const SizedBox(height: 12),
          _businessCard(),
          const SizedBox(height: 12),
          _bankingCard(),
          const SizedBox(height: 12),
          _documentsCard(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _onCancel, child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: _onSave, child: const Text('Save'))),
          ])
        ]),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: SingleChildScrollView(
          child: Column(children: [
            _profileCard(),
            const SizedBox(height: 12),
            _businessCard(),
            const SizedBox(height: 12),
            _bankingCard(),
          ]),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        flex: 2,
        child: SingleChildScrollView(
          child: Column(children: [
            _documentsCard(),
            const SizedBox(height: 24),
            _actionButtons(),
          ]),
        ),
      )
    ]);
  }

  Widget _profileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profile Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(onTap: _pickLogo, child: _logoPreview()),
            const SizedBox(width: 12),
            Expanded(
                child: Column(children: [
              TextFormField(
                controller: _nameCtr,
                decoration: const InputDecoration(labelText: 'Restaurant name', prefixIcon: Icon(Icons.store)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtr,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter an email';
                  final re = RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}");
                  return re.hasMatch(v.trim()) ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtr,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter phone';
                  final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
                  return digits.length < 7 ? 'Enter a valid phone' : null;
                },
              ),
            ]))
          ]),
        ]),
      ),
    );
  }

  Widget _businessCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Business Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(controller: _addressCtr, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter address' : null),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _hoursCtr, readOnly: true, decoration: const InputDecoration(labelText: 'Operating hours', prefixIcon: Icon(Icons.access_time)))),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: _pickTimeRange, icon: const Icon(Icons.schedule), label: const Text('Pick'))
          ]),
        ]),
      ),
    );
  }

  Widget _bankingCard() {
    final acct = controller.account.value;
    final accCtr = TextEditingController(text: acct.bankAccountNo);
    final ifscCtr = TextEditingController(text: acct.bankIfsc);
    final bankCtr = TextEditingController(text: acct.bankName);
    final upiCtr = TextEditingController(text: acct.upiId ?? '');
    SettlementCycle cycle = acct.settlementCycle;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bank & Settlements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: accCtr, decoration: const InputDecoration(labelText: 'Account No', prefixIcon: Icon(Icons.account_balance)), validator: (v) => (v == null || v.trim().length < 8) ? 'Invalid account no' : null)),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: ifscCtr, decoration: const InputDecoration(labelText: 'IFSC', prefixIcon: Icon(Icons.qr_code_2)), validator: (v) => (v == null || v.trim().length < 6) ? 'Invalid IFSC' : null)),
          ]),
          const SizedBox(height: 8),
          TextFormField(controller: bankCtr, decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Icons.account_balance_wallet)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter bank name' : null),
          const SizedBox(height: 8),
          TextFormField(controller: upiCtr, decoration: const InputDecoration(labelText: 'UPI ID (optional)', prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Settlement Cycle:'),
            const SizedBox(width: 12),
            DropdownButton<SettlementCycle>(
              value: cycle,
              items: const [
                DropdownMenuItem(value: SettlementCycle.daily, child: Text('Daily')),
                DropdownMenuItem(value: SettlementCycle.weekly, child: Text('Weekly')),
                DropdownMenuItem(value: SettlementCycle.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => cycle = v);
              },
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                controller.updateBankDetails(accNo: accCtr.text, ifsc: ifscCtr.text, bank: bankCtr.text, upi: upiCtr.text);
                controller.setSettlementCycle(cycle);
                controller.save();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Bank'),
            )
          ])
        ]),
      ),
    );
  }


  Widget _documentsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Documents', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.upload_file), label: const Text('Upload document')),
          const SizedBox(height: 12),
          Obx(() {
            final docs = controller.documents;
            return Column(children: docs.map((d) => _docRow(d)).toList());
          }),
          const SizedBox(height: 8),
          if (_pickedDocs.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Files to upload', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Column(children: _pickedDocs.map((p) => ListTile(title: Text(p.name))).toList()),
          ]
        ]),
      ),
    );
  }

  Widget _docRow(DocumentModel d) {
    Color bg;
    String label;
    switch (d.status) {
      case DocumentStatus.verified:
        bg = Colors.green.shade100;
        label = 'Verified';
        break;
      case DocumentStatus.pending:
        bg = Colors.amber.shade100;
        label = 'Pending';
        break;
      case DocumentStatus.rejected:
        bg = Colors.red.shade100;
        label = 'Rejected';
        break;
    }
    final canApply = d.status != DocumentStatus.verified;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(label)),
        if (canApply) const SizedBox(width: 8),
        if (canApply)
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) {
                // Inline form configured for the selected document
                final formKey = GlobalKey<FormState>();
                String docName = d.name;
                String name = controller.account.value.name;
                String email = controller.account.value.email;
                String phone = controller.account.value.phone;
                String notes = '';
                return Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Apply to Build Document', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(docName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(initialValue: name, decoration: const InputDecoration(labelText: 'Applicant Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null, onChanged: (v) => name = v),
                          const SizedBox(height: 8),
                          TextFormField(initialValue: email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v == null || !RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(v)) ? 'Invalid email' : null, onChanged: (v) => email = v),
                          const SizedBox(height: 8),
                          TextFormField(initialValue: phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => (v == null || v.trim().length < 7) ? 'Invalid phone' : null, onChanged: (v) => phone = v),
                          const SizedBox(height: 8),
                          TextFormField(decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 3, onChanged: (v) => notes = v),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                            const SizedBox(width: 8),
                            ElevatedButton(onPressed: () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              await controller.applyForDocument(documentName: docName, applicantName: name, email: email, phone: phone, notes: notes);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            }, child: const Text('Submit Application')),
                          ])
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            icon: const Icon(Icons.description, size: 18),
            label: const Text('Apply'),
          ),
      ]),
    );
  }

  Widget _logoPreview() {
    // web: show bytes
    if (_pickedLogoBytes != null && kIsWeb) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_pickedLogoBytes!, width: 80, height: 80, fit: BoxFit.cover));
    }

    if (_pickedLogoFile != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_pickedLogoFile!, width: 80, height: 80, fit: BoxFit.cover));
    }

    final logoPath = controller.account.value.logoPath;
    if (logoPath != null && logoPath.isNotEmpty && !kIsWeb) {
      final f = File(logoPath);
      if (f.existsSync()) {
        return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover));
      }
    }

    return Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.storefront, color: Colors.grey, size: 36));
  }

  Widget _actionButtons() {
    return Row(children: [
      Expanded(child: OutlinedButton(onPressed: _onCancel, child: const Text('Cancel'))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton(onPressed: _onSave, child: const Text('Save'))),
    ]);
  }
}
