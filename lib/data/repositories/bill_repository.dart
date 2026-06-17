import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/bill/bill_model.dart';
import '../../core/models/bill_filter_model.dart';
import '../../services/supabase.dart';

class BillRepository {
  final SupabaseService _supabase;

  BillRepository(this._supabase);

  /// Create a new bill
  Future<BillModel> createBill(BillModel bill) async {
    try {
      final response = await _supabase.client
          .from('bills')
          .insert(bill.toJson())
          .select()
          .single();
      
      return BillModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating bill: $e');
      rethrow;
    }
  }

  /// Get all bills for a seller
  Future<List<BillModel>> getBillsBySellerId(String sellerId, {BillFilterModel? filters}) async {
    try {
      var query = _supabase.client
          .from('bills')
          .select()
          .eq('seller_id', sellerId);

      // Apply filters
      if (filters != null) {
        if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
          // Full-text search on recipient name or email
          query = query.or('recipient.name.ilike.%${filters.searchQuery}%,recipient.email.ilike.%${filters.searchQuery}%');
        }

        if (filters.statusFilters != null && filters.statusFilters!.isNotEmpty) {
          query = query.inFilter('status', filters.statusFilters!);
        }

        if (filters.typeFilters != null && filters.typeFilters!.isNotEmpty) {
          query = query.inFilter('type', filters.typeFilters!);
        }

        if (filters.startDate != null) {
          query = query.gte('created_at', filters.startDate!.toIso8601String());
        }

        if (filters.endDate != null) {
          query = query.lte('created_at', filters.endDate!.toIso8601String());
        }

        // Sorting
        query = query.order(
          filters.sortBy ?? 'created_at',
          ascending: filters.ascending,
        );
      } else {
        query = query.order('created_at', ascending: false);
      }

      final response = await query;
      return response.map((json) => BillModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching bills: $e');
      return [];
    }
  }

  /// Get a single bill by ID
  Future<BillModel?> getBillById(String billId) async {
    try {
      final response = await _supabase.client
          .from('bills')
          .select()
          .eq('id', billId)
          .single();
      
      return BillModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching bill: $e');
      return null;
    }
  }

  /// Update bill status
  Future<BillModel> updateBillStatus(String billId, BillStatus status) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.name,
      };

      if (status == BillStatus.paid) {
        updates['paid_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase.client
          .from('bills')
          .update(updates)
          .eq('id', billId)
          .select()
          .single();
      
      return BillModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating bill status: $e');
      rethrow;
    }
  }

  /// Update bill PDF URL
  Future<void> updateBillPdfUrl(String billId, String pdfUrl) async {
    try {
      await _supabase.client
          .from('bills')
          .update({'pdf_url': pdfUrl})
          .eq('id', billId);
    } catch (e) {
      debugPrint('Error updating PDF URL: $e');
    }
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      await _supabase.client
          .from('bills')
          .delete()
          .eq('id', billId);
    } catch (e) {
      debugPrint('Error deleting bill: $e');
      rethrow;
    }
  }

  /// Get bills statistics
  Future<Map<String, dynamic>> getBillsStats(String sellerId) async {
    try {
      final bills = await getBillsBySellerId(sellerId);
      
      double totalRevenue = 0;
      int totalBills = bills.length;
      int paidBills = bills.where((b) => b.status == BillStatus.paid).length;
      int pendingBills = bills.where((b) => b.status == BillStatus.pending).length;
      int overdueBills = bills.where((b) => b.status == BillStatus.overdue).length;
      
      for (var bill in bills) {
        if (bill.status == BillStatus.paid) {
          totalRevenue += bill.totalAmount;
        }
      }

      return {
        'total_revenue': totalRevenue,
        'total_bills': totalBills,
        'paid_bills': paidBills,
        'pending_bills': pendingBills,
        'overdue_bills': overdueBills,
      };
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {
        'total_revenue': 0.0,
        'total_bills': 0,
        'paid_bills': 0,
        'pending_bills': 0,
        'overdue_bills': 0,
      };
    }
  }
}
