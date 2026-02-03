import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (creates if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('personal_haven.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }


  /// Create all tables
  Future<void> _createDB(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE,
        first_name TEXT,
        bio TEXT,
        last_name TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        is_premium INTEGER DEFAULT 0,
        preferences_json TEXT
      )
    ''');

    // User credentials table (separate for security)
    await db.execute('''
      CREATE TABLE user_credentials (
        user_id TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Biometric settings table
    await db.execute('''
      CREATE TABLE biometric_settings (
        user_id TEXT PRIMARY KEY,
        is_enabled INTEGER NOT NULL DEFAULT 0,
        biometric_type TEXT,
        last_used TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Journal Entry table
    await db.execute('''
      CREATE TABLE journal_entries (
        entry_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        is_private INTEGER DEFAULT 1,
        location_data TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        category TEXT,
        emoji TEXT,
        tags TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Mood Log table
    await db.execute('''
      CREATE TABLE mood_logs (
        mood_log_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        mood_level INTEGER NOT NULL,
        mood_label_id TEXT,
        mood_emoji TEXT,
        timestamp TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Mood Label table
    await db.execute('''
      CREATE TABLE mood_labels (
        mood_label_id TEXT PRIMARY KEY,
        label_name TEXT UNIQUE NOT NULL,
        icon_code TEXT
      )
    ''');

    // Habit table
    await db.execute('''
      CREATE TABLE habits (
        habit_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        goal_value INTEGER,
        goal_unit TEXT,
        start_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Habit Tracking table
    await db.execute('''
      CREATE TABLE habit_tracking (
        tracking_id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        log_date TEXT NOT NULL,
        actual_value INTEGER,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES habits (habit_id) ON DELETE CASCADE
      )
    ''');

    // Budget table
    await db.execute('''
      CREATE TABLE budgets (
        budget_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        total_income REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Transaction table
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        budget_id TEXT,
        category_id TEXT,
        amount REAL NOT NULL,
        transaction_type TEXT NOT NULL,
        description TEXT,
        transaction_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
        FOREIGN KEY (budget_id) REFERENCES budgets (budget_id) ON DELETE SET NULL
      )
    ''');

    // Goal table
    await db.execute('''
      CREATE TABLE goals (
        goal_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        target_value REAL,
        current_value REAL DEFAULT 0.0,
        unit TEXT,
        start_date TEXT NOT NULL,
        target_date TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Event/Calendar table
    await db.execute('''
      CREATE TABLE events (
        event_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        event_date TEXT NOT NULL,
        event_time TEXT,
        category TEXT,
        is_completed INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Task table
    await db.execute('''
      CREATE TABLE tasks (
        task_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER DEFAULT 0,
        due_date TEXT,
        priority TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await _createIndexes(db);

    // Insert default mood labels
    await _insertDefaultMoodLabels(db);
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute(
      'CREATE INDEX idx_journal_user_date ON journal_entries(user_id, entry_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_mood_user_timestamp ON mood_logs(user_id, timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_habit_user ON habits(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_user_date ON transactions(user_id, transaction_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_task_user_completed ON tasks(user_id, is_completed)',
    );
  }

  /// Insert default mood labels
  Future<void> _insertDefaultMoodLabels(Database db) async {
    final moodLabels = [
      {'mood_label_id': '1', 'label_name': 'Happy', 'icon_code': '😊'},
      {'mood_label_id': '2', 'label_name': 'Sad', 'icon_code': '😢'},
      {'mood_label_id': '3', 'label_name': 'Anxious', 'icon_code': '😰'},
      {'mood_label_id': '4', 'label_name': 'Calm', 'icon_code': '😌'},
      {'mood_label_id': '5', 'label_name': 'Energetic', 'icon_code': '⚡'},
      {'mood_label_id': '6', 'label_name': 'Tired', 'icon_code': '😴'},
      {'mood_label_id': '7', 'label_name': 'Stressed', 'icon_code': '😫'},
      {'mood_label_id': '8', 'label_name': 'Grateful', 'icon_code': '🙏'},
    ];

    for (final label in moodLabels) {
      await db.insert('mood_labels', label);
    }
  }

  /// Handle database upgrades
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when schema changes
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE users ADD COLUMN new_field TEXT');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Delete database (useful for testing or reset)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'personal_haven.db');
    await deleteDatabase(path);
    _database = null;
  }
}