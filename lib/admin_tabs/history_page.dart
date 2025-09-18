// lib/admin_tabs/history_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DateFilter { today, thisWeek, thisMonth, all }

DateTimeRange getDateRange(DateFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case DateFilter.today:
      return DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
    case DateFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), end: now);
    case DateFilter.thisMonth:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    case DateFilter.all:
      return DateTimeRange(start: DateTime(2000), end: now);
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("History"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: "User Purchases"),
              Tab(icon: Icon(Icons.store), text: "Vendor Earnings"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserPurchaseHistory(),
            VendorEarningsHistory(),
          ],
        ),
      ),
    );
  }
}

// ========================== User Purchase History ==========================
class UserPurchaseHistory extends StatefulWidget {
  const UserPurchaseHistory({super.key});

  @override
  State<UserPurchaseHistory> createState() => _UserPurchaseHistoryState();
}

class _UserPurchaseHistoryState extends State<UserPurchaseHistory> {
  DateFilter _selectedFilter = DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final dateRange = getDateRange(_selectedFilter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<DateFilter>(
            value: _selectedFilter,
            onChanged: (value) => setState(() => _selectedFilter = value!),
            items: const [
              DropdownMenuItem(value: DateFilter.today, child: Text("Today")),
              DropdownMenuItem(value: DateFilter.thisWeek, child: Text("This Week")),
              DropdownMenuItem(value: DateFilter.thisMonth, child: Text("This Month")),
              DropdownMenuItem(value: DateFilter.all, child: Text("All Time")),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("orders")
                .where("eventDate", isGreaterThanOrEqualTo: dateRange.start)
                .where("eventDate", isLessThanOrEqualTo: dateRange.end)
                .orderBy("eventDate")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allOrders = snapshot.data?.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList() ??
                  [];

              if (allOrders.isEmpty) {
                return const Center(
                  child: Text(
                    "No history yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView(
                children: [
                  HistorySummary(orders: allOrders),
                  ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.event_available, color: Colors.orange),
                    title: Text(
                        "Upcoming Events (${allOrders.where((o) => o['eventStatus'] != 'done').length})"),
                    children: allOrders
                        .where((o) => o['eventStatus'] != 'done')
                        .map((order) => buildOrderCard(order))
                        .toList(),
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(
                        "Completed Events (${allOrders.where((o) => o['eventStatus'] == 'done').length})"),
                    children: allOrders
                        .where((o) => o['eventStatus'] == 'done')
                        .map((order) => buildOrderCard(order))
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final eventDate = (order['eventDate'] as Timestamp).toDate();
    final paymentStatus = order['paymentStatus'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text("User: ${order['userId']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service: ${order['serviceId']}"),
            Text("Event Date: $eventDate"),
            Text("Advance Paid: ₹${order['advancePaid']}"),
            Text("Total Amount: ₹${order['totalAmount']}"),
            Text(
              "Payment: ${paymentStatus == 'complete' ? "✅ Complete" : "❌ Pending (₹${order['balanceAmount']})"}",
            ),
            Text("Event Status: ${order['eventStatus']}"),
          ],
        ),
      ),
    );
  }
}

// ========================== Vendor Earnings History ==========================
class VendorEarningsHistory extends StatefulWidget {
  const VendorEarningsHistory({super.key});

  @override
  State<VendorEarningsHistory> createState() => _VendorEarningsHistoryState();
}

class _VendorEarningsHistoryState extends State<VendorEarningsHistory> {
  DateFilter _selectedFilter = DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final dateRange = getDateRange(_selectedFilter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<DateFilter>(
            value: _selectedFilter,
            onChanged: (value) => setState(() => _selectedFilter = value!),
            items: const [
              DropdownMenuItem(value: DateFilter.today, child: Text("Today")),
              DropdownMenuItem(value: DateFilter.thisWeek, child: Text("This Week")),
              DropdownMenuItem(value: DateFilter.thisMonth, child: Text("This Month")),
              DropdownMenuItem(value: DateFilter.all, child: Text("All Time")),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("orders")
                .where("eventDate", isGreaterThanOrEqualTo: dateRange.start)
                .where("eventDate", isLessThanOrEqualTo: dateRange.end)
                .orderBy("eventDate")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allOrders = snapshot.data?.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList() ??
                  [];

              if (allOrders.isEmpty) {
                return const Center(
                  child: Text(
                    "No history yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView(
                children: [
                  HistorySummary(orders: allOrders, isVendor: true),
                  ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.event_note, color: Colors.orange),
                    title: Text(
                        "Upcoming Bookings (${allOrders.where((o) => o['eventStatus'] != 'done').length})"),
                    children: allOrders
                        .where((o) => o['eventStatus'] != 'done')
                        .map((order) => buildVendorCard(order))
                        .toList(),
                  ),
                  ExpansionTile(
                    leading: const Icon(Icons.monetization_on, color: Colors.green),
                    title: Text(
                        "Completed Bookings (${allOrders.where((o) => o['eventStatus'] == 'done').length})"),
                    children: allOrders
                        .where((o) => o['eventStatus'] == 'done')
                        .map((order) => buildVendorCard(order))
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildVendorCard(Map<String, dynamic> order) {
    final eventDate = (order['eventDate'] as Timestamp).toDate();
    final paymentStatus = order['paymentStatus'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text("Vendor: ${order['vendorId']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service: ${order['serviceId']}"),
            Text("Event Date: $eventDate"),
            Text("Advance Received: ₹${order['advancePaid']}"),
            Text("Total Amount: ₹${order['totalAmount']}"),
            Text(
              "Payment: ${paymentStatus == 'complete' ? "✅ Complete" : "❌ Pending (₹${order['balanceAmount']})"}",
            ),
            Text("Event Status: ${order['eventStatus']}"),
          ],
        ),
      ),
    );
  }
}

// ========================== Analytics Summary ==========================
class HistorySummary extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool isVendor;

  const HistorySummary({super.key, required this.orders, this.isVendor = false});

  @override
  Widget build(BuildContext context) {
    final totalOrders = orders.length;
    final upcoming = orders.where((o) => o['eventStatus'] != 'done').length;
    final completed = orders.where((o) => o['eventStatus'] == 'done').length;
    final pendingBalance = orders
        .where((o) => o['paymentStatus'] != 'complete')
        .fold<double>(0, (acc, o) => acc + (o['balanceAmount'] ?? 0.0));
    final totalAmount = orders.fold<double>(
        0, (acc, o) => acc + (o['totalAmount'] ?? 0.0));

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      children: [
        _buildSummaryCard("Total Orders", totalOrders.toString(), Icons.list_alt, Colors.blue),
        _buildSummaryCard("Upcoming", upcoming.toString(), Icons.event_available, Colors.orange),
        _buildSummaryCard("Completed", completed.toString(), Icons.check_circle, Colors.green),
        _buildSummaryCard("Pending Balance", "₹$pendingBalance", Icons.warning, Colors.red),
        _buildSummaryCard(isVendor ? "Total Earnings" : "Total Amount", "₹$totalAmount",
            Icons.monetization_on, Colors.teal),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
