import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final _auth = FirebaseAuth.instance;
  Future<User?> createUserWithEmailAndPassword(
    String email, String password)async{
      try{
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        return cred.user;
      }on FirebaseAuthException catch (e) {
        log("Auth Error [SignUp]: ${e.code} - ${e.message}");
        rethrow;
      } catch (e) {
        log("Unknown Error [SignUp]: $e");
        rethrow;
      }
      
  }

  Future<User?> loginUserWithEmailAndPassword(
    String email, String password)async{
      try{
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        return cred.user;
      }on FirebaseAuthException catch (e) {
        log("Auth Error [Login]: ${e.code} - ${e.message}");
        rethrow;
      } catch (e) {
        log("Unknown Error [Login]: $e");
        rethrow;
      }
      
  }

  Future<void> signout()async{
    try{
      await _auth.signOut();
    }catch(e){
      log("Something went wrong");
    }
  }
}