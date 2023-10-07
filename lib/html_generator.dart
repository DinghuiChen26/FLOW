import 'dart:convert';
import 'dart:io';

String imageToBase64String(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  return base64Encode(bytes);
}

String generateHTML(String base64Image) {
  // Check if the file exists
  // final file = File(imagePath);
  // if (!file.existsSync()) {
  //   throw Exception('File does not exist at the provided path: $imagePath');
  // }

  return '''
<!doctype html>
<html>
<head>
    <title>L28 - Stereoscopic images</title>
    <script src="https://aframe.io/releases/1.0.4/aframe.min.js"></script>
    <script>
      // ... [Your embedded JS code here] ...
    </script>
</head>
    
<body>
    <a-scene>
        <a-assets>
              <img id="left" src="data:image/jpg;base64,$base64Image">
              <img id="right" src="data:image/jpg;base64,$base64Image">
          </a-assets>
        
        <a-camera stereocam="eye: right"></a-camera>
        
        <a-sky src="#left" rotation="0 -90 0" stereo="eye: left"></a-sky>
        <a-sky src="#right" rotation="0 -90 0" stereo="eye: right"></a-sky>
    </a-scene>
</body>
</html>
''';
}
