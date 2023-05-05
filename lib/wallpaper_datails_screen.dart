import 'dart:io';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallpaper/photo.dart';

import 'favourites_screen.dart';

// A provider to get the download status
final downloadStatusProvider = StateProvider<DownloadStatus>((ref) => DownloadStatus.none);

// An enum to represent the download status
enum DownloadStatus { none, downloading, success, error }

class WallpaperDetailsScreen extends ConsumerWidget {
  const WallpaperDetailsScreen({super.key, required this.photo});
  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downloadStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallpaper Details'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              photo.src?.portrait ?? photo.portrait ?? '',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: status == DownloadStatus.downloading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () async {
                      final permission = await Permission.storage.request();
                      if (permission.isGranted) {
                        ref.read(downloadStatusProvider.notifier).state = DownloadStatus.downloading;
                        try {
                          final client = http.Client();
                          final response = await client.get(Uri.parse(photo.src?.original ?? ''));
                          final bytes = response.bodyBytes;
                          client.close();
                          final tempDir = await getTemporaryDirectory();
                          final tempPath = tempDir.path;
                          final file = File('$tempPath/${photo.id}.jpg');
                          await file.writeAsBytes(bytes);
                          // Save the image to the gallery
                          final result = await ImageGallerySaver.saveFile(file.path);
                          if (result['isSuccess']) {
                            ref.read(downloadStatusProvider.notifier).state = DownloadStatus.success;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallpaper downloaded and saved to the gallery'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save the wallpaper to the gallery'),
                              ),
                            );
                          }
                          // final file = File('$tempPath/${photo.id}.jpg');
                          // await file.writeAsBytes(bytes);
                        } catch (e) {
                          // If there is an error, update the download status to error and show a snackbar with the error message
                          ref.read(downloadStatusProvider.notifier).state = DownloadStatus.error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      } else {
                        // If the permission is not granted, show a snackbar with a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Storage permission is required to download wallpapers'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: ElevatedButton.icon(
              onPressed: () async {
                final database = ref.read(databaseProvider).value;
                await database?.insert(
                  'favorites',
                  photo.toJson(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    action: SnackBarAction(
                        label: 'Open',
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                            return const FavoriteScreen();
                          }));
                        }),
                    content: const Text('Wallpaper added to favorites'),
                  ),
                );
                // Pop the screen and return true as the result
                // Navigator.pop(context, true);
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Favorite'),
            ),
          ),
          // A widget that displays a circular progress indicator if the download status is downloading
          if (status == DownloadStatus.downloading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
