import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/widgets/app_drawer.dart';
import 'package:customer_app/features/active_orders/presentation/widgets/active_orders_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final statusPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 180,
            collapsedHeight: 65 + statusPadding,
            scrolledUnderElevation: 0.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double top = constraints.biggest.height;
                final double expandedHeight = 180;
                final double collapsedHeight = 65 + statusPadding;
                final double t =
                    ((top - collapsedHeight) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // S-Shape Background
                    ClipPath(
                      clipper: SShapeClipper(progress: t),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentRedDeep,
                              AppColors.primary,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Header Content
                    _buildHeaderContent(context, homeState, t, statusPadding),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.semanticGrayNeutralBgWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 20),
                  child: Column(
                    children: [
                      const ActiveOrdersBanner(),
                      _buildServiceGrid(context),
                      // Hardcoded promo/restaurant sections with fake ids — see
                      // FeatureFlags.foodHomePromoSections. Hidden until wired
                      // to the discovery feed.
                      if (FeatureFlags.foodHomePromoSections) ...[
                        _buildPromoBanner(context),
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          context,
                          title: 'เมนูลด 60%',
                          emoji: '🔥',
                        ),
                        _buildHorizontalFoodList(context),
                        const SizedBox(height: 20),
                        _buildPromoCodeCard(context),
                        const SizedBox(height: 20),
                        _buildSectionHeader(context, title: 'ร้านยอดนิยม'),
                        _buildHorizontalRestaurantList(context),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    HomeState homeState,
    double t,
    double statusPadding,
  ) {
    // t = 1.0 (expanded), t = 0.0 (collapsed)
    final double topNavOpacity = (t - 0.6).clamp(0.0, 1.0) / 0.4;

    // Calculate vertical centering for search bar when collapsed
    // Collapsed height is 56 (excluding statusPadding)
    // Search bar height is 48
    // Center offset = (56 - 48) / 2 = 4
    final double searchBarTopCollapsed = statusPadding + 4;
    final double searchBarTopExpanded = statusPadding + 80;
    final double currentSearchBarTop =
        searchBarTopCollapsed +
        (t * (searchBarTopExpanded - searchBarTopCollapsed) - 20);

    return Stack(
      children: [
        // Expanded Elements (Top Nav) - Hides when scrolling up
        Positioned(
          top: statusPadding + 10,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: topNavOpacity,
            child: _buildTopNav(context, homeState),
          ),
        ),

        // Search Bar Area - Moves to center vertically when collapsed
        Positioned(
          top: currentSearchBarTop,
          left: 16,
          right: 16,
          child: _buildSearchBar(t),
        ),
      ],
    );
  }

  Widget _buildTopNav(BuildContext context, HomeState homeState) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/food-place-search'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AppIcons.asset(
                  AppAssets.icLocationFill,
                  color: AppColors.semanticGrayNeutralBgWhite,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกสถานที่จัดส่ง',
                        style: AppTypography.caption4.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              homeState.foodAddress ?? 'โปรดเลือกสถานที่',
                              style: AppTypography.label2.copyWith(
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildCircularButton(Icons.favorite_border_sharp),
      ],
    );
  }

  Widget _buildSearchBar(double t) {
    return GestureDetector(
      onTap: () => context.push('/item-search'),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF0038A8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'สั่งอะไรดี?',
                style: AppTypography.caption3.copyWith(color: Colors.black54),
              ),
            ),
            if (t > 0.6) ...[
              Container(
                height: 24,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.tune, color: Color(0xFF0038A8), size: 22),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildServiceCard(
            context,
            'เรียกรถ',
            'เรียกครั้งแรก',
            'ลด ฿100*',
            Colors.red,
            Icons.directions_car,
            AppColors.foundationBlue800,
            AppColors.foundationBlue100,
            onTap: () {
              context.push('/ride-landing');
              // ref
              //     .read(homeControllerProvider.notifier)
              //     .startSelection(mode: RideSelectionMode.dropoff);
            },
          ),
          _buildServiceCard(
            context,
            'สั่งอาหาร',
            'ถูกสุดทุกวัน',
            'ลด ฿100*',
            Colors.red,
            Icons.fastfood,
            AppColors.foundationGreen800,
            AppColors.foundationGreen100,
            onTap: () {
              context.push('/food-delivery');
              // ref
              //     .read(homeControllerProvider.notifier)
              //     .startSelection(mode: RideSelectionMode.dropoff);
            },
          ),
          // _buildServiceCard(
          //   context,
          //   'สั่งของ',
          //   'ครบ โค้ดเยอะ ส่งฟรี*',
          //   'ลด ฿400*',
          //   Colors.orange,
          //   Icons.shopping_bag,
          //   AppColors.foundationOrange800,
          //   AppColors.foundationOrange100,
          // ),
          _buildServiceCard(
            context,
            'เมสเซนเจอร์',
            'ส่งของ พัสดุ',
            null,
            null,
            Icons.delivery_dining,
            AppColors.foundationViolet800,
            AppColors.foundationViolet100,
            onTap: () {
              context.push('/messenger-booking');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String subtitle,
    String? promo,
    Color? promoColor,
    IconData icon,
    Color iconColor,
    Color iconBgColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption4.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (promo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (promoColor ?? Colors.red).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        promo,
                        style: AppTypography.caption5.copyWith(
                          color: promoColor ?? Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, size: 28, color: iconColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'โปรคุ้มตลอดวัน',
                  style: AppTypography.label3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'โดนัท AFTER YOU 3 ชิ้น + พอน เดอ ริง 3 ชิ้น...',
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '฿159',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? emoji,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: AppTypography.heading4.copyWith(
              color: const Color(0xFF1C1B1B),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.push(
              Uri(
                path: '/category-list',
                queryParameters: {'title': title},
              ).toString(),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  'ดูทั้งหมด',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  size: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFoodList(BuildContext context) {
    final items = [
      _RecommendationItem(
        id: 'r2',
        title: 'ไข่หมึกทอดราดน้ำ...',
        subtitle: 'เฮงหอยทอดชาวเล - ต...',
        price: '฿119',
        oldPrice: '฿169',
        rating: '4.8',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
      ),
      _RecommendationItem(
        id: 'r3',
        title: 'ชุดรวมมิตรหมู(ให...',
        subtitle: 'เรือนเพชรสุกี้ - ถนนเลี่...',
        price: '฿379',
        oldPrice: '฿552',
        rating: '4.8',
        deliveryFee: '฿14',
        image:
            'https://images.unsplash.com/photo-1547825407-2d060104b7f8?w=400',
      ),
    ];

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildFoodCard(context, items[index]),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, _RecommendationItem item) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${item.id}'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                item.image,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.subtitle,
                    style: AppTypography.caption5.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(item.deliveryFee, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating, style: AppTypography.caption5),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.price != null)
                        Text(
                          item.price!,
                          style: AppTypography.label3.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (item.oldPrice != null)
                        Text(
                          item.oldPrice!,
                          style: AppTypography.caption5.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalRestaurantList(BuildContext context) {
    final items = [
      _RecommendationItem(
        id: 'r1',
        title: 'ไก่ทอด ขีดละ 35 - บาง...',
        subtitle: '31 นาที',
        rating: '3.9',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=400',
      ),
      _RecommendationItem(
        id: 'r4',
        title: 'ติดแซ่บ หมูปิ้ง ข้าวเหนี...',
        subtitle: '37 นาที',
        rating: '4.7',
        deliveryFee: '฿0',
        image:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=400',
      ),
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _buildRestaurantCard(context, items[index]),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, _RecommendationItem item) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${item.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                item.image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(item.deliveryFee, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      Text(item.subtitle, style: AppTypography.caption5),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating, style: AppTypography.caption5),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ใส่โค้ด "LINEMAN"',
                  style: AppTypography.label3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ลดสูงสุด 50%* ไม่มีขั้นต่ำ',
                  style: AppTypography.caption5.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

class SShapeClipper extends CustomClipper<Path> {
  final double progress;

  SShapeClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    // When progress is 0 (collapsed), we want a flatter curve
    // When progress is 1 (expanded), we want a more pronounced S-shape
    final double curveHeight = 30.0 * progress;

    path.lineTo(0, size.height - curveHeight);

    // Smooth S-shape using two quadratic beziers or one cubic
    // We'll use cubic for a more elegant S-flow
    path.cubicTo(
      size.width * 0.3,
      size.height + curveHeight * 1.2, // Dip down on the left
      size.width * 0.7,
      size.height - curveHeight * 2.5, // Arch up on the right
      size.width,
      size.height - curveHeight * 0.8, // End point
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant SShapeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _RecommendationItem {
  final String id;
  final String title;
  final String subtitle;
  final String? price;
  final String? oldPrice;
  final String rating;
  final String deliveryFee;
  final String image;

  _RecommendationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.price,
    this.oldPrice,
    required this.rating,
    required this.deliveryFee,
    required this.image,
  });
}
