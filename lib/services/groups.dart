import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_app/models/group.dart';
import 'package:social_app/models/message.dart';
import 'package:social_app/models/user.dart';

class GroupService {
  FirebaseFirestore instance = FirebaseFirestore.instance;

  Future<void> addGroup(String username, String groupName) async {
    // get the firest user
    var result = await instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();

    String id = result.docs[0].id;
    print("-----------\nId is: " + id);

    // make a new chat in firestore, initial users are logged in user and selected user
    instance.collection("chats").add({
      "users": [FirebaseAuth.instance.currentUser.uid, id],
      "createdAt": Timestamp.now(),
      "groupName": groupName,
    });
  }

  List<GroupModel> _getGroupModel(QuerySnapshot snapshot) {
    // returns a GroupModel for each found document
    return snapshot.docs.map((doc) {
      var data = doc.data();
      return GroupModel(groupName: data['groupName'], id: doc.id);
    }).toList();
  }

  Stream<List<GroupModel>> getGroupsFromId() {
    
    return instance
        .collection("chats")
        .where('users', arrayContains: FirebaseAuth.instance.currentUser.uid)
        .snapshots()
        .map(_getGroupModel);
  }

  Future<void> addMessage(String id, String text) async {
    //TODO: this isnt so smart, find solution
    var user = await instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser.uid)
        .get();
    var data = user.data();

    // add message to chat
    await instance.collection("chats").doc(id).collection("messages").add({
      "creator": FirebaseAuth.instance.currentUser.uid,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "isVerified": data['isVerified'],
      "username": data['username'],
      "profileImageUrl": data["profile"],
    });
  }

  List<MessageModel> _getMessageModel(QuerySnapshot snapshot) {
    // returns a message model for each document
    // TODO: optimize?
    
    return snapshot.docs.map((doc) {
      var data = doc.data();
      return doc != null
          ? MessageModel(
              isVerified: data['isVerified'],
              profileImgUrl: data['profileImageUrl'],
              name: data['username'],
              creator: data['creator'],
              text: data['text'] ?? "NULL",
              timestamp: data['timestamp'],
            )
          : null;
    }).toList();
  }

  Stream<List<MessageModel>> getMessagesByGroup(String id) {
    return instance
        .collection("chats")
        .doc(id)
        .collection("messages")
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map(_getMessageModel);
  }
}
