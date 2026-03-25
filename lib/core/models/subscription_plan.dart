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
      name: "Starter",
      description: "Beginner Merchant (Try before you buy)",
      price: "Free",
      productLimit: 10,
      orderLimit: 20,
      hasReports: false,
      hasSpecialSupport: true,
    ),
    SubscriptionPlan(
      type: PlanType.growth,
      name: "Growth",
      description: "Established Merchant (Needs organization)",
      price: "300 EGP",
      productLimit: 20,
      orderLimit: -1, // Unlimited
      hasReports: true,
      hasSpecialSupport: true,
    ),
    SubscriptionPlan(
      type: PlanType.pro,
      name: "Pro",
      description: "Large Stores (Brand)",
      price: "500 EGP",
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
