import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ImagePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  String host = 'https://d75a-34-138-109-12.ngrok-free.app/';
  String data = '';
  bool isSending = false;
  File? imageFile;

  Future<String> sendRequest(File image) async {
    final uri = Uri.parse(host);
    final request = http.MultipartRequest("POST", uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        image.readAsBytesSync(),
        filename: 'image.jpg',
      ),
    );

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint("MMMMMMM SENDING");

      if (response.statusCode != 200) {
        // print message
        debugPrint("MMMMMMM ERROR: ${response.statusCode}");
        debugPrint("MMMMMMM BODY: $body");
        return throw Exception('Failed to send request');
      }

      debugPrint("MMMMMMM RECEIVED");

      setState(() {
        data = jsonDecode(body)['prediction'] ?? 'No data received';
      });

      return body;
    } catch (e) {
      rethrow;
    }
  }

  Future<File> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      throw Exception('No image selected');
    }

    final file = File(pickedFile.path);

    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 300,
                height: 400,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: imageFile == null
                    ? Center(
                        child: TextButton(
                          child: const Text('Pick Image'),
                          onPressed: () async {
                            try {
                              final file = await pickImage();
                              setState(() {
                                imageFile = file;
                              });
                              if (isSending) {
                                Timer.periodic(const Duration(seconds: 1),
                                    (timer) async {
                                  if (!isSending) {
                                    timer.cancel();
                                  } else {
                                    final response = await sendRequest(file);
                                    debugPrint(response);
                                  }
                                });
                              }
                            } catch (e) {
                              debugPrint('Error picking image: $e');
                            }
                          },
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Text(
                data,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            FloatingActionButton.small(
              child: const Icon(Icons.clear_rounded),
              onPressed: () {
                setState(() {
                  imageFile = null;
                  data = '';
                });
              },
            ),
            FloatingActionButton.small(
              child: const Icon(Icons.computer_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          const Text('Change Host'),
                          Text(
                            'Enter the host URL to send the image to. Current host is $host',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      content: TextField(
                        onChanged: (value) {
                          host = value;
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            FloatingActionButton(
              child: !isSending
                  ? const Icon(Icons.send_rounded)
                  : const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeCap: StrokeCap.round,
                      ),
                    ),
              onPressed: () async {
                if (imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an image first'),
                    ),
                  );
                  return;
                }
                try {
                  if (!isSending) {
                    if (context.mounted) {
                      isSending = true;
                    }
                    final response = await sendRequest(imageFile!);
                    debugPrint(response);
                    if (context.mounted) {
                      isSending = false;
                    }
                  }
                } catch (e) {
                  debugPrint('Error sending request: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Error sending request, please check the settings'),
                      ),
                    );
                  }
                  if (context.mounted) {
                    isSending = false;
                  }
                }
              },
            ),
          ],
        ));
  }
}
