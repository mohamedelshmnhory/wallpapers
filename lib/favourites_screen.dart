import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallpaper/photo.dart';
import 'package:wallpaper/wallpaper_datails_screen.dart';

// A provider to get the database instance
final databaseProvider = FutureProvider<Database>((ref) {
  // Open the database and create a table for favorite photos if it does not exist
  final database = openDatabase(
    'favorites.db',
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE favorites(id INTEGER PRIMARY KEY, url TEXT, portrait TEXT)',
      );
    },
    version: 1,
  );
  // Return the database instance
  return database;
});

final favoritesProvider = FutureProvider.autoDispose<List<Photo>>((ref) async {
  final database = ref.watch(databaseProvider).value;
  final maps = await database?.query('favorites');
  final photos = maps?.map<Photo>((map) => Photo.fromJson(map)).toList();
  return photos ?? [];
});

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Wallpapers'),
      ),
      body: favorites.when(
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
                            photo.portrait ?? '',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10.0,
                        left: 10.0,
                        child: IconButton(
                          onPressed: () async {
                            // Get the database instance from the databaseProvider
                            final database = ref.read(databaseProvider).value;
                            // Insert the photo object into the favorites table
                            await database?.delete('favorites', where: 'id = ?', whereArgs: [photo.id]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallpaper removed from favorites'),
                              ),
                            );
                            ref.refresh(favoritesProvider);
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
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
          // If there is an error, show a text widget with the error message
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }
}
