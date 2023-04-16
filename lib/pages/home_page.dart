import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:radio_app/model/radio.dart';
import 'package:radio_app/utils/ai_utils.dart';
import 'package:velocity_x/velocity_x.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
           List<MyRadio>? radios   ;
          late MyRadio _selectedRadio;
          late Color _selectedColor;
         bool _isplaying = false;

         final AudioPlayer _audioPlayer  = AudioPlayer();
  @override
  void initState() {
    super.initState();
    setupAlan();
    fetchRadios();
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if(event == PlayerState.playing){
        _isplaying =true;
      }
      else{
        _isplaying =false;
      }
    });
  }
  setupAlan(){
    AlanVoice.addButton(
        "38dcb3f672848f6352d886a1ddb5aa282e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }
  _handleCommand(Map<String,dynamic> response){
    switch(response["command"]){
      case "play" :
        _playMusic(_selectedRadio.url);
        break;
      case "play_channel":
        final id = response["id"];
        // _audioPlayer.pause();
        MyRadio newRadio = radios!.firstWhere((element) => element.id == id);
        radios?.remove(newRadio);
        radios?.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;
      case "stop" :
        _audioPlayer.stop();
        break;
      case "next":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index + 1 > radios!.length) {
          newRadio = radios!.firstWhere((element) => element.id == 1);
          radios?.remove(newRadio);
          radios?.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index + 1);
          radios?.remove(newRadio);
          radios?.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      case "prev":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index - 1 <= 0) {
          newRadio = radios!.firstWhere((element) => element.id == 1);
          radios?.remove(newRadio);
          radios?.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index - 1);
          radios?.remove(newRadio);
          radios?.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      default:
        if (kDebugMode) {
          print('Command was ${response["command"]}');
        }
    }
  }
  fetchRadios() async {
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios![0];
    _selectedColor =Color(int.tryParse(_selectedRadio.color)!);
    if (kDebugMode) {
      print(radios);
    }
    setState(() {});
  }
  _playMusic(String url){
    _audioPlayer.play(UrlSource(url));
    _selectedRadio=  radios!.firstWhere((element) => element.url == url);
    print(_selectedRadio.name);
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(colors: [
                AIColor.primaryColor2,
                AIColor.primaryColor1,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight))
              .make(),
          AppBar(
            title: 'AI Radio'
                .text
                .xl4
                .bold
                .white
                .make()
                .shimmer(primaryColor: Vx.red200, secondaryColor: Colors.white),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
          ).h(100.0).p16(),
          radios!=null ? VxSwiper.builder(
            itemCount: radios?.length ?? 0,
            aspectRatio: 1.0,
            enlargeCenterPage : true,
            onPageChanged: (index){
              _selectedRadio = radios![index];
              final colorhex = radios![index].color;
              _selectedColor = Color(int.tryParse(colorhex)!);
              setState(() {

              });
            },
            itemBuilder: (context, index) {
              final rad = radios![index];
              return VxBox(child:ZStack([
                Positioned(
                  top: 0.0,
                  right: 0.0,
                  child: VxBox(
                    child: rad.category.text.uppercase.white.make().px16()
                  ).height(40.0).black.alignCenter.withRounded(value: 10.0).make()
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VStack(
                    [rad.name.text.xl3.white.bold.make(),
                    5.heightBox,
                    rad.tagline.text.sm.white.semiBold.make()]
                  ,
                    crossAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: [const Icon(CupertinoIcons.play_circle,
                  color: Colors.white,),
                    10.heightBox,
                    "Double tap to play".text.gray300.make(),
                  ].vStack())
              ],clip: Clip.antiAlias,))
                  .clip(Clip.antiAlias)
                  .bgImage(DecorationImage(
                      image: NetworkImage(rad.image),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3), BlendMode.darken)))
                  .border(color: Colors.black,width: 2.0)
                  .withRounded(value: 60.0)
                  .make().onInkDoubleTap(() {_playMusic(rad.url);}).p16();
            },
          ).centered():const Center(child: CircularProgressIndicator(backgroundColor: Colors.white,),),
           Align(
            alignment: Alignment.bottomCenter,
            child: [
              if(_isplaying)
                "Playing now - ${_selectedRadio.name} FM".text.white
                    .makeCentered(),
              Icon(
              _isplaying
                  ?CupertinoIcons.stop_circle:CupertinoIcons.play_circle,
              color: Colors.white,
              size: 50.0,
            ).onInkTap(() {
              if(_isplaying){
                _audioPlayer.stop();
              }
            else{
              _playMusic(_selectedRadio.url);
            }})].vStack(),
          ).pOnly(bottom: context.percentHeight * 12)
        ],
      ),
    );
  }
}
