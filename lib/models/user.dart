class User {
  final int? userId;
  final String account;
  final String username;
  final String password;
  final String email;
  final String? phone;

  // ✅ 新增的布林欄位
  final bool newsCategorySubscription;
  final bool expertAnalysisSubscription;
  final bool weeklyReportSubscription;
  final bool fakeNewsAlert;
  final bool trendingTopicAlert;
  final bool expertResponseAlert;
  final bool privacyPolicyAgreed;

  User({
    this.userId,
    required this.account,
    required this.username,
    required this.password,
    required this.email,
    this.phone,
    this.newsCategorySubscription = false,
    this.expertAnalysisSubscription = false,
    this.weeklyReportSubscription = false,
    this.fakeNewsAlert = false,
    this.trendingTopicAlert = false,
    this.expertResponseAlert = false,
    this.privacyPolicyAgreed = false,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      account: map['account'],
      username: map['username'],
      password: map['password'] ?? '',
      email: map['email'],
      phone: map['phone'],
      newsCategorySubscription: map['news_category_subscription'] ?? false,
      expertAnalysisSubscription: map['expert_analysis_subscription'] ?? false,
      weeklyReportSubscription: map['weekly_report_subscription'] ?? false,
      fakeNewsAlert: map['fake_news_alert'] ?? false,
      trendingTopicAlert: map['trending_topic_alert'] ?? false,
      expertResponseAlert: map['expert_response_alert'] ?? false,
      privacyPolicyAgreed: map['privacy_policy_agreed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'account': account,
      'username': username,
      'password': password,
      'email': email,
      'phone': phone,
      'news_category_subscription': newsCategorySubscription,
      'expert_analysis_subscription': expertAnalysisSubscription,
      'weekly_report_subscription': weeklyReportSubscription,
      'fake_news_alert': fakeNewsAlert,
      'trending_topic_alert': trendingTopicAlert,
      'expert_response_alert': expertResponseAlert,
      'privacy_policy_agreed': privacyPolicyAgreed,
    };
  }

  Map<String, dynamic> toSafeMap() {
    return {
      'user_id': userId,
      'account': account,
      'username': username,
      'email': email,
      'phone': phone,
      'news_category_subscription': newsCategorySubscription,
      'expert_analysis_subscription': expertAnalysisSubscription,
      'weekly_report_subscription': weeklyReportSubscription,
      'fake_news_alert': fakeNewsAlert,
      'trending_topic_alert': trendingTopicAlert,
      'expert_response_alert': expertResponseAlert,
      'privacy_policy_agreed': privacyPolicyAgreed,
    };
  }
}
