CustomImageCutter is a simple and versatile package designed to simplify the process of customizing image crops in an intuitive way.

## Features
Scale and adjust image to crop

### scale image 

  Using external controller                   |  Using gestures                
:-------------------------:|:-------------------------:
![scale using external controller](https://raw.githubusercontent.com/fmn-learning/custom-image-cutter/main/doc/external_scale.gif)|![scale using gestures](https://raw.githubusercontent.com/fmn-learning/custom-image-cutter/main/doc/gesture_scale.gif)


### adjust image position
![adjust image position](https://raw.githubusercontent.com/fmn-learning/custom-image-cutter/main/doc/adjusting_image.gif)


### crop image
![crop image](https://raw.githubusercontent.com/fmn-learning/custom-image-cutter/main/doc/crop_image.gif)




## Getting started

You will find a simple example on example folder.


Start creating a controller: 

```final controller = CustomImageCutterController();```

And a globalkey: 

```final cropImage = GlobalKey();```



And use it on:

```
CustomImageCutter(
    controller: controller,
    cropperKey: cropImage,
    imagePath: 'image_path',
    image: Image.network('image_path'),
    ),
```

To scale the image:
```controller.updateScale(value) //value is a double```

You can use a slider to control the scale:
```
Slider(
min: 1,
max: controller.maxScale, //the controller hold the max scale
value: controller.scale, //the contoller expose the actual scale
onChanged: (value) =>setState(() => controller.updateScale(value)))),
```

To get the cropped image:

```
final cropped = await controller.crop(cropperKey: cropImage);
```