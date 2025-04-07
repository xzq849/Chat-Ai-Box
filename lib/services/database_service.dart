import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/provider.dart';

/// 数据库服务类
/// 负责管理本地SQLite数据库
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  
  // 数据库版本
  static const int _databaseVersion = 1;
  
  // 表名
  static const String tableChats = 'chats';
  static const String tableMessages = 'messages';
  static const String tableProviders = 'providers';
  
  // 单例模式
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }
  
  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ai_chat_app.db');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建提供商表
    await db.execute('''
      CREATE TABLE $tableProviders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        apiKey TEXT NOT NULL,
        baseUrl TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        config TEXT NOT NULL
      )
    ''');
    
    // 创建聊天表
    await db.execute('''
      CREATE TABLE $tableChats (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        providerId TEXT NOT NULL,
        settings TEXT,
        isPinned INTEGER NOT NULL,
        isArchived INTEGER NOT NULL,
        FOREIGN KEY (providerId) REFERENCES $tableProviders (id) ON DELETE CASCADE
      )
    ''');
    
    // 创建消息表
    await db.execute('''
      CREATE TABLE $tableMessages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        sender TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        imageUrl TEXT,
        fileUrl TEXT,
        metadata TEXT,
        chatId TEXT NOT NULL,
        replyToId TEXT,
        FOREIGN KEY (chatId) REFERENCES $tableChats (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // ==================== 提供商相关操作 ====================
  
  /// 插入或更新提供商
  Future<void> upsertProvider(Provider provider) async {
    final db = await database;
    
    // 将config转换为JSON字符串
    final providerMap = provider.toMap();
    providerMap['config'] = jsonEncode(providerMap['config']);
    
    await db.insert(
      tableProviders,
      providerMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 获取所有提供商
  Future<List<Provider>> getAllProviders() async {
    final db = await database;
    final maps = await db.query(tableProviders);
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
      // 解析config字段
      if (map['config'] != null) {
        map['config'] = jsonDecode(map['config'] as String);
      }
      
      return Provider.fromMap(map);
    });
  }
  
  /// 获取指定ID的提供商
  Future<Provider?> getProviderById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableProviders,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    // 解析config字段
    if (map['config'] != null) {
      map['config'] = jsonDecode(map['config'] as String);
    }
    
    return Provider.fromMap(map);
  }
  
  /// 删除提供商
  Future<void> deleteProvider(String id) async {
    final db = await database;
    await db.delete(
      tableProviders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ==================== 聊天相关操作 ====================
  
  /// 插入或更新聊天
  Future<void> upsertChat(Chat chat) async {
    final db = await database;
    
    // 将settings转换为JSON字符串
    final chatMap = chat.toMap();
    if (chatMap['settings'] != null) {
      chatMap['settings'] = jsonEncode(chatMap['settings']);
    }
    
    await db.insert(
      tableChats,
      chatMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 获取所有聊天
  Future<List<Chat>> getAllChats() async {
    final db = await database;
    final maps = await db.query(
      tableChats,
      orderBy: 'updatedAt DESC',
    );
    
    return List.generate(maps.length, (i) {
      final map = maps[i];
      // 解析settings字段
      if (map['settings'] != null) {
        map['settings'] = jsonDecode(map['settings'] as String);
      }
      
      return Chat.fromMap(map);
    });
  }
  
  /// 获取指定ID的聊天，包括其所有消息
  Future<Chat?> getChatWithMessages(String id) async {
    final db = await database;
    final chatMaps = await db.query(
      tableChats,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (chatMaps.isEmpty) return null;
    
    final chatMap = chatMaps.first;
    // 解析settings字段
    if (chatMap['settings'] != null) {
      chatMap['settings'] = jsonDecode(chatMap['settings'] as String);
    }
    
    // 获取聊天的所有消息
    final messageMaps = await db.query(
      tableMessages,
      where: 'chatId = ?',
      whereArgs: [id],
      orderBy: 'timestamp ASC',
    );
    
    final messages = messageMaps.map((map) {
      // 解析metadata字段
      if (map['metadata'] != null) {
        map['metadata'] = jsonDecode(map['metadata'] as String);
      }
      return Message.fromMap(map);
    }).toList();
    
    return Chat.fromMap(chatMap, messages: messages);
  }
  
  /// 删除聊天
  Future<void> deleteChat(String id) async {
    final db = await database;
    await db.delete(
      tableChats,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ==================== 消息相关操作 ====================
  
  /// 插入或更新消息
  Future<void> upsertMessage(Message message) async {
    final db = await database;
    
    // 将metadata转换为JSON字符串
    final messageMap = message.toMap();
    if (messageMap['metadata'] != null) {
      messageMap['metadata'] = jsonEncode(messageMap['metadata']);
    }
    
    await db.insert(
      tableMessages,
      messageMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 批量插入消息
  Future<void> batchInsertMessages(List<Message> messages) async {
    final db = await database;
    final batch = db.batch();
    
    for (final message in messages) {
      // 将metadata转换为JSON字符串
      final messageMap = message.toMap();
      if (messageMap['metadata'] != null) {
        messageMap['metadata'] = jsonEncode(messageMap['metadata']);
      }
      
      batch.insert(
        tableMessages,
        messageMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  /// 获取指定聊天的所有消息
  Future<List<Message>> getMessagesByChatId(String chatId) async {
    final db = await database;
    final maps = await db.query(
      tableMessages,
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    
    return maps.map((map) {
      // 解析metadata字段
      if (map['metadata'] != null) {
        map['metadata'] = jsonDecode(map['metadata'] as String);
      }
      return Message.fromMap(map);
    }).toList();
  }
  
  /// 删除消息
  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      tableMessages,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 删除指定聊天的所有消息
  Future<void> deleteMessagesByChatId(String chatId) async {
    final db = await database;
    await db.delete(
      tableMessages,
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }
  
  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    db.close();
  }