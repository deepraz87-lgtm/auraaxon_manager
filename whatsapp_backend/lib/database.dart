import 'package:mysql1/mysql1.dart';
import 'env.dart';

class DatabaseHelper {
  static MySqlConnection? _connection;

  static Future<MySqlConnection> getConnection() async {
    if (_connection != null) return _connection!;

    final settings = ConnectionSettings(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.parse(env['DB_PORT'] ?? '3306'),
      user: env['DB_USER'] ?? 'root',
      password: env['DB_PASSWORD'] ?? '',
      db: env['DB_NAME'] ?? 'auraaxon_leads',
    );

    _connection = await MySqlConnection.connect(settings);

    // Ensure the leads table exists
    await _connection!.query('''
      CREATE TABLE IF NOT EXISTS leads (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(20) NOT NULL UNIQUE,
        profile_name VARCHAR(255),
        last_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
    ''');

    return _connection!;
  }

  static Future<void> saveOrUpdateLead(String phoneNumber, String? profileName, String message) async {
    final conn = await getConnection();
    
    final existingLead = await conn.query(
      'SELECT id FROM leads WHERE phone_number = ?',
      [phoneNumber],
    );

    if (existingLead.isNotEmpty) {
      // Update existing lead
      await conn.query(
        'UPDATE leads SET profile_name = ?, last_message = ? WHERE phone_number = ?',
        [profileName, message, phoneNumber],
      );
    } else {
      // Insert new lead
      await conn.query(
        'INSERT INTO leads (phone_number, profile_name, last_message) VALUES (?, ?, ?)',
        [phoneNumber, profileName, message],
      );
    }
  }
}
