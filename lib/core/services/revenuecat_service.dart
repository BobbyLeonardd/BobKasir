import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const String _androidApiKey = 'test_UletyhiypyFNgagYifcFICBybNW'; 
  static const String _entitlementId = 'premium'; // Set your entitlement ID from RevenueCat dashboard here

  static final _customerInfoController = StreamController<CustomerInfo>.broadcast();
  static Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  static Future<void> init() async {
    if (kIsWeb) return; // RevenueCat does not support web
    
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_androidApiKey);
    } 

    if (configuration != null) {
      await Purchases.configure(configuration);
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfoController.add(customerInfo);
      });
    }
  }

  static Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      debugPrint('Error fetching offerings: \$e');
    }
    return [];
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final params = PurchaseParams.package(package);
      final result = await Purchases.purchase(params);
      return result.customerInfo.entitlements.all[_entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint('Error purchasing package: \$e');
      return false;
    }
  }
}
