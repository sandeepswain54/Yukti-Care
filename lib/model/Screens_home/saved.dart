import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/utils.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/global.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Widgets/posting_grid_tile_ui.dart';
import 'package:service_app/views/view_posting_screen.dart';

class Saved extends StatefulWidget {
  const Saved({super.key});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.fromLTRB(25, 15, 25, 0),
    child: GridView.builder(
     physics: ScrollPhysics(),
     shrinkWrap: true,
     itemCount: AppConstants.currentUser.savedPostings!.length,
     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 3/4),
    itemBuilder: (context,index)
    {
      PostingModel currentPosting = AppConstants.currentUser.savedPostings![index];

      return Stack(
children: [
  InkResponse(
    enableFeedback: true,
    child: PostingGridTileUi(posting: currentPosting,),
    onTap: (){
Get.to(ViewPostingScreen(posting: currentPosting,));
    },
  ),

Align(
  alignment: Alignment.topRight,
  child: Padding(padding: 
  EdgeInsets.only(right: 10),
  child: Container(
    width: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white
    ),

    child: IconButton(onPressed: (){
AppConstants.currentUser.removeSavedPosting(currentPosting);

setState(() {
  
});


    }, icon: Icon(Icons.clear,
    color: Colors.black,)),
  ),),
)

],
      );
    }, ),

    
    );
  }
}