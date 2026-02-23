enum PlanType { starter, growth, pro }

class SubscriptionPlan {
  final PlanType type;
  final String name;
  final String description;
  final String price;
  final int productLimit;
  final int orderLimit;
  final bool hasReports;
  final bool hasSpecialSupport;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.productLimit,
    required this.orderLimit,
    required this.hasReports,
    required this.hasSpecialSupport,
  });

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      type: PlanType.starter,
      name: "البداية (Starter)",
      description: "التاجر المبتدئ (جرب قبل ما تشتري)",
      price: "مجاني",
      productLimit: 10,
      orderLimit: 30,
      hasReports: false,
      hasSpecialSupport: false,
    ),
    SubscriptionPlan(
      type: PlanType.growth,
      name: "النمو (Growth)",
      description: "التاجر المستقر (بيحتاج تنظيم)",
      price: "500 ج.م",
      productLimit: 50,
      orderLimit: -1, // Unlimited
      hasReports: true,
      hasSpecialSupport: false,
    ),
    SubscriptionPlan(
      type: PlanType.pro,
      name: "الاحترافية (Pro)",
      description: "المتاجر الكبيرة (Brand)",
      price: "1500 ج.م",
      productLimit: -1, // Unlimited
      orderLimit: -1, // Unlimited
      hasReports: true,
      hasSpecialSupport: true,
    ),
  ];

  static SubscriptionPlan fromString(String? planName) {
    if (planName == null) return plans[0];
    return plans.firstWhere(
      (p) => p.type.name == planName.toLowerCase(),
      orElse: () => plans[0],
    );
  }
}
