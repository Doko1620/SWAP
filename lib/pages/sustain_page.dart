import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class SustainabilityPage extends StatefulWidget {
  final String username;
  final String city;
  final double temperature;

  const SustainabilityPage({
    super.key,
    required this.username,
    required this.city,
    required this.temperature,
  });

  @override
  State<SustainabilityPage> createState() => _SustainabilityPageState();
}

class _SustainabilityPageState extends State<SustainabilityPage> {
  int? _userScore;

  final Color primaryColor = const Color(0xFF4A148C);
  final Color glassBorder = Colors.white.withOpacity(0.45);
  final Color glassBgTop = Colors.white.withOpacity(0.7);
  final Color glassBgBottom = Colors.white.withOpacity(0.28);

  @override
  void initState() {
    super.initState();
    _fetchUserScore(); 
  }

  Future<void> _fetchUserScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      debugPrint("No user logged in, cannot fetch score.");
      if (mounted) setState(() => _userScore = 0); // Default to 0 if no user
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Email', isEqualTo: user.email!)
          .limit(1)
          .get();

      if (mounted && querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _userScore = (userData['score'] as num?)?.toInt() ?? 0;
        });
      } else {
        if (mounted) setState(() => _userScore = 0); 
      }
    } catch (e) {
      debugPrint("Error fetching score: $e");
      if (mounted) setState(() => _userScore = 0); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 218, 202, 242),
              Color.fromARGB(255, 218, 202, 242),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _HeaderRow(
                    primaryColor: primaryColor,
                    city: widget.city, 
                    temperature: widget.temperature, 
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GlassContainer(
                    glassBgTop: glassBgTop,
                    glassBgBottom: glassBgBottom,
                    glassBorder: glassBorder,
                    child: _EcoScoreCard(
                      score: _userScore, 
                      primaryColor: primaryColor,
                    ),
                  ),
                ),
              ),


              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), 
                  child: _GlassContainer(
                    glassBgTop: glassBgTop,
                    glassBgBottom: glassBgBottom,
                    glassBorder: glassBorder,
                    child: _TipsCarousel(primaryColor: primaryColor),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    "Learn • Fast Fashion",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              SliverList.list(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _GlassContainer(
                      glassBgTop: glassBgTop,
                      glassBgBottom: glassBgBottom,
                      glassBorder: glassBorder,
                      child: _InfoSectionCard(
                        primaryColor: primaryColor,
                        title: "What is Fast Fashion?",
                        image: const AssetImage('assets/images/Neatly Organized Clothing Selection.png'),
                        children: const [
                          "Mass-produced, trend-driven clothing made quickly and cheaply.",
                          "Encourages frequent purchases, short wear cycles, and high waste.",
                          "Often linked to high water use, dye pollution, and carbon emissions.",
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _GlassContainer(
                      glassBgTop: glassBgTop,
                      glassBgBottom: glassBgBottom,
                      glassBorder: glassBorder,
                      child: _InfoSectionCard(
                        primaryColor: primaryColor,
                        title: "Environmental Impact",
                        image: const AssetImage('assets/images/Sunset Agricultural Scene with Solar Panels.png'),
                        children: const [
                          "Synthetic fibers (like polyester) are fossil-fuel based.",
                          "Dyes and treatments can pollute rivers and harm ecosystems.",
                          "Excess stock ends up in landfills or is incinerated.",
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "Build • Capsule Wardrobe",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _GlassContainer(
                    glassBgTop: glassBgTop,
                    glassBgBottom: glassBgBottom,
                    glassBorder: glassBorder,
                    child: _CapsuleWardrobeCard(primaryColor: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final Color primaryColor;
  final String city;
  final double temperature;

  const _HeaderRow({
    required this.primaryColor,
    required this.city,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.account_circle, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sustainability",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Row(
              children: [
                Text(
                  city,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(width: 5),
                Text(
                  ": ${temperature.round()} ℃",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final Color glassBgTop;
  final Color glassBgBottom;
  final Color glassBorder;

  const _GlassContainer({
    required this.child,
    required this.glassBgTop,
    required this.glassBgBottom,
    required this.glassBorder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [glassBgTop, glassBgBottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EcoScoreCard extends StatelessWidget {
  final int? score; 
  final Color primaryColor;

  const _EcoScoreCard({
    required this.score,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Your Eco Score",
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          score != null ? "$score / 100" : "...",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        
        
        const SizedBox(height: 10), 
      ],
    );
  }
}


class _TipsCarousel extends StatefulWidget {
  final Color primaryColor;
  const _TipsCarousel({required this.primaryColor});

  @override
  State<_TipsCarousel> createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<_TipsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _index = 0;

  final List<_TipItem> _items = const [
    _TipItem(
      title: "Shop Less, Style More",
      subtitle: "Rewear pieces in new combos to cut impact.",
      image: AssetImage('assets/images/Cozy Clothing Store.png'),
    ),
    _TipItem(
      title: "Seasonless Essentials",
      subtitle: "Choose fabrics that work across seasons.",
      image: AssetImage('assets/images/Elegant Boutique Display.png'),
    ),
    _TipItem(
      title: "Repair & Care",
      subtitle: "Mend tears, wash cool, and air dry.",
      image: AssetImage('assets/images/Artistic Depiction of Hanging Shirts.png'),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Tips",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: widget.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (_controller.position.haveDimensions) {
                    final page = _controller.page ?? _controller.initialPage.toDouble();
                    scale = (1 - (page - i).abs()).clamp(0.9, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _TipCard(item: item, primaryColor: widget.primaryColor),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _index == i ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _index == i
                    ? widget.primaryColor
                    : widget.primaryColor.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _TipItem {
  final String title;
  final String subtitle;
  final ImageProvider image;

  const _TipItem({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}

class _TipCard extends StatelessWidget {
  final _TipItem item;
  final Color primaryColor;

  const _TipCard({required this.item, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: item.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: Text(
                  "Image not found",
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.45),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final ImageProvider image;
  final List<String> children;
  final Color primaryColor;

  const _InfoSectionCard({
    required this.title,
    required this.image,
    required this.children,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image(image: image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: primaryColor,
            collapsedIconColor: primaryColor,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
            children: [
              const SizedBox(height: 8),
              ...children.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: primaryColor.withOpacity(0.9)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapsuleWardrobeCard extends StatefulWidget {
  final Color primaryColor;
  const _CapsuleWardrobeCard({required this.primaryColor});

  @override
  State<_CapsuleWardrobeCard> createState() => _CapsuleWardrobeCardState();
}

class _CapsuleWardrobeCardState extends State<_CapsuleWardrobeCard> {
  final List<String> topTypes = const [
    "T-shirt",
    "Shirt",
    "Knit",
    "Blouse",
    "Jacket",
  ];

  final List<String> bottomTypes = const [
    "Jeans",
    "Chinos",
    "Tailored Trousers",
    "Shorts",
    "Skirt",
  ];

  final List<String> baseColors5 = const ["Black", "White", "Navy", "Grey", "Beige"];

  final List<String> shoeColors3 = const ["White", "Black", "Brown"];

  final Set<String> selectedTopTypes = {"T-shirt"};
  final Set<String> selectedTopColors = {"White"};

  final Set<String> selectedBottomTypes = {"Jeans"};
  final Set<String> selectedBottomColors = {"Black"};

  final Set<String> selectedShoeColors = {"White"};

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.primaryColor;

    final int totalItems =
        topTypes.length + baseColors5.length + bottomTypes.length + baseColors5.length + shoeColors3.length;

    final int selectedCount =
        selectedTopTypes.length +
        selectedTopColors.length +
        selectedBottomTypes.length +
        selectedBottomColors.length +
        selectedShoeColors.length;

    final double readiness = selectedCount / totalItems;

    Widget _sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        );

    Widget _chipWrap({
      required Iterable<String> items,
      required Set<String> selectedSet,
    }) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((e) {
          final bool isOn = selectedSet.contains(e);
          return FilterChip(
            label: Text(
              e,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isOn ? Colors.white : Colors.black87,
              ),
            ),
            selected: isOn,
            onSelected: (v) {
              setState(() {
                if (v) {
                  selectedSet.add(e);
                } else {
                  selectedSet.remove(e);
                }
              });
            },
            backgroundColor: Colors.white.withOpacity(0.7),
            selectedColor: primaryColor.withOpacity(0.9),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isOn ? primaryColor : Colors.black12,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Start Small, Wear More",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image(
              image: const AssetImage('assets/images/Impeccably Organized Wardrobe.png'),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: Text(
                    "Image not found",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Pick versatile pieces by type and neutral colors. Aim for 7–12 items that mix & match across occasions.",
          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black87, height: 1.38),
        ),

        _sectionTitle("Tops • types"),
        _chipWrap(items: topTypes, selectedSet: selectedTopTypes),
        _sectionTitle("Tops • 5 basic colors"),
        _chipWrap(items: baseColors5, selectedSet: selectedTopColors),

        _sectionTitle("Bottoms • types"),
        _chipWrap(items: bottomTypes, selectedSet: selectedBottomTypes),
        _sectionTitle("Bottoms • 5 basic colors"),
        _chipWrap(items: baseColors5, selectedSet: selectedBottomColors),

        _sectionTitle("Shoes • 3 basic colors"),
        _chipWrap(items: shoeColors3, selectedSet: selectedShoeColors),

        const SizedBox(height: 12),
        _ProgressRow(
          title: "Your capsule readiness",
          value: readiness,
          primaryColor: primaryColor,
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final Color primaryColor;

  const _ProgressRow({
    required this.title,
    required this.value,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title   •   $pct%",
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withOpacity(0.45),
            valueColor: AlwaysStoppedAnimation(primaryColor),
          ),
        ),
      ],
    );
  }
}


// ignore: unused_element
class _CTA extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onPressed;

  const _CTA({
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.trending_up, color: primaryColor, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Plan your 7-day re-wear challenge\nand boost your Eco Score!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: onPressed,
          child: Text(
            "Start",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}