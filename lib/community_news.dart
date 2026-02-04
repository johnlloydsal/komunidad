import 'package:flutter/material.dart';
import 'homepage.dart';
import 'profile.dart';

class CommunityNewsPage extends StatefulWidget {
  const CommunityNewsPage({super.key});

  @override
  State<CommunityNewsPage> createState() => _CommunityNewsPageState();
}

class _CommunityNewsPageState extends State<CommunityNewsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Community News tab is selected

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;

    Widget destination;
    if (index == 0) {
      destination = const HomePage();
    } else if (index == 1 || index == 2) {
      return; // Already on community news
    } else if (index == 3) {
      destination = const ProfilePage();
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  final List<NewsItem> allNews = [
    NewsItem(
      category: "Barangay",
      title: "Barangay Coming-Up Drive",
      source: "Source: Barangay Hall",
      date: "Nov 15, 2024 | 1 hour ago",
    ),
    NewsItem(
      category: "Advisory",
      title: "Severe Weather Alert Issued",
      source: "Source: Adv Clim",
      date: "Nov 15, 2024 | 1 hour ago",
    ),
    NewsItem(
      category: "Global",
      title: "Massive Corruption in The Philippines",
      source: "Source: News Daily",
      date: "Nov 15, 2024 | 1 hour ago",
    ),
    NewsItem(
      category: "Global",
      title: "Palestine vs. Israel News Updates",
      source: "Source: GNN News",
      date: "Nov 15, 2024 | 1 hour ago",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: const Text(
          "Community News",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4A00E0),
          labelColor: const Color(0xFF4A00E0),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Barangay"),
            Tab(text: "Events"),
            Tab(text: "Advisory"),
            Tab(text: "Security"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsList(allNews),
          _buildNewsList(
            allNews.where((item) => item.category == "Barangay").toList(),
          ),
          _buildNewsList([]),
          _buildNewsList(
            allNews.where((item) => item.category == "Advisory").toList(),
          ),
          _buildNewsList([]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: const Color(0xFF4A00E0),
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<NewsItem> news) {
    return news.isEmpty
        ? const Center(
            child: Text(
              "No news available",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.source,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

class NewsItem {
  final String category;
  final String title;
  final String source;
  final String date;

  NewsItem({
    required this.category,
    required this.title,
    required this.source,
    required this.date,
  });
}
