Widget _buildAnalytics() {
  return Column(
    children: [
      Expanded(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('analytics').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> analyticsSnapshot) {
            if (analyticsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!analyticsSnapshot.hasData || analyticsSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No analytics data"));
            }

            return StreamBuilder(
              stream: FirebaseFirestore.instance.collection('globalAnalytics').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> globalAnalyticsSnapshot) {
                if (globalAnalyticsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!globalAnalyticsSnapshot.hasData || globalAnalyticsSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No global analytics data"));
                }

                // Aggregate data for analytics collection
                Map<String, Map<String, int>> aggregatedData = {};
                int totalUsersCount = 0;
                int totalRequestsCount = 0;

                for (var doc in analyticsSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String tableId = data['tableId'] ?? 'Unknown';
                  int requestCount = data['requestCount'] ?? 0;
                  int usersCount = data['usersCount'] ?? 0;

                  if (!aggregatedData.containsKey(tableId)) {
                    aggregatedData[tableId] = {'requestCount': 0, 'usersCount': 0};
                  }

                  aggregatedData[tableId]!['requestCount'] =
                      (aggregatedData[tableId]!['requestCount'] ?? 0) + requestCount;
                  aggregatedData[tableId]!['usersCount'] =
                      (aggregatedData[tableId]!['usersCount'] ?? 0) + usersCount;

                  totalRequestsCount += requestCount;
                  totalUsersCount += usersCount;
                }

                List<_ChartData> requestData = aggregatedData.entries.map((entry) {
                  return _ChartData(entry.key, entry.value['requestCount']!);
                }).toList();

                // Aggregate data for globalAnalytics collection
                List<_ChartData> requestTypeData = [];
                for (var doc in globalAnalyticsSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String requestType = data['requestType'] ?? 'Unknown';
                  int requestTypeCount = data['requestTypeCount'] ?? 0;

                  requestTypeData.add(_ChartData(requestType, requestTypeCount));
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Display Total Counts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Total Requests
                          Container(
                            width: 200,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$totalRequestsCount",
                                  style: const TextStyle(
                                      fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const Text(
                                  "Total Requests",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          // Total Users
                          Container(
                            width: 200,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$totalUsersCount",
                                  style: const TextStyle(
                                      fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Text(
                                  "Total Users",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Request Count by Table",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 300,
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(),
                          series: <ChartSeries>[
                            ColumnSeries<_ChartData, String>(
                              dataSource: requestData,
                              xValueMapper: (_ChartData data, _) => data.tableId,
                              yValueMapper: (_ChartData data, _) => data.count,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Request Type",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 300,
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(),
                          series: <ChartSeries>[
                            ColumnSeries<_ChartData, String>(
                              dataSource: requestTypeData,
                              xValueMapper: (_ChartData data, _) => data.tableId,
                              yValueMapper: (_ChartData data, _) => data.count,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}
