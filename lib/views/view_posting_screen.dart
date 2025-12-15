import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Host_Screens/book_listing_screen.dart';
import 'package:service_app/views/Widgets/posting_info_tile_ui.dart';
import 'package:service_app/views/conversation_screen.dart';

class ViewPostingScreen extends StatefulWidget {
  final PostingModel? posting;

  ViewPostingScreen({super.key, this.posting});

  @override
  State<ViewPostingScreen> createState() => _ViewPostingScreenState();
}

class _ViewPostingScreenState extends State<ViewPostingScreen> {
  late PostingModel posting;
  bool isLoading = true;

  Future<void> getRequiredInfo() async {
    try {
      await posting.getAllImagesFromStorage();
      await posting.getHostFromFirestore();
      
      // Debug: Print host information
      print("Host ID: ${posting.host?.id}");
      print("Host Name: ${posting.host?.getFullNameofUser()}");
      print("Host Display Image: ${posting.host?.displayImage}");
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    posting = widget.posting!;
    getRequiredInfo();
  }

  Future<void> _startConversation() async {
    if (posting.host != null && posting.host!.id != null) {
      try {
        // Show loading indicator
        Get.dialog(
          Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        // Create a ContactModel for the host
        ContactModel hostContact = ContactModel(
          id: posting.host!.id,
          firstname: posting.host!.firstname,
          lastname: posting.host!.lastname,
        );

        // Initialize a new conversation
        ConversationModel conversation = ConversationModel();
        
        // Check if conversation already exists or create new one
        QuerySnapshot conversationSnapshot = await FirebaseFirestore.instance
            .collection("conversations")
            .where("userIDs", arrayContains: AppConstants.currentUser.id)
            .get();

        bool conversationExists = false;
        
        for (var doc in conversationSnapshot.docs) {
          List<dynamic> userIDs = doc["userIDs"] ?? [];
          if (userIDs.contains(posting.host!.id)) {
            // Existing conversation found
            conversation.id = doc.id;
            await conversation.getConversationInfoFromFirestore(doc);
            conversationExists = true;
            break;
          }
        }

        if (!conversationExists) {
          // Create new conversation
          await conversation.addConversationToFirestore(hostContact);
        }

        // Close loading dialog
        if (Get.isDialogOpen!) Get.back();

        // Navigate to conversation screen
        Get.to(() => ConversationScreen(conversation: conversation));
        
      } catch (e) {
        // Close loading dialog if still open
        if (Get.isDialogOpen!) Get.back();
        
        Get.snackbar(
          'Error',
          'Could not start conversation: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
        print("Conversation error: $e");
      }
    } else {
      Get.snackbar(
        'Error',
        'Host information is not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A6CF7), Color(0xFF82C3FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text("Product Information", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              if (posting.id != null && posting.id!.isNotEmpty) {
                AppConstants.currentUser.addSavedPosting(posting);
                Get.snackbar('Saved', 'Added to your saved list');
              } else {
                Get.snackbar('Failed to save', 'Posting ID is missing');
              }
            },
            icon: Icon(Icons.save, color: Colors.white),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Listing Images
                  AspectRatio(
                    aspectRatio: 2 / 2,
                    child: (posting.displayImages.isEmpty)
                        ? Container(
                            color: Colors.grey[200],
                            child: Center(child: Icon(Icons.image, size: 50)),
                          )
                        : PageView.builder(
                            itemCount: posting.displayImages.length,
                            itemBuilder: (context, index) {
                              MemoryImage currentImage = posting.displayImages[index];
                              return Image(
                                image: currentImage,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(child: Icon(Icons.broken_image)),
                                  );
                                },
                              );
                            },
                          ),
                  ),

                  // Posting Name and book now button
                  Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Posting Name button and book now
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 1.55,
                              child: Text(
                                posting.name!.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 3,
                              ),
                            ),

                            // book now button price
                            Column(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF4A6CF7), Color(0xFF82C3FF)],
                                      begin: FractionalOffset(0, 0),
                                      end: FractionalOffset(1, 0),
                                      stops: [0, 1],
                                      tileMode: TileMode.clamp,
                                    ),
                                  ),
                                  child: MaterialButton(
                                    onPressed: () {
                                      final hostId = posting.host?.id ?? '';
                                      Get.to(() => BookListingScreen(posting: posting, hostID: hostId));
                                    },
                                    child: Text(
                                      "Order Now",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Text(
                                  "\$${posting.price}/unit",
                                  style: TextStyle(fontSize: 14),
                                )
                              ],
                            )
                          ],
                        ),

                        // Description and profile pic
                        Padding(
                          padding: EdgeInsets.only(top: 25, bottom: 25),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 1.75,
                                child: Text(
                                  posting.description!,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 5,
                                ),
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _startConversation,
                                    child: CircleAvatar(
                                      radius: MediaQuery.of(context).size.width / 12.5,
                                      backgroundColor: Colors.grey[300],
                                      child: posting.host?.displayImage != null
                                          ? CircleAvatar(
                                              backgroundImage: posting.host!.displayImage,
                                              radius: MediaQuery.of(context).size.width / 13,
                                            )
                                          : CircleAvatar(
                                              radius: MediaQuery.of(context).size.width / 13,
                                              backgroundColor: Colors.blue,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      posting.host?.getFullNameofUser() ?? "Pharmacy",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // Product details
                  Padding(
                    padding: EdgeInsets.only(bottom: 25),
                    child: ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        PostingInfoTileUi(
                          iconData: Icons.health_and_safety,
                          category: "Product Type",
                          categoryInfo: posting.type ?? "Not specified",
                        ),
                        PostingInfoTileUi(
                          iconData: Icons.eco,
                          category: "Availability",
                          categoryInfo: "${posting.getGuestsNumber()} in stock",
                        ),
                        PostingInfoTileUi(
                          iconData: Icons.inventory,
                          category: "Category",
                          categoryInfo: posting.type ?? "General",
                        ),
                      ],
                    ),
                  ),

                  // Sizes
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Available Sizes:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 25, left: 16, right: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 3.6,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: posting.amenities != null 
                          ? List.generate(
                              posting.amenities!.length,
                              (index) {
                                String currentAmenity = posting.amenities![index];
                                return Container(
                                  margin: EdgeInsets.all(4),
                                  child: Chip(
                                    label: Text(
                                      currentAmenity,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: Colors.blue[50],
                                    elevation: 2,
                                  ),
                                );
                              },
                            )
                          : [
                              Chip(
                                label: Text("No sizes available"),
                                backgroundColor: Colors.grey[200],
                              )
                            ],
                    ),
                  ),

                  // Location
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Pharmacy Address:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 25, left: 16, right: 16),
                    child: Text(
                      posting.getFullAddress(),
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}