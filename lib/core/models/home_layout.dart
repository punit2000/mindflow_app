/// Identifies the top-level tabs that can be shown on the home screen.
enum HomeTab {
  reminders('Reminders', 'reminders'),
  notes('Notes', 'notes'),
  library('Library', 'library');

  const HomeTab(this.label, this.storageId);

  final String label;
  final String storageId;

  static HomeTab fromStorageId(String id) {
    return HomeTab.values.firstWhere(
      (t) => t.storageId == id,
      orElse: () => HomeTab.reminders,
    );
  }
}

/// Serializable home layout: the order of visible tabs and the list of tabs
/// the user has hidden (pinned tabs are simply the first ones in [order]).
class HomeLayout {
  final List<HomeTab> order;
  final List<HomeTab> hidden;

  const HomeLayout({required this.order, this.hidden = const []});

  factory HomeLayout.defaultLayout() {
    return const HomeLayout(order: [HomeTab.reminders, HomeTab.notes, HomeTab.library]);
  }

  List<HomeTab> get visibleTabs => order;

  bool isVisible(HomeTab tab) => order.contains(tab) && !hidden.contains(tab);

  HomeLayout copyWith({List<HomeTab>? order, List<HomeTab>? hidden}) {
    return HomeLayout(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, dynamic> toJson() => {
        'order': order.map((t) => t.storageId).toList(),
        'hidden': hidden.map((t) => t.storageId).toList(),
      };

  factory HomeLayout.fromJson(Map<String, dynamic> json) {
    final order = (json['order'] as List<dynamic>?)
            ?.map((e) => HomeTab.fromStorageId(e.toString()))
            .toList() ??
        const <HomeTab>[];
    final hidden = (json['hidden'] as List<dynamic>?)
            ?.map((e) => HomeTab.fromStorageId(e.toString()))
            .toList() ??
        const <HomeTab>[];
    if (order.isEmpty) return HomeLayout.defaultLayout();
    return HomeLayout(order: order, hidden: hidden);
  }
}