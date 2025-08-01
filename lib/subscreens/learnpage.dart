import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';

class Learnpage extends StatefulWidget {
  const Learnpage({super.key});

  @override
  State<Learnpage> createState() => _LearnpageState();
}

class _LearnpageState extends State<Learnpage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ksubbackgroundcolor,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'Bitcoin University',
            style: TextStyle(
              color: kwhitecolor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: ksubbackgroundcolor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(
                  begin: const Offset(-1.5, 0),
                  end: Offset.zero,
                ),
                duration: const Duration(seconds: 2),
                curve: Curves.easeOut,
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset * size.width,
                    child: child,
                  );
                },
                child: customContainer(
                  size.height / 7.8,
                  size.width,
                  BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurStyle: BlurStyle.solid,
                        color: ksubcolor,
                        offset: Offset.zero,
                        spreadRadius: 0.9,
                        blurRadius: 0.5,
                      ),
                    ],
                    color: kmainBackgroundcolor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: ksubcolor,
                          backgroundImage:
                              const AssetImage('asset/bitcoinicon.png'),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: Text(
                          'Holding Bitcoin is like you holding your breath under water, except you run out of oxygen and you get rich.',
                          style: TextStyle(
                            color: kwhitecolor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Bitverse',
                    style: TextStyle(
                      color: kwhitecolor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Icon(Icons.book_outlined, color: kwhitecolor),
                ),
              ],
            ),

            const SizedBox(height: 5),

            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  String image = images[index];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: customContainer(
                      size.height / 7.4,
                      size.width / 2.1,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurStyle: BlurStyle.outer,
                            color: ksubcolor,
                            offset: Offset.zero,
                            spreadRadius: 0.9,
                            blurRadius: 0.5,
                          ),
                        ],
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                      index == 2   ?   Lottie.asset(
                              image,
                              fit: BoxFit.cover,
                              height: index == 2 ? 150 : null,
                            ):Lottie.asset(
                              image,
                              fit: BoxFit.fitHeight,
                              height: index == 2 ? 150 : null),
                            Align(
                              alignment: index == 2
                                  ? Alignment.centerRight
                                  : Alignment.center,
                              child: Padding(
                                padding: index == 2
                                    ? const EdgeInsets.only(right: 8.0, top: 39.5,left:8.0 )
                                    : const EdgeInsets.all(8.0),
                                child: customContainer(
                                  45,
                                  size.width / 2.1,
                                  BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        blurStyle: BlurStyle.solid,
                                        color: ksubcolor,
                                        offset: Offset.zero,
                                        spreadRadius: 0.9,
                                        blurRadius: 0.5,
                                      ),
                                    ],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    color: ksubbackgroundcolor,
                                  ),
                                  Center(
                                    child: Text(
                                      earnText[index],
                                      style: TextStyle(color: kwhitecolor),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 3),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Video',
                    style: TextStyle(
                      color: kwhitecolor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: customContainer(
                      size.height / 9.0,
                      size.width / 2.1,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurStyle: BlurStyle.outer,
                            color: ksubcolor,
                            offset: Offset.zero,
                            spreadRadius: 0.9,
                            blurRadius: 0.5,
                          ),
                        ],
                        color: kmainBackgroundcolor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(), // Add your content here
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
