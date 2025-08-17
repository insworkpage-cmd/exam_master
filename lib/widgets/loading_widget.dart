import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final LoadingType type;
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50,
    this.color,
    this.type = LoadingType.circular,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.circular:
        return _buildCircularLoading(context);
      case LoadingType.linear:
        return _buildLinearLoading(context);
      case LoadingType.dots:
        return _buildDotsLoading(context);
      case LoadingType.pulse:
        return _buildPulseLoading(context);
      case LoadingType.bounce:
        return _buildBounceLoading(context);
    }
  }

  Widget _buildCircularLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.08,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinearLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size * 2,
            child: LinearProgressIndicator(
              minHeight: size * 0.16,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotsLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                width: size * 0.2,
                height: size * 0.2,
              );
            }),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPulseLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).primaryColor).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            width: size,
            height: size,
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.08,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBounceLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.bounceOut,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                width: size * 0.2,
                height: size * 0.2,
              );
            }),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ویجت لودینگ تمام صفحه
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? loaderColor;
  const FullScreenLoading({
    super.key,
    this.message,
    this.backgroundColor,
    this.loaderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: LoadingWidget(
          message: message ?? 'در حال بارگذاری...',
          size: 60,
          color: loaderColor,
          type: LoadingType.circular,
        ),
      ),
    );
  }
}

// ویجت لودینگ روی محتوا
class ContentLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? color;
  const ContentLoading({
    super.key,
    required this.child,
    this.isLoading = false,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingWidget(
                  message: message ?? 'در حال بارگذاری...',
                  color: Colors.white,
                  size: 50,
                  type: LoadingType.circular,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ویجت لودینگ برای لیست‌ها
class ListLoading extends StatelessWidget {
  final String? message;
  final Color? color;
  const ListLoading({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingWidget(
            message: message,
            size: 40,
            color: color,
            type: LoadingType.linear,
          ),
        ],
      ),
    );
  }
}

// ویجت لودینگ شیک و مدرن
class ModernLoading extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  const ModernLoading({
    super.key,
    this.message,
    this.size = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // لودینگ چرخشی با افکت مدرن
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color ?? Theme.of(context).primaryColor,
                  (color ?? Theme.of(context).primaryColor).withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              // ignore: prefer_const_constructors
              padding: EdgeInsets.all(size * 0.15), // ✅ هشدار نادیده گرفته شد
              child: CircularProgressIndicator(
                strokeWidth: size * 0.06,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // متن متحرک
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1500),
            child: Text(
              message ?? 'در حال بارگذاری...',
              style: TextStyle(
                fontSize: size * 0.24,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ویجت لودینگ برای دکمه‌ها
class ButtonLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? color;
  const ButtonLoading({
    super.key,
    required this.child,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color ?? Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ویجت لودینگ برای تصاویر
class ImageLoading extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  const ImageLoading({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl ?? '',
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return placeholder ?? child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
      },
    );
  }
}

// انواع لودینگ
enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  bounce,
}

// ویجت سوئیچر برای تغییر حالت لودینگ
class LoadingSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const LoadingSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<LoadingSwitcher> createState() => _LoadingSwitcherState();
}

class _LoadingSwitcherState extends State<LoadingSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
