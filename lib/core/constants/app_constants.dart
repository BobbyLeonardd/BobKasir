abstract class AppConstants {
  static const String appName = 'BobKasir';
  static const String appVersion = '1.0.0';
  static const String companyName = 'StarCyberCompany';
  static const int releaseYear = 2026;

  // Subscription
  static const int trialDays = 7;
  static const int weeklyPriceCents = 30000; // Rp 30.000
  static const int monthlyPriceCents = 100000; // Rp 100.000
  static const int weeklyDays = 7;
  static const int monthlyDays = 30;

  // Printer
  static const int paper58mmChars = 32;
  static const int paper80mmChars = 48;

  // Pagination
  static const int pageSize = 20;

  // Sync
  static const int syncRetryMax = 3;

  // API base — ganti saat deploy ke production
  // PENTING: Emulator Android gunakan 10.0.2.2 (bukan localhost)
  // Device fisik gunakan IP komputer (misal: 192.168.1.x)
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';
  static const int apiTimeoutMs = 30000;

  // Midtrans (Sandbox)
  static const String midtransClientKey = 'Mid-client-tPgNA6HHSLs9lMwn';
  static const String midtransSnapUrl = 'https://app.sandbox.midtrans.com/snap/snap.js';
  static const bool midtransIsProduction = false;

  // Local DB
  static const String dbName = 'bobkasir_local.db';
  static const int dbVersion = 1;
}
