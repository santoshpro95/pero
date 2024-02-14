import 'package:flutter/material.dart';
import 'package:pero/features/home/home_screen.dart';
import 'package:pero/features/user_details/user_details_bloc.dart';
import 'package:pero/features/user_details/user_details_screen.dart';

// region App
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // region Build
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {'/home': (context) => const UserDetailsScreen()},
      initialRoute: '/home',
    );
  }
  // endregion

}
// endregion
