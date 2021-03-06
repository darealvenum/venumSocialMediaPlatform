import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class AuthService {
  FirebaseAuth auth = FirebaseAuth.instance;

  UserModel _userFromFirebaseUser(User user) {
    return user != null ? UserModel(id: user.uid) : null;
  }

  Stream<UserModel> get user {
    return auth.authStateChanges().map(_userFromFirebaseUser);
  }

  Future signUp(String email, String password) async {
    try {
      UserCredential user = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
      _userFromFirebaseUser(user.user);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user.uid)
          .set(
        {
          'username': email,
          'email': email,
          'bio': 'No bio yet',
          'isVerified': false,
          'posts': 0,
          'profile': "https://inlandfutures.org/wp-content/uploads/2019/12/thumbpreview-grey-avatar-designer.jpg",
        },
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  void signIn(String email, String password) async {
    try {
      User user = (await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password)) as User;
    } on FirebaseAuthException catch (e) {
      print(e);
    } catch (e) {
      print(e);
    }
  }

  Future signOut() async {
    try {
      return await auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
