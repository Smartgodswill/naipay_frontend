import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:naipay/theme/colors.dart';
import 'package:naipay/utils/utils.dart';

class Depositscreen extends StatefulWidget {
  const Depositscreen({super.key});

  @override
  State<Depositscreen> createState() => _DepositscreenState();
}

class _DepositscreenState extends State<Depositscreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kmainBackgroundcolor,
        iconTheme: IconThemeData(color: kmainWhitecolor),
      ),
      backgroundColor: kmainBackgroundcolor,
      body: Column(
        children: [
            SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15,top: 10),
                child: Text('Fund your wallet',style: TextStyle(color: kmainWhitecolor,fontSize: 25),),
              ),
            
            ],
          ),
            Row(
              children: [
                Padding(
                    padding: const EdgeInsets.only(left:16 ,top: 2),
                    child: Text('Select a local currency to fund your wallet',style: TextStyle(color: kmainWhitecolor,fontSize: 15),),
                  ),
              ],
            ),
           
          SizedBox(height: 20,),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: customButtonContainer(60, size.width*1, BoxDecoration(
              color: kmainBackgroundcolor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kwhitecolor,
                  blurRadius: 5,
                  blurStyle: BlurStyle.solid,
                  spreadRadius: 0.9
                )
              ]
            ), Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: SvgPicture.asset('asset/nairaicon.svg',color: Colors.green),),),
                Text('Naira',style: TextStyle(color: kmainWhitecolor),)
                  ],
                ),
              ],
            ), (){}),
          ),
           SizedBox(height: 8,),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: customButtonContainer(60, size.width*1, BoxDecoration(
              color: kmainBackgroundcolor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kwhitecolor,
                  blurRadius: 5,
                  blurStyle: BlurStyle.solid,
                  spreadRadius: 0.9
                )
              ]
            ),  Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: SvgPicture.asset('asset/kenyancurrencyicon.svg',color: Colors.green,),),),
                 Text('Kenya shillings',style: TextStyle(color: kmainWhitecolor),)
                  ],
                )
              ],
            ), (){}),
          )
        ],
      ),
    );
  }
}