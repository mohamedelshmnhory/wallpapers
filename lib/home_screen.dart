import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favourites_screen.dart';
import 'photo.dart';
import 'search_screen.dart';
import 'wallpaper_datails_screen.dart';

int currentPage = 1;
int perPage = 30;

final wallpapersProvider = FutureProvider<List<Photo>>((ref) async {
  final client = http.Client();
  final response = await client.get(
    Uri.parse('https://api.pexels.com/v1/curated?per_page=$perPage&page=$currentPage'),
    headers: {'Authorization': 'iPWDgXWrmom0R62xg5RffnManopWBiS177ItGwXEWhDYjth0KooM7IIq'},
  );
  client.close();
  final data = jsonDecode(response.body);
  final photos = data['photos'].map<Photo>((photo) => Photo.fromJson(photo)).toList();
  return photos;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ScrollController();
    final wallpapers = ref.watch(wallpapersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallpaper App'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                return const SearchScreen();
              }));
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                return const FavoriteScreen();
              }));
            },
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
      body: wallpapers.when(
        data: (photos) {
          return GridView.builder(
            controller: scrollController,
            itemCount: photos.length + 1, // Add 1 for the load more button
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index == photos.length) {
                return IconButton(
                  onPressed: () {
                    currentPage++;
                    ref.refresh(wallpapersProvider);
                    scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 70),
                );
              } else {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                      return WallpaperDetailsScreen(photo: photo);
                    }));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        photo.src?.portrait ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }
}
