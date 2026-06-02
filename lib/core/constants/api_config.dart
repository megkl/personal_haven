class ApiConfig {
  static const String baseUrl = 'https://api.personalhaven.com/v1';
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}