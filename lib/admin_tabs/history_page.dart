// lib/admin_tabs/history_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum DateFilter { today, thisWeek, thisMonth, all }

DateTimeRange getDateRange(DateFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case DateFilter.today:
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: now,
      );
    case DateFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: now,
      );
    case DateFilter.thisMonth:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    case DateFilter.all:
      return DateTimeRange(start: DateTime(2020), end: now);
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: const [
          TabBar(
            labelColor: Color(0xFF6A11CB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6A11CB),
            tabs: [
              Tab(icon: Icon(Icons.person), text: "User Bookings"),
              Tab(icon: Icon(Icons.store), text: "Vendor Bookings"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BookingHistoryList(isVendorView: false),
                BookingHistoryList(isVendorView: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingHistoryList extends StatefulWidget {
  final bool isVendorView;
  const BookingHistoryList({super.key, required this.isVendorView});

  @override
  State<BookingHistoryList> createState() => _BookingHistoryListState();
}

class _BookingHistoryListState extends State<BookingHistoryList> {
  DateFilter _selectedFilter = DateFilter.all;

  @override
  Widget build(BuildContext context) {
    final dateRange = getDateRange(_selectedFilter);

    final Query query = FirebaseFirestore.instance
        .collectionGroup("bookings")
        .where("eventDate", isGreaterThanOrEqualTo: dateRange.start)
        .where("eventDate", isLessThanOrEqualTo: dateRange.end)
        .orderBy("eventDate", descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error: [cloud_firestore/failed-precondition] ${snapshot.error}\n\nPlease ensure the required Collection Group index for 'bookings' on 'eventDate' (Descending) is created and enabled in your Firestore console.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allBookings =
            snapshot.data?.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList() ??
            [];

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            Center(
              child: DropdownButton<DateFilter>(
                value: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
                items: const [
                  DropdownMenuItem(
                    value: DateFilter.today,
                    child: Text("Today"),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.thisWeek,
                    child: Text("This Week"),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.thisMonth,
                    child: Text("This Month"),
                  ),
                  DropdownMenuItem(
                    value: DateFilter.all,
                    child: Text("All Time"),
                  ),
                ],
              ),
            ),

            HistorySummary(
              bookings: allBookings,
              isVendor: widget.isVendorView,
            ),

            if (allBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: Center(
                  child: Text(
                    "No history found for this period.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

            if (widget.isVendorView)
              ..._buildVendorGroupedList(allBookings)
            else
              ...allBookings.map((booking) => _buildBookingCard(booking)),
          ],
        );
      },
    );
  }

  List<Widget> _buildVendorGroupedList(List<Map<String, dynamic>> allBookings) {
    final Map<String, List<Map<String, dynamic>>> groupedBookings = {};
    for (var booking in allBookings) {
      final vendorName = booking['vendorName'] ?? 'Unknown Vendor';
      groupedBookings.putIfAbsent(vendorName, () => []).add(booking);
    }

    return groupedBookings.entries.map((entry) {
      return ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.store, color: Color(0xFF6A11CB)),
        title: Text("${entry.key} (${entry.value.length} bookings)"),
        children: entry.value
            .map((booking) => _buildBookingCard(booking))
            .toList(),
      );
    }).toList();
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final eventDate =
        (booking['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isVendorView
                  ? "Client: ${booking['userName'] ?? 'N/A'}"
                  : "Vendor: ${booking['vendorName'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text("Service: ${booking['serviceTitle'] ?? 'N/A'}"),
            Text("Event Date: ${DateFormat('dd MMM yyyy').format(eventDate)}"),
            Text("Advance Paid: ₹${booking['advancePayment'] ?? 0}"),
            Text("Status: ${booking['eventStatus'] ?? 'Upcoming'}"),
            if (!widget.isVendorView)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Booked by: ${booking['userName'] ?? 'N/A'}",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistorySummary extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final bool isVendor;

  const HistorySummary({
    super.key,
    required this.bookings,
    this.isVendor = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalBookings = bookings.length;
    final upcoming = bookings
        .where((o) => o['eventStatus'] != 'Completed')
        .length;
    final completed = bookings
        .where((o) => o['eventStatus'] == 'Completed')
        .length;
    final totalRevenue = bookings.fold<double>(
      0,
      (acc, o) => acc + (o['advancePayment'] ?? 0.0),
    );

    return GridView.count(
      crossAxisCount: 2,
      // --- FINAL FIX ---
      // Changed from 1.1 to 1.0 to make the cards square, providing enough height.
      childAspectRatio: 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildSummaryCard(
          "Total Bookings",
          totalBookings.toString(),
          Icons.list_alt,
          Colors.blue,
        ),
        _buildSummaryCard(
          isVendor ? "Total Revenue" : "Total Spent",
          "₹${totalRevenue.toStringAsFixed(0)}",
          Icons.monetization_on,
          Colors.teal,
        ),
        _buildSummaryCard(
          "Upcoming",
          upcoming.toString(),
          Icons.event_available,
          Colors.orange,
        ),
        _buildSummaryCard(
          "Completed",
          completed.toString(),
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}