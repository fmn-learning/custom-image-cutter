import 'package:custom_image_cutter/custom_image_cutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MyHomePage(title: 'Flutter Demo Home Page'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final cropImage = GlobalKey();
  final controller = CustomImageCutterController();

  @override
  void initState() {
    controller.scaleNotifier.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 300,
                  height: 400,
                  child: CustomImageCutter(
                    controller: controller,
                    cropperKey: cropImage,
                    imagePath: 'image_path',
                    image: Image.network(
                      'https://play-lh.googleusercontent.com/IeNJWoKYx1waOhfWF6TiuSiWBLfqLb18lmZYXSgsH1fvb8v1IYiZr5aYWe0Gxu-pVZX3', //square image
                      // 'https://nmwa.org/wp-content/uploads/2020/01/1993.76-GAP.jpg', //portrait image
                      // 'https://st.depositphotos.com/1034986/4574/i/950/depositphotos_45747235-stock-photo-beautiful-woman-selfie.jpg', //landscape image
                    ),
                  ),
                ),
              ],
            ),
            Slider(
                min: controller.minScale,
                max: controller.maxScale,
                value: controller.scale,
                onChanged: (value) =>
                    setState(() => controller.updateScale(value))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cropped = await controller.crop(cropperKey: cropImage);
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(),
                body: Center(child: Image.memory(cropped!)),
              ),
              fullscreenDialog: true,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
