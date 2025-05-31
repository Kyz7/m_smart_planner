import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final int count;
  final EdgeInsets? padding;
  final double? height;

  const LoadingShimmer({
    Key? key,
    this.count = 3,
    this.padding,
    this.height,
  }) : super(key: key);

  @override
  _LoadingShimmerState createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.count,
        (index) => Padding(
          padding: widget.padding ?? EdgeInsets.only(bottom: 16),
          child: ShimmerPlaceCard(
            animation: _animation,
            height: widget.height,
          ),
        ),
      ),
    );
  }
}

class ShimmerPlaceCard extends StatelessWidget {
  final Animation<double> animation;
  final double? height;

  const ShimmerPlaceCard({
    Key? key,
    required this.animation,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height ?? 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: _createShimmerGradient(),
                ),
              ),
              
              // Content placeholder
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: _createShimmerGradient(),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Subtitle placeholder
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: _createShimmerGradient(),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Rating and price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating placeholder
                        Container(
                          height: 16,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: _createShimmerGradient(),
                          ),
                        ),
                        
                        // Price placeholder
                        Container(
                          height: 18,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: _createShimmerGradient(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Description placeholder
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: _createShimmerGradient(),
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

  LinearGradient _createShimmerGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [
        animation.value - 1,
        animation.value,
        animation.value + 1,
      ].where((stop) => stop >= 0.0 && stop <= 1.0).toList(),
      colors: [
        Colors.grey.shade300,
        Colors.grey.shade100,
        Colors.grey.shade300,
      ].take(3).toList(),
    );
  }
}

// Alternative simpler shimmer widget if you prefer
class SimpleLoadingShimmer extends StatelessWidget {
  final int count;
  final EdgeInsets? padding;

  const SimpleLoadingShimmer({
    Key? key,
    this.count = 3,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: padding ?? EdgeInsets.only(bottom: 16),
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                
                // Content placeholder
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 200,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 16,
                            width: 80,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            height: 18,
                            width: 60,
                            color: Colors.grey.shade300,
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
      ),
    );
  }
}