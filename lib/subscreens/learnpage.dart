import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Learnpage extends StatefulWidget {
  const Learnpage({super.key});

  @override
  State<Learnpage> createState() => _LearnpageState();
}

List<AssetImage> videoimages = [
  AssetImage('asset/bit1.jpg'),
  AssetImage('asset/bit2.jpg'),
];
List<String> videoLinks = [
  "https://21lessons.com/preface",
  "https://youtu.be/8Z4hGvUET8I?si=tHUFjIA09exAChOs",
];

List<String> readLinks = [
  "https://stacker.news",
  "https://www.thndr.games/",
  "https://youtu.be/-m22d6tPaj4?si=p7jtodLwOAtR1gt5",
  "https://bitcoiners.africa/earn-bitcoin/places-to-earn-sats/",
];
Future<void> openVideoUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
Future<void> openBooksUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _LearnpageState extends State<Learnpage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: kmainWhitecolor),
        backgroundColor: kmainBackgroundcolor,
        title: Padding(
          padding: const EdgeInsets.all(10),
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
      backgroundColor: kmainBackgroundcolor,
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
                        color: kwhitecolor,
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
                          backgroundImage: const AssetImage(
                            'asset/bitcoinicon.png',
                          ),
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

            const SizedBox(height: 8),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 9),
                  child: Text(
                    'Read',
                    style: TextStyle(
                      color: kwhitecolor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  String image = images[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: customContainer(
                      250,
                      size.width / 2.1,
                      BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurStyle: BlurStyle.solid,
                            color: kwhitecolor,
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
                            Lottie.asset(
                              image,
                              fit: index == 2 ? BoxFit.cover : BoxFit.fitHeight,

                              height: index == 2 ? 133 : 130,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 50,
                              ),
                              child: GestureDetector(
                                onTap: ()=>openBooksUrl(readLinks[index]),
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
                                    borderRadius: BorderRadius.circular(30),
                                    color: kwhitecolor,
                                  ),
                                  Center(
                                    child: Text(
                                      earnText[index],
                                      style: TextStyle(
                                        color: kmainBackgroundcolor,
                                      ),
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

            const SizedBox(height: 20),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 9),
                  child: Text(
                    'Videos',
                    style: TextStyle(
                      color: kwhitecolor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 250,
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(9.0),
                    child: Stack(
                      children: [
                        SizedBox(height: 30,),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () => openVideoUrl(videoLinks[index]),
                            child: customContainer(
                              size.height / 9.0,
                              size.width,
                              BoxDecoration(
                                image: DecorationImage(
                                  image: videoimages[index],
                                  fit: BoxFit.cover,
                                ),
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
                              const SizedBox(),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 45,
                          left: 170,
                          child: InkWell(
                            onTap: () => openVideoUrl(videoLinks[index]),
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 45,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
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
