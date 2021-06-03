import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

final _fireStore=Firestore.instance;
FirebaseUser loggedInUser;
class ChatScreen extends StatefulWidget {
  static String id='chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextCntrll=TextEditingController();
  final _auth=FirebaseAuth.instance;

  String messageText;
  void getCurrentUser() async{
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e)
    {
      print(e);
    }
  }
//  void getMessages()async{
//    final messages=await _fireStore.collection('messages').getDocuments();
//    for(var message in messages.documents){
//      print(message.data);
//    }


  @override
  void initState() {
    // TODO: implement initState
    getCurrentUser();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
               _auth.signOut();
               Navigator.pop(context);

              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

           MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextCntrll,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText=value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      messageTextCntrll.clear();
                      _fireStore.collection('messages').add({
                        'text':messageText,
                        'sender':loggedInUser.email,
                        'time':FieldValue.serverTimestamp()
                      });

                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  StreamBuilder<QuerySnapshot>(stream: _fireStore.collection('messages').orderBy('time',descending: false).snapshots(),builder:(context,snapshot){
      if(!snapshot.hasData){return CircularProgressIndicator(backgroundColor: Colors.blueAccent,);}
      final messages=snapshot.data.documents.reversed;
      List<MessageBubble> messageBubbles=[];
      for(var message in messages){
        final messageText=message.data['text'];
        final messageSender=message.data['sender'];
        final messageTime=message.data['time'] as Timestamp;
        final currentUser=loggedInUser.email;

        final messageBubble=MessageBubble(sender: messageSender,text:messageText,isMe: currentUser==messageSender,time:messageTime);
        messageBubbles.add(messageBubble);
      }
      return Expanded(
        child: ListView(
          reverse: true,
          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20.0),
          children:messageBubbles,
        ),
      );
    }
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final Timestamp time;
  MessageBubble({this.sender,this.text,this.isMe, this.time});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:isMe?CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender,style: TextStyle(color: Colors.black54,fontSize: 12.0),),
          Material(
            elevation: 5.0,
            borderRadius: isMe?BorderRadius.only(topLeft: Radius.circular(30),bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30)):BorderRadius.only(topRight: Radius.circular(30),bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30)),
            color: isMe?Colors.lightBlueAccent:Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: Text('$text',style: TextStyle(
                fontSize: 15,
                color:isMe?Colors.white:Colors.black,
              ),),
            ),
          ),
        ],
      ),
    );
  }
}
