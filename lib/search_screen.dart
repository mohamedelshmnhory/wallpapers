import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:wallpaper/photo.dart';
import 'package:wallpaper/wallpaper_datails_screen.dart';

import 'favourites_screen.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Photo>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final client = http.Client();
  final response = await client.get(
    Uri.parse('https://api.pexels.com/v1/search?query=$query'),
    headers: {'Authorization': 'iPWDgXWrmom0R62xg5RffnManopWBiS177ItGwXEWhDYjth0KooM7IIq'},
  );
  client.close();
  final data = jsonDecode(response.body);
  final photos = (data['photos'] as List).map<Photo>((photo) => Photo.fromJson(photo)).toList();
  return photos;
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Wallpapers')),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Enter a keyword',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final results = ref.watch(searchResultsProvider);
              return Expanded(
                child: results.when(
                  data: (photos) {
                    return GridView.builder(
                      itemCount: photos.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
                              return WallpaperDetailsScreen(photo: photo);
                            }));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: Image.network(
                                      photo.src?.portrait ?? '',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10.0,
                                  left: 10.0,
                                  child: IconButton(
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
                                    },
                                    icon: const Icon(Icons.favorite, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
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
            },
          ),
        ],
      ),
    );
  }
}
