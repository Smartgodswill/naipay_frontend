import 'package:flutter/material.dart';
import 'package:naipay/subscreens/homepage.dart';
import 'package:naipay/subscreens/learnpage.dart';
import 'package:naipay/subscreens/marketlevelpage.dart';
import 'package:naipay/subscreens/personpage.dart';
import 'package:naipay/theme/colors.dart';
import 'package:super_bottom_navigation_bar/super_bottom_navigation_bar.dart';

class NavigateScreen extends StatefulWidget {
  final String email;
  const NavigateScreen({super.key, required this.email});

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  int _indexedScreen = 0;
  late final List<Widget> _selectedPages;

  @override
  void initState() {
    super.initState();
    _selectedPages = [
      Homepage(email: widget.email),
      Learnpage(),
      Marketlevelpage(),
      Personpage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedPages[_indexedScreen],
      backgroundColor: ksubbackgroundcolor,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SuperBottomNavigationBar(
          curve: Curves.easeInOut,
          height: 60,
          backgroundColor: kmainBackgroundcolor,
          items: [
            SuperBottomNavigationBarItem(
              splashColor: kgraycolor,
              backgroundShadowColor: ksubcolor,
              borderBottomColor: ksubbackgroundcolor,

              selectedIcon: Icons.home,
              unSelectedIcon: Icons.home,
              selectedIconColor: ksubcolor,
            ),
            SuperBottomNavigationBarItem(
              backgroundShadowColor: ksubcolor,
              selectedIconColor: ksubcolor,
              splashColor: kgraycolor,
              borderBottomColor: kmainBackgroundcolor,

              selectedIcon: Icons.upcoming,
              unSelectedIcon: Icons.upcoming,
            ),

            SuperBottomNavigationBarItem(
              splashColor: kgraycolor,
              borderBottomColor: ksubbackgroundcolor,

              selectedIconColor: ksubcolor,
              backgroundShadowColor: ksubcolor,

              selectedIcon: Icons.library_books,
              unSelectedIcon: Icons.library_books,
            ),
            SuperBottomNavigationBarItem(
              splashColor: kgraycolor,
              backgroundShadowColor: ksubcolor,
              borderBottomColor: kmainBackgroundcolor,
              selectedIconColor: ksubcolor,
              selectedIcon: Icons.person_2,
              unSelectedIcon: Icons.person_2,
            ),
          ],
          currentIndex: _indexedScreen,
          onSelected: (index) {
            setState(() {
              _indexedScreen = index;
            });
          },
        ),
      ),
    );
  }
}
