// For ImageFilter
import 'package:flutter/material.dart';
import 'package:travel_visionary/widgets/full_screen_image_view.dart'; // Import the new widget

class FeaturedCard extends StatefulWidget {
  // Changed to StatefulWidget
  final String destination;
  const FeaturedCard({super.key, required this.destination});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  // State class
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false, // Important for transparent background
              pageBuilder: (BuildContext context, _, __) {
                return FullScreenImageView(
                  destination: widget.destination,
                ); // Use widget.destination
              },
              transitionsBuilder: (
                ___,
                Animation<double> animation,
                ____,
                Widget child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: Card(
          elevation: _isHovering ? 12 : 4, // Increased elevation on hover
          shadowColor:
              _isHovering
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Colors.black54, // Glow effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            // width: 160, // Removed fixed width to allow GridView to size it
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(
                  'assets/home/${widget.destination}.jpg', // Use widget.destination
                ), // Use destination name for image
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Colors.black26,
                  BlendMode.darken,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.destination, // Use widget.destination
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
