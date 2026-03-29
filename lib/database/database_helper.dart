import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'posts_database.db');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) => print('Database opened successfully'),
      );
    } catch (e) {
      throw Exception('Database initialization failed: $e');
    }
  }

  // Create table
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE posts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
      print('Posts table created successfully');
    } catch (e) {
      throw Exception('Failed to create table: $e');
    }
  }

  // CREATE - Insert new post
  Future<int> insertPost(Post post) async {
    try {
      Database db = await database;
      return await db.insert(
        'posts',
        post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert post: $e');
    }
  }

  // READ - Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        'posts',
        orderBy: 'created_at DESC', // Show newest first
      );
      
      return List.generate(maps.length, (i) {
        return Post.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // READ - Get single post by ID
  Future<Post?> getPostById(int id) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        'posts',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Post.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  // UPDATE - Update existing post
  Future<int> updatePost(Post post) async {
    try {
      Database db = await database;
      return await db.update(
        'posts',
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // DELETE - Delete post
  Future<int> deletePost(int id) async {
    try {
      Database db = await database;
      return await db.delete(
        'posts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // DELETE - Delete all posts (optional feature)
  Future<int> deleteAllPosts() async {
    try {
      Database db = await database;
      return await db.delete('posts');
    } catch (e) {
      throw Exception('Failed to delete all posts: $e');
    }
  }

  // Search posts by title or content
  Future<List<Post>> searchPosts(String query) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps = await db.query(
        'posts',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Post.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // Get post count
  Future<int> getPostCount() async {
    try {
      Database db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM posts');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get post count: $e');
    }
  }
}