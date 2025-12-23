import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap/components/auth_service.dart';

class ProfilePage extends StatefulWidget {
 final String username;
 final String city;
 final double temperature;

 const ProfilePage({
   super.key,
   required this.username,
   required this.city,
   required this.temperature,
 });

 @override
 State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
 final Color primaryColor = const Color(0xFF4A148C);
 final Color secondaryPurple = const Color.fromARGB(255, 144, 76, 213);

 int topsCount = 0;
 int pantsCount = 0;
 int shoesCount = 0;
 int headwearCount = 0;
 
 int? ecoScore; 

 String? userDocId;

 @override
 void initState() {
   super.initState();
   _loadUserDocIdAndCounts();
 }

 Future<void> _loadUserDocIdAndCounts() async {
   final user = FirebaseAuth.instance.currentUser;

   if (user != null && user.email != null) {
     final querySnapshot = await FirebaseFirestore.instance
         .collection('users')
         .where('Email', isEqualTo: user.email!)
         .limit(1)
         .get();

     if (querySnapshot.docs.isNotEmpty) {
       var userData = querySnapshot.docs.first; 
       userDocId = userData.id;

       final clothesSnapshot = await FirebaseFirestore.instance
           .collection("users")
           .doc(userDocId)
           .collection("clothes")
           .get();

       int tops = 0, pants = 0, shoes = 0, headwear = 0;

       for (var doc in clothesSnapshot.docs) {
         final data = doc.data();
         final type = (data["type"] ?? "").toString().toLowerCase();

         if (type.contains("shirt") || type.contains("top")) {
           tops++;
         } else if (type.contains("pant")) {
           pants++;
         } else if (type.contains("shoe")) {
           shoes++;
         } else if (type.contains("head") || type.contains("hat") || type.contains("cap")) {
           headwear++;
         }
       }

       if (mounted) {
          setState(() {
            topsCount = tops;
            pantsCount = pants;
            shoesCount = shoes;
            headwearCount = headwear;
            ecoScore = (userData['score'] as num?)?.toInt() ?? 0; 
          });
       }
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   final _auth = AuthService();
   return Scaffold(
     backgroundColor: Colors.grey[100],
     body: CustomScrollView(
       slivers: [
         SliverAppBar(
           expandedHeight: 200,
           pinned: true,
           backgroundColor: Colors.transparent,
           flexibleSpace: LayoutBuilder(
             builder: (context, constraints) {
               double shrinkRatio =
                   (constraints.maxHeight - kToolbarHeight) / (200 - kToolbarHeight);
               shrinkRatio = shrinkRatio.clamp(0.0, 1.0);

               return FlexibleSpaceBar(
                 titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                 title: Opacity(
                   opacity: shrinkRatio,
                   child: Text(
                     widget.username,
                     style: GoogleFonts.poppins(
                       fontWeight: FontWeight.bold,
                       color: primaryColor,
                       fontSize: 20,
                     ),
                   ),
                 ),
                 background: Container(
                   decoration: const BoxDecoration(
                     gradient: LinearGradient(
                       colors: [Color(0xFFDACAF2), Color(0xFFE0D1F8)],
                       begin: Alignment.topCenter,
                       end: Alignment.bottomCenter,
                     ),
                   ),
                   child: Padding(
                     padding: const EdgeInsets.all(16),
                     child: Row(
                       children: [
                         Transform.scale(
                           scale: shrinkRatio.clamp(0.6, 1.0),
                           child: CircleAvatar(
                             radius: 40,
                             backgroundColor: secondaryPurple,
                             child: const Icon(Icons.person,
                                 color: Colors.white, size: 48),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(widget.username,
                                 style: GoogleFonts.poppins(
                                     fontWeight: FontWeight.bold,
                                     fontSize: 22,
                                     color: primaryColor)),
                             const SizedBox(height: 6),
                             Text(
                                 "${widget.city} • ${widget.temperature.round()}℃",
                                 style: GoogleFonts.poppins(
                                     fontSize: 14,
                                     fontWeight: FontWeight.w500,
                                     color: Colors.grey[700])),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
               );
             },
           ),
         ),

         SliverPadding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
           sliver: SliverToBoxAdapter(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("My Capsule Wardrobe",
                     style: GoogleFonts.poppins(
                         fontWeight: FontWeight.bold,
                         fontSize: 20,
                         color: primaryColor)),
                 const SizedBox(height: 16),

                 _WideEcoCard(
                   icon: Icons.eco,
                   title: "Eco Score",
                   value: "${ecoScore ?? '...'}%", 
                   color: Colors.green,
                 ),
                 const SizedBox(height: 16),

                 GridView.count(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   crossAxisCount: 2,
                   crossAxisSpacing: 12,
                   mainAxisSpacing: 12,
                   childAspectRatio: 1.2,
                   children: [
                     _WardrobeCard(
                         icon: Icons.checkroom,
                         title: "Tops",
                         value: topsCount.toString(),
                         color: primaryColor),
                     _WardrobeCard(
                         icon: Icons.shopping_bag,
                         title: "Pants",
                         value: pantsCount.toString(),
                         color: secondaryPurple),
                     _WardrobeCard(
                         icon: Icons.directions_walk,
                         title: "Shoes",
                         value: shoesCount.toString(),
                         color: Colors.deepPurple),
                     _WardrobeCard(
                         icon: Icons.emoji_people,
                         title: "Headwear",
                         value: headwearCount.toString(),
                         color: Colors.indigo),
                   ],
                 ),

                 const SizedBox(height: 30),

                 Center(
                   child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(
                           horizontal: 40, vertical: 14),
                       backgroundColor: Colors.redAccent,
                       shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(30)),
                       shadowColor: Colors.red.withOpacity(0.4),
                       elevation: 6,
                     ),
                     icon: const Icon(Icons.logout, color: Colors.white),
                     label: Text("Logout",
                         style: GoogleFonts.poppins(
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
                             color: Colors.white)),
                     onPressed: () async {
                       await _auth.signout();
                       Navigator.pushReplacementNamed(context, '/login');
                     },
                   ),
                 ),
                 const SizedBox(height: 40),
               ],
             ),
           ),
         ),
       ],
     ),
   );
 }
}

class _WideEcoCard extends StatelessWidget {
 final IconData icon;
 final String title;
 final String value;
 final Color color;

 const _WideEcoCard({
   required this.icon,
   required this.title,
   required this.value,
   required this.color,
 });

 @override
 Widget build(BuildContext context) {
   return ClipRRect(
     borderRadius: BorderRadius.circular(20),
     child: BackdropFilter(
       filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
       child: Container(
         width: double.infinity,
         padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
         decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.25),
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
           boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.3),
               blurRadius: 12,
               offset: const Offset(2, 6),
             )
           ],
         ),
         child: Row(
           children: [
             Icon(icon, color: color, size: 36),
             const SizedBox(width: 14),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(title,
                       style: GoogleFonts.poppins(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                           color: Colors.grey[800])),
                   const SizedBox(height: 4),
                   Text(value,
                       style: GoogleFonts.poppins(
                           fontSize: 22,
                           fontWeight: FontWeight.bold,
                           color: color)),
                 ],
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }
}

class _WardrobeCard extends StatelessWidget {
 final IconData icon;
 final String title;
 final String value;
 final Color color;

 const _WardrobeCard({
   required this.icon,
   required this.title,
   required this.value,
   required this.color,
 });

 @override
 Widget build(BuildContext context) {
   return ClipRRect(
     borderRadius: BorderRadius.circular(20),
     child: BackdropFilter(
       filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 18),
         decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.25),
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
           boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.3),
               blurRadius: 10,
               offset: const Offset(2, 4),
             )
           ],
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(icon, color: color, size: 32),
             const SizedBox(height: 8),
             Text(value,
                 style: GoogleFonts.poppins(
                     fontWeight: FontWeight.bold, fontSize: 18, color: color)),
             Text(title,
                 style: GoogleFonts.poppins(
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
                     color: Colors.grey[700])),
           ],
         ),
       ),
     ),
   );
 }
}