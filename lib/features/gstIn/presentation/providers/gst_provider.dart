import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/gst_models.dart';

final gstProfileProvider = Provider<GstProfile>((ref) {
  return const GstProfile(
    gstin: '19ABCDE1234F1Z5',
    legalName: 'Tax Bunny Retail Store',
    tradeName: 'Tax Bunny Retail Store',
    registrationDate: '01 Jul 2023',
    primaryPlaceOfBusiness: '12, Industrial Area, Kolkata - 700015, West Bengal',
    state: 'West Bengal',
    stateCode: '19',
    status: 'Active',
  );
});

final gstKpiMetricsProvider = Provider<GstKpiMetrics>((ref) {
  return const GstKpiMetrics(
    returnsFiledCount: 5,
    totalReturnsCount: 6,
    returnCompliancePercentage: 83.0,
    upcomingLiability: 18750.00,
    itcAvailable: 42350.00,
    annualTurnover: 2485630.00,
    turnoverDateLabel: 'Up to 24 May 2026',
    gstinStatus: 'Active',
  );
});

final gstReturnsListProvider = Provider<List<GstReturnRecord>>((ref) {
  return const [
    GstReturnRecord(
      id: 'ret_01',
      returnType: 'GSTR-1',
      taxPeriod: 'May 2026',
      dueDate: '11 Jun 2026',
      status: GstReturnStatus.notFiled,
      liabilityAmount: null,
    ),
    GstReturnRecord(
      id: 'ret_02',
      returnType: 'GSTR-3B',
      taxPeriod: 'May 2026',
      dueDate: '20 Jun 2026',
      status: GstReturnStatus.notFiled,
      liabilityAmount: 18750.00,
    ),
    GstReturnRecord(
      id: 'ret_03',
      returnType: 'GSTR-1',
      taxPeriod: 'Apr 2026',
      dueDate: '11 May 2026',
      status: GstReturnStatus.filed,
      liabilityAmount: null,
    ),
    GstReturnRecord(
      id: 'ret_04',
      returnType: 'GSTR-3B',
      taxPeriod: 'Apr 2026',
      dueDate: '20 May 2026',
      status: GstReturnStatus.filed,
      liabilityAmount: 15420.00,
    ),
    GstReturnRecord(
      id: 'ret_05',
      returnType: 'GSTR-1',
      taxPeriod: 'Mar 2026',
      dueDate: '11 Apr 2026',
      status: GstReturnStatus.filed,
      liabilityAmount: null,
    ),
  ];
});

final gstLiabilitySummaryProvider = Provider<GstLiabilitySummary>((ref) {
  return const GstLiabilitySummary(
    totalLiability: 104250.00,
    igst: 45250.00,
    cgst: 29500.00,
    sgst: 29500.00,
    cess: 0.00,
    paidThisFy: 68830.00,
    balanceThisFy: 104250.00,
    financialYear: 'FY 2025-26',
  );
});

class GstActiveTabNotifier extends StateNotifier<String> {
  GstActiveTabNotifier() : super('Overview');

  void setTab(String tab) => state = tab;
}

final gstActiveTabProvider = StateNotifierProvider<GstActiveTabNotifier, String>((ref) {
  return GstActiveTabNotifier();
});
