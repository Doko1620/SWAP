import 'dart:ui'; 
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap/components/toast.dart'; 

class ClothItem {
 final String id;
 final String name;
 final String imageUrl;
 final String type; 

 ClothItem({
   required this.id,
   required this.name,
   required this.imageUrl,
   required this.type,
 });

 factory ClothItem.fromFirestore(DocumentSnapshot doc) {
   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
   return ClothItem(
     id: doc.id,
     name: data['name'] ?? 'Unnamed',
     imageUrl: data['imageUrl'] ?? '', // Handle missing URL
     type: data['type'] ?? 'Unknown',
   );
 }
}


class OutfitSuggestionPage extends StatefulWidget {
 final String username;
 final String city;
 final double temperature;

 const OutfitSuggestionPage({
   super.key,
   required this.username,
   required this.city,
   required this.temperature,
 });

 @override
 State<OutfitSuggestionPage> createState() => _OutfitSuggestionPageState();
}

class _OutfitSuggestionPageState extends State<OutfitSuggestionPage> {
 final Color primaryColor = const Color(0xFF4A148C);
 final Color accentColor = const Color(0xFFE1BEE7); 

 String? userDocId;
 bool _isLoading = true;
 String _loadingMessage = "Loading wardrobe...";

 List<ClothItem> tops = [];
 List<ClothItem> pants = [];
 List<ClothItem> shoes = [];

 final PageController _topsController = PageController(viewportFraction: 0.5);
 final PageController _pantsController = PageController(viewportFraction: 0.5);
 final PageController _shoesController = PageController(viewportFraction: 0.5);

 int _topIndex = -1; 
 int _pantIndex = -1;
 int _shoeIndex = -1;

 final Random _random = Random(); 

 @override
 void initState() {
   super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
     if (mounted) {
       ToastHelper.init(context);
     }
     _fetchUserAndClothes();
   });
 }

 @override
 void dispose() {
   _topsController.dispose();
   _pantsController.dispose();
   _shoesController.dispose();
   super.dispose();
 }

 Future<void> _fetchUserAndClothes() async {
   final user = FirebaseAuth.instance.currentUser;
   if (user == null || user.email == null) {
     if (mounted) setState(() { _isLoading = false; _loadingMessage = "Error: Not logged in."; });
     return;
   }

   try {
     final querySnapshot = await FirebaseFirestore.instance
         .collection('users')
         .where('Email', isEqualTo: user.email!)
         .limit(1)
         .get();

     if (querySnapshot.docs.isEmpty) {
       throw Exception("User document not found.");
     }
     userDocId = querySnapshot.docs.first.id;

     if (mounted) setState(() { _loadingMessage = "Fetching clothes..."; });

     final clothesSnapshot = await FirebaseFirestore.instance
         .collection('users')
         .doc(userDocId)
         .collection('clothes')
         .orderBy('createdAt', descending: true)
         .get();

     tops.clear();
     pants.clear();
     shoes.clear();

     for (var doc in clothesSnapshot.docs) {
       final item = ClothItem.fromFirestore(doc);
       if (item.imageUrl.isNotEmpty) { 
            if (item.type == "Shirts/Tops") {
            tops.add(item);
            } else if (item.type == "Pants") {
            pants.add(item);
            } else if (item.type == "Shoes") {
            shoes.add(item);
            }
       }
     }

     _topIndex = tops.isNotEmpty ? 0 : -1;
     _pantIndex = pants.isNotEmpty ? 0 : -1;
     _shoeIndex = shoes.isNotEmpty ? 0 : -1;


     if (mounted) {
       setState(() {
         _isLoading = false;
         _loadingMessage = ""; 
       });
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (_topsController.hasClients && _topIndex != -1) _topsController.jumpToPage(_topIndex);
           if (_pantsController.hasClients && _pantIndex != -1) _pantsController.jumpToPage(_pantIndex);
           if (_shoesController.hasClients && _shoeIndex != -1) _shoesController.jumpToPage(_shoeIndex);
        });
     }

   } catch (e) {
     debugPrint("Error fetching user/clothes: $e");
     if (mounted) {
       setState(() {
         _isLoading = false;
         _loadingMessage = "Error loading wardrobe: $e";
       });
       ToastHelper.showToast(message: "Error loading wardrobe: $e", backgroundColor: Colors.red);
     }
   }
 }

 void _randomizeOutfit() {
    if (tops.isEmpty && pants.isEmpty && shoes.isEmpty) {
        ToastHelper.showToast(message: "Wardrobe is empty!", backgroundColor: Colors.orange);
        return;
    }

    int newTopIndex = _topIndex;
    int newPantIndex = _pantIndex;
    int newShoeIndex = _shoeIndex;

    if (tops.isNotEmpty) {
        newTopIndex = _random.nextInt(tops.length);
    }
    if (pants.isNotEmpty) {
        newPantIndex = _random.nextInt(pants.length);
    }
    if (shoes.isNotEmpty) {
        newShoeIndex = _random.nextInt(shoes.length);
    }

    setState(() {
        _topIndex = newTopIndex;
        _pantIndex = newPantIndex;
        _shoeIndex = newShoeIndex;
    });

    if (_topsController.hasClients && newTopIndex != -1) {
        _topsController.animateToPage(
            newTopIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
        );
    }
     if (_pantsController.hasClients && newPantIndex != -1) {
        _pantsController.animateToPage(
            newPantIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
        );
    }
     if (_shoesController.hasClients && newShoeIndex != -1) {
        _shoesController.animateToPage(
            newShoeIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
        );
    }
 }

 @override
 Widget build(BuildContext context) {
   final ClothItem? currentTop = (tops.isNotEmpty && _topIndex >= 0 && _topIndex < tops.length) ? tops[_topIndex] : null;
   final ClothItem? currentPant = (pants.isNotEmpty && _pantIndex >= 0 && _pantIndex < pants.length) ? pants[_pantIndex] : null;
   final ClothItem? currentShoe = (shoes.isNotEmpty && _shoeIndex >= 0 && _shoeIndex < shoes.length) ? shoes[_shoeIndex] : null;

   return Scaffold(
     backgroundColor: const Color.fromARGB(255, 240, 235, 248), // Lighter purple background
     body: SafeArea(
       child: Column(
         children: [
           _buildHeader(),

           if (_isLoading)
             Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: primaryColor), const SizedBox(height: 15), Text(_loadingMessage, style: GoogleFonts.poppins())]))),

           if (!_isLoading && tops.isEmpty && pants.isEmpty && shoes.isEmpty)
             Expanded(child: Center(child: Text("Your wardrobe is empty!\nAdd clothes via the Upload tab.", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])))),

           if (!_isLoading && (tops.isNotEmpty || pants.isNotEmpty || shoes.isNotEmpty))
             Expanded(
               child: SingleChildScrollView(
                 child: Column(
                   children: [
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                       child: Container(
                         padding: const EdgeInsets.all(12.0),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.6),
                           borderRadius: BorderRadius.circular(24),
                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 5))]
                         ),
                         child: Column(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               _buildSelectedItemPreview(currentTop, "Top"),
                               Divider(color: primaryColor.withOpacity(0.1), thickness: 1, height: 1),
                               _buildSelectedItemPreview(currentPant, "Pants"),
                               Divider(color: primaryColor.withOpacity(0.1), thickness: 1, height: 1),
                               _buildSelectedItemPreview(currentShoe, "Shoes"),
                             ],
                         ),
                       ),
                     ),

                     Container(
                       padding: const EdgeInsets.only(top: 15, bottom: 10),
                       child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: [
                             _buildCategorySwiper("Tops", tops, _topsController, _topIndex),
                             const SizedBox(height: 10), 
                             _buildCategorySwiper("Pants", pants, _pantsController, _pantIndex),
                             const SizedBox(height: 10), 
                             _buildCategorySwiper("Shoes", shoes, _shoesController, _shoeIndex),
                           ],
                       ),
                     ),

                     Padding(
                         padding: const EdgeInsets.only(bottom: 20.0, top: 15.0),
                         child: ElevatedButton.icon(
                             onPressed: _isLoading ? null : _randomizeOutfit, 
                             icon: Icon(Icons.shuffle, color: Colors.white, size: 24), 
                             label: Text("Randomize", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                             style: ElevatedButton.styleFrom(
                                 backgroundColor: primaryColor,
                                 padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                 elevation: 6,
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
   );
 }


 Widget _buildHeader() {
   return Padding(
     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       crossAxisAlignment: CrossAxisAlignment.start, 
       children: [
         Row(
           children: [
             CircleAvatar(
               radius: 22,
               backgroundColor: primaryColor.withOpacity(0.1),
               child: Icon(Icons.auto_awesome, color: primaryColor, size: 28), 
             ),
             const SizedBox(width: 12),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("Outfit Studio",
                     style: GoogleFonts.poppins(
                         fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                 Text("Create your look",
                     style: GoogleFonts.poppins(
                         fontSize: 14, color: Colors.grey[700])),
               ],
             ),
           ],
         ),
         Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                Text(widget.city, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor)),
                Text("${widget.temperature.round()} °C", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
            ],
         )
       ],
     ),
   );
 }

 Widget _buildSelectedItemPreview(ClothItem? item, String categoryName) {
    return SizedBox( 
      height: 85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                width: 65, 
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2))
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: item?.imageUrl != null && item!.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                           loadingBuilder: (context, child, loadingProgress) =>
                               loadingProgress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryColor)),
                           errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 25),
                        )
                      : Center(child: Icon(Icons.add_circle_outline, color: primaryColor.withOpacity(0.5), size: 30)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.name ?? 'Select $categoryName',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: item != null ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                   if (item != null)
                     Text(
                        categoryName,
                        style: GoogleFonts.poppins(
                           fontSize: 12,
                           color: Colors.grey[600],
                        ),
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
 }

 Widget _buildCategorySwiper(String title, List<ClothItem> items, PageController controller, int currentIndex) {
   if (items.isEmpty) {
     return Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        alignment: Alignment.center,
        child: Text("No ${title.toLowerCase()} added", style: GoogleFonts.poppins(color: Colors.grey)),
     );
   }

   return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 5),
                child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: primaryColor.withOpacity(0.9))),
            ),
            Container(
                height: 85, 
                child: PageView.builder(
                    controller: controller,
                    itemCount: items.length,
                    onPageChanged: (index) {
                        if (controller == _topsController && mounted) setState(() => _topIndex = index);
                        else if (controller == _pantsController && mounted) setState(() => _pantIndex = index);
                        else if (controller == _shoesController && mounted) setState(() => _shoeIndex = index);
                    },
                    itemBuilder: (context, index) {
                        final item = items[index];
                        final bool isSelected = (index == currentIndex);
                        final double scale = isSelected ? 1.0 : 0.85;

                        return Center(
                           child: AnimatedScale(
                                scale: scale,
                                duration: const Duration(milliseconds: 250),
                                child: GestureDetector(
                                    onTap: () {
                                        if (controller.hasClients) {
                                            controller.animateToPage( index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, );
                                        }
                                    },
                                    child: Container(
                                        width: 80,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: isSelected ? primaryColor : Colors.grey.shade300,
                                                width: isSelected ? 3.0 : 1.0,
                                            ),
                                            boxShadow: isSelected ? [
                                                BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 0)
                                            ] : [
                                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 0)
                                            ],
                                        ),
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10.5),
                                            child: Image.network(
                                                item.imageUrl,
                                                fit: BoxFit.cover,
                                                height: 85,
                                                width: 80,
                                                loadingBuilder: (context, child, progress) => progress == null ? child : Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryColor)),
                                                errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.error_outline, size: 24, color: Colors.grey)),
                                            ),
                                        ),
                                    ),
                                ),
                           ),
                        );
                    },
                ),
            ),
        ],
   );
 }
}