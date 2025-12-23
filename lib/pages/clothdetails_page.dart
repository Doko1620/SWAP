import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:swap/components/toast.dart';

class ClothDetailsPage extends StatefulWidget {
  final String userDocId;
  final String clothId;
  final Map<String, dynamic> clothData;

  const ClothDetailsPage({
    super.key,
    required this.userDocId,
    required this.clothId,
    required this.clothData,
  });

  @override
  State<ClothDetailsPage> createState() => _ClothDetailsState();
}

class _ClothDetailsState extends State<ClothDetailsPage> {
  final Color primaryColor = const Color(0xFF4A148C);
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastHelper.init(context);
    });
  }

  Future<void> _updateUserEcoScore() async {
    try {
      final clothesSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userDocId)
          .collection("clothes")
          .get();

      if (clothesSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userDocId)
            .update({"score": 0});
        return;
      }

      double totalScore = 0;
      double maxScore = clothesSnapshot.docs.length * 25;

      for (var doc in clothesSnapshot.docs) {
        final data = doc.data();
        final material = data["material"]?.toString() ?? "";

        const sustainableMaterials = {
          "Cotton",
          "Wool",
          "Linen",
          "Silk",
        };

        final itemScore =
            sustainableMaterials.contains(material) ? 25 : 10;

        totalScore += itemScore;
      }

      final percentage = (totalScore / maxScore) * 100;
      final finalScore = percentage.round();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userDocId)
          .update({"score": finalScore});
    } catch (e) {
      debugPrint("Eco Score Update Error: $e");
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Cloth"),
        content: const Text("Are you sure you want to delete this cloth?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteCloth();
    }
  }

  Future<void> _deleteCloth() async {
    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userDocId)
          .collection("clothes")
          .doc(widget.clothId)
          .delete();

      final url = widget.clothData["imageUrl"];
      if (url != null && url.toString().isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          debugPrint("⚠️ Could not delete image: $e");
        }
      }

      await _updateUserEcoScore();

      if (mounted) {
        ToastHelper.showToast(
          message: "Cloth deleted successfully",
          backgroundColor: primaryColor.withValues(alpha: 0.5),
          icon: Icons.delete_forever,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(
          message: "Error: $e",
          backgroundColor: Colors.red.withOpacity(0.8),
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloth = widget.clothData;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color(0xFFF9F7FC),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImagePage(
                            imageUrl: cloth["imageUrl"] ?? "",
                            tag: widget.clothId,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: widget.clothId,
                      child: Image.network(
                        cloth["imageUrl"] ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(cloth["name"] ?? "Unnamed",
                          style: GoogleFonts.poppins(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildInfoTile("Type", cloth["type"] ?? "-", Icons.category),
                          _buildInfoTile("Subcategory", cloth["subcategory"] ?? "-", Icons.label),
                          _buildInfoTile("Shade", cloth["shade"] ?? "-", Icons.brightness_low),
                          _buildInfoTile("Color", cloth["color"] ?? "-", Icons.color_lens),
                          _buildInfoTile("Material", cloth["material"] ?? "-", Icons.texture),
                          _buildInfoTile("Formality", cloth["formality"] ?? "-", Icons.work),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),

        Positioned(
          top: 40,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        Positioned(
          top: 40,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white, size: 26),
              onPressed: _confirmDelete,
            ),
          ),
        ),

        if (_isDeleting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: SpinKitDoubleBounce(
                color: Color(0xFF4D2C6F),
                size: 60.0,
              ),
            ),
          ),
      ],
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 12) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Hero(
            tag: tag,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
