import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap/components/storage_service.dart';
import 'package:swap/models/weather.dart';
import 'package:swap/models/weather_services.dart';
import 'package:swap/pages/outfitsug_page.dart';
import 'package:swap/pages/profile_page.dart';
import 'package:swap/pages/sustain_page.dart';
import 'package:swap/pages/uploadimage_page.dart';
import 'package:swap/pages/clothdetails_page.dart';

class HomePage extends StatefulWidget {
 const HomePage({super.key});

 @override
 State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 String? username;
 String? userDocId;
 int? userScore; 
 final _weatherService = WeatherService('91bbf835abf4eb3e02caf9cdf440ade7');
 weather? _weather;

 final PageController _pageController = PageController();
 int _selectedIndex = 0;

 // 🔹 Filters
 Set<String> selectedCategories = {};
 String searchQuery = "";
 String? selectedColor;

 @override
 void initState() {
   super.initState();
   _loadUsername();
   fetchWeather();
 }

 fetchWeather() async {
   String cityName = await _weatherService.getCurrentCity();
   try {
     final weather = await _weatherService.getWeather(cityName);
     if (mounted) {
      setState(() {
       _weather = weather;
     });
     }
   } catch (e) {
     print(e.toString());
   }
 }

 Future<void> _loadUsername() async {
   final user = FirebaseAuth.instance.currentUser;

   if (user != null && user.email != null) {
     String email = user.email!;
     final querySnapshot = await FirebaseFirestore.instance
         .collection('users')
         .where('Email', isEqualTo: email)
         .limit(1)
         .get();

     if (mounted && querySnapshot.docs.isNotEmpty) {
       var userData = querySnapshot.docs.first; // Get the user's document
       setState(() {
         username = userData['User Name'];
         userDocId = userData.id;
         userScore = (userData['score'] as num?)?.toInt() ?? 0; // Fetch and default score
       });
     }
   }
 }

 final List<Map<String, dynamic>> categories = [
   {"icon": Icons.checkroom, "label": "Shirts/Tops"},
   {"icon": Icons.work, "label": "Pants"},
   {"icon": Icons.hiking, "label": "Shoes"},
   {"icon": Icons.headphones_sharp, "label": "Headwear"},
 ];

 // 🔹 New color options
 final Map<String, Color> colorOptions = {
   "All Colors": Colors.transparent, // reset option
   "Black": Colors.black,
   "White": Colors.white,
   "Grey": Colors.grey,
   "Navy": const Color(0xFF001F54),
   "Blue": Colors.blue,
   "Red": Colors.red,
   "Green": Colors.green,
   "Yellow": Colors.yellow,
   "Brown": Colors.brown,
   "Beige": const Color(0xFFF5F5DC),
   "Purple": Colors.purple,
   "Pink": Colors.pink,
   "Orange": Colors.orange,
   "Olive": const Color(0xFF808000),
   "Teal": Colors.teal,
   "Maroon": const Color(0xFF800000),
 };

 final Color primaryColor = const Color(0xFF4A148C);

 void _onItemTapped(int index) {
   // This function now only handles jumping to the page.
   // The refresh logic is handled in onPageChanged.
   _pageController.jumpToPage(index);
 }

 Widget _buildWardrobePage() {
   return SafeArea(
     child: Column(
       children: [
         // ✅ Header
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Row(
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
                       Text("Hello, ${username ?? "..."}",
                           style: GoogleFonts.poppins(
                               fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                       Row(
                         children: [
                           Text(_weather?.cityName ?? "Loading...",
                               style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                           const SizedBox(width: 5),
                           Text(": ${_weather?.temperature.round().toString()} ℃",
                               style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                         ],
                       ),
                     ],
                   ),
                 ],
               ),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: primaryColor.withOpacity(0.2),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Column(
                   children: [
                     Icon(Icons.eco, color: primaryColor, size: 28),
                     Text(userScore?.toString() ?? "...", 
                         style: GoogleFonts.poppins(
                             fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                     Text("Score",
                         style: GoogleFonts.poppins(
                             fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                   ],
                 ),
               ),
             ],
           ),
         ),

         // ✅ Search & Category + Color filter
         Container(
           padding: const EdgeInsets.all(12), // smaller padding
           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // smaller margin
           decoration: BoxDecoration(
             color: primaryColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(16),
           ),
           child: Column(
             children: [
               TextField(
                 onChanged: (value) => setState(() => searchQuery = value),
                 decoration: InputDecoration(
                   hintText: "Search clothes...",
                   prefixIcon: Icon(Icons.search, color: primaryColor),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: BorderSide.none,
                   ),
                   filled: true,
                   fillColor: Colors.grey[100],
                 ),
               ),
               const SizedBox(height: 8),
               // Categories
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: categories.map((cat) {
                   final isSelected = selectedCategories.contains(cat["label"]);
                   return GestureDetector(
                     onTap: () {
                       setState(() {
                         isSelected
                             ? selectedCategories.remove(cat["label"])
                             : selectedCategories.add(cat["label"]);
                       });
                     },
                     child: Column(
                       children: [
                         CircleAvatar(
                           radius: 24,
                           backgroundColor: isSelected ? primaryColor : Colors.grey[200],
                           child: Icon(cat["icon"], size: 22,
                               color: isSelected ? Colors.white : primaryColor),
                         ),
                         const SizedBox(height: 4),
                         Text(cat["label"],
                             style: GoogleFonts.poppins(
                                 fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                       ],
                     ),
                   );
                 }).toList(),
               ),
               const SizedBox(height: 10),
               // 🔹 Elegant Color Dropdown
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.7),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.grey.shade300, width: 1),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.05),
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     ),
                   ],
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String>(
                     value: selectedColor,
                     hint: Text("Filter by Color",
                         style: GoogleFonts.poppins(
                             fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor)),
                     icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                     isExpanded: true,
                     dropdownColor: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     onChanged: (value) {
                       setState(() {
                         selectedColor = value == "All Colors" ? null : value;
                       });
                     },
                     items: colorOptions.entries.map((entry) {
                       return DropdownMenuItem<String>(
                         value: entry.key,
                         child: Row(
                           children: [
                             if (entry.key != "All Colors")
                               CircleAvatar(
                                 radius: 10,
                                 backgroundColor: entry.value,
                                 child: entry.key == "White"
                                     ? Container(
                                         decoration: BoxDecoration(
                                           border: Border.all(color: Colors.grey),
                                           shape: BoxShape.circle,
                                         ),
                                       )
                                     : null,
                               ),
                             if (entry.key != "All Colors") const SizedBox(width: 10),
                             Text(entry.key,
                                 style: GoogleFonts.poppins(
                                     fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                           ],
                         ),
                       );
                     }).toList(),
                   ),
                 ),
               ),
             ],
           ),
         ),

         // ✅ Wardrobe Grid
         Expanded(
           child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: userDocId == null
                 ? const Center(child: CircularProgressIndicator())
                 : StreamBuilder<QuerySnapshot>(
                     stream: FirebaseFirestore.instance
                         .collection("users")
                         .doc(userDocId)
                         .collection("clothes")
                         .orderBy("createdAt", descending: true)
                         .snapshots(),
                     builder: (context, snapshot) {
                       if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                       final clothes = snapshot.data!.docs.where((doc) {
                         final data = doc.data() as Map<String, dynamic>;
                         final matchesCategory = selectedCategories.isEmpty ||
                             selectedCategories.contains(data["type"] ?? "");
                         final matchesSearch = searchQuery.isEmpty ||
                             (data["name"] ?? "").toLowerCase().contains(searchQuery.toLowerCase());
                         final matchesColor = selectedColor == null ||
                             (data["color"]?.toString().toLowerCase() ?? "").contains(selectedColor!.toLowerCase());
                         return matchesCategory && matchesSearch && matchesColor;
                       }).toList();

                       if (clothes.isEmpty) {
                         return Center(
                             child: Text("No clothes match your filters",
                                 style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)));
                       }

                       return GridView.builder(
                         itemCount: clothes.length,
                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                           crossAxisCount: 2,
                           childAspectRatio: 0.75,
                           crossAxisSpacing: 12,
                           mainAxisSpacing: 12,
                         ),
                         itemBuilder: (context, index) {
                           final docSnap = clothes[index];
                           final cloth = docSnap.data() as Map<String, dynamic>;

                           return GestureDetector(
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => ClothDetailsPage(
                                     clothId: docSnap.id,
                                     userDocId: userDocId!,
                                     clothData: cloth,
                                   ),
                                 ),
                               );
                             },
                             child: _GlassContainer(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.center,
                                 children: [
                                   Expanded(
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(16),
                                       child: cloth["imageUrl"] != null
                                           ? Image.network(
                                               cloth["imageUrl"],
                                               fit: BoxFit.cover,
                                               width: double.infinity,
                                             )
                                           : Container(
                                               color: Colors.grey[300],
                                               child: const Icon(Icons.image_not_supported,
                                                   size: 50, color: Colors.grey),
                                             ),
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                   Text(cloth["name"] ?? "Unnamed",
                                       style: GoogleFonts.poppins(
                                           fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                                   Text("${cloth["type"] ?? "Unknown"} | ${cloth["color"] ?? "-"}",
                                       style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                 ],
                               ),
                             ),
                           );
                         },
                       );
                     },
                   ),
           ),
         ),
       ],
     ),
   );
 }

 @override
 Widget build(BuildContext context) {
   final storageService = StorageService(email: FirebaseAuth.instance.currentUser!.email.toString());
   storageService;
   return Scaffold(
     body: Container(
       decoration: const BoxDecoration(
         gradient: LinearGradient(
           colors: [Color.fromARGB(255, 218, 202, 242), Color.fromARGB(255, 218, 202, 242)],
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
         ),
       ),
       child: PageView(
         controller: _pageController,
         onPageChanged: (index) {
           setState(() => _selectedIndex = index);
           if (index == 0) {
             _loadUsername();
           }
         },
         children: [
           _buildWardrobePage(),
           OutfitSuggestionPage(
             username: username.toString(),
             city: _weather?.cityName ?? "Loading...",
             temperature: _weather?.temperature.toDouble() ?? 0,
           ),
           SustainabilityPage(
             username: username.toString(),
             city: _weather?.cityName ?? "Loading...",
             temperature: _weather?.temperature.toDouble() ?? 0,
           ),
           UploadImagePage(email: FirebaseAuth.instance.currentUser?.email ?? "No Email"),
           ProfilePage(
             username: username.toString(),
             city: _weather?.cityName ?? "Loading...",
             temperature: _weather?.temperature.toDouble() ?? 0,
           ),
         ],
       ),
     ),
     bottomNavigationBar: ClipRRect(
       borderRadius: const BorderRadius.only(
         topLeft: Radius.circular(24),
         topRight: Radius.circular(24),
       ),
       child: BackdropFilter(
         filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
         child: BottomNavigationBar(
           backgroundColor: Colors.white.withOpacity(0.2),
           elevation: 0,
           currentIndex: _selectedIndex,
           onTap: _onItemTapped,
           selectedItemColor: primaryColor,
           unselectedItemColor: Colors.black,
           type: BottomNavigationBarType.shifting,
           items: const [
             BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
             BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: "Outfits"),
             BottomNavigationBarItem(icon: Icon(Icons.eco_sharp), label: "Eco"),
             BottomNavigationBarItem(icon: Icon(Icons.add_a_photo_sharp), label: "Upload"),
             BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
           ],
         ),
       ),
     ),
   );
 }
}

class _GlassContainer extends StatelessWidget {
 final Widget child;
 const _GlassContainer({required this.child});

 @override
 Widget build(BuildContext context) {
   return ClipRRect(
     borderRadius: BorderRadius.circular(20),
     child: BackdropFilter(
       filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
       child: Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(20),
           color: Colors.white.withOpacity(0.3),
           border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
         ),
         child: child,
       ),
     ),
   );
 }
}