import 'package:flutter/material.dart';

/// Category model for the sales filter row
class SalesCategory {
  final String id;
  final String name;
  final IconData icon;

  const SalesCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Catalog product item matching the Sales UI design
class SalesProductItem {
  final String id;
  final String name;
  final String weight;
  final String category;
  final double price;
  final double mrp;
  final int stock;
  final bool isLowStock;
  final String barcode;
  final String sku;
  final String? imageUrl;
  final IconData placeholderIcon;
  final Color themeColor;

  const SalesProductItem({
    required this.id,
    required this.name,
    required this.weight,
    required this.category,
    required this.price,
    required this.mrp,
    required this.stock,
    this.isLowStock = false,
    required this.barcode,
    required this.sku,
    this.imageUrl,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.themeColor = const Color(0xFF10B981),
  });

  String get displayNameWithWeight => '$name $weight';
}

/// Cart line item in the Current Bill panel
class SalesCartItem {
  final SalesProductItem product;
  int quantity;
  double rate;

  SalesCartItem({
    required this.product,
    this.quantity = 1,
    required this.rate,
  });

  double get amount => quantity * rate;
}

/// Predefined categories from the reference design
const List<SalesCategory> kSalesCategories = [
  SalesCategory(id: 'all', name: 'All', icon: Icons.grid_view_rounded),
  SalesCategory(id: 'beverages', name: 'Beverages', icon: Icons.local_drink_outlined),
  SalesCategory(id: 'snacks', name: 'Snacks', icon: Icons.cookie_outlined),
  SalesCategory(id: 'dairy', name: 'Dairy', icon: Icons.egg_outlined),
  SalesCategory(id: 'grocery', name: 'Grocery', icon: Icons.shopping_bag_outlined),
  SalesCategory(id: 'personal_care', name: 'Personal Care', icon: Icons.spa_outlined),
  SalesCategory(id: 'household', name: 'Household', icon: Icons.cleaning_services_outlined),
  SalesCategory(id: 'others', name: 'Others', icon: Icons.sell_outlined),
];

/// Pre-populated list of exact products shown in the UI image
final List<SalesProductItem> kDefaultSalesProducts = [
  const SalesProductItem(
    id: 'sp_001',
    name: 'Coca Cola',
    weight: '500 ml',
    category: 'beverages',
    price: 40.00,
    mrp: 45.00,
    stock: 85,
    isLowStock: false,
    barcode: '5449000200427',
    sku: 'CC-500ML',
    imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.local_drink_outlined,
    themeColor: Color(0xFFDC2626),
  ),
  const SalesProductItem(
    id: 'sp_002',
    name: 'Parle-G Biscuit',
    weight: '200 g',
    category: 'snacks',
    price: 28.00,
    mrp: 30.00,
    stock: 140,
    isLowStock: false,
    barcode: '8901719570017',
    sku: 'PG-200G',
    imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.cookie_outlined,
    themeColor: Color(0xFFD97706),
  ),
  const SalesProductItem(
    id: 'sp_003',
    name: 'Amul Gold Milk',
    weight: '1 L',
    category: 'dairy',
    price: 62.00,
    mrp: 66.00,
    stock: 50,
    isLowStock: false,
    barcode: '8901262000012',
    sku: 'AML-GLD-1L',
    imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.water_drop_outlined,
    themeColor: Color(0xFF2563EB),
  ),
  const SalesProductItem(
    id: 'sp_004',
    name: 'Maggi Noodles',
    weight: '70 g',
    category: 'snacks',
    price: 15.00,
    mrp: 15.00,
    stock: 120,
    isLowStock: false,
    barcode: '8901000100712',
    sku: 'MAG-70G',
    imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.ramen_dining_outlined,
    themeColor: Color(0xFFEAB308),
  ),
  const SalesProductItem(
    id: 'sp_005',
    name: "Lay's Classic",
    weight: '52 g',
    category: 'snacks',
    price: 20.00,
    mrp: 20.00,
    stock: 95,
    isLowStock: false,
    barcode: '8901493000123',
    sku: 'LAY-CLS-52G',
    imageUrl: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.fastfood_outlined,
    themeColor: Color(0xFFF59E0B),
  ),
  const SalesProductItem(
    id: 'sp_006',
    name: 'Britannia Bread',
    weight: '400 g',
    category: 'dairy',
    price: 35.00,
    mrp: 40.00,
    stock: 4,
    isLowStock: true,
    barcode: '8901063012019',
    sku: 'BRT-BRD-400G',
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.bakery_dining_outlined,
    themeColor: Color(0xFFB45309),
  ),
  const SalesProductItem(
    id: 'sp_007',
    name: 'Surf Excel',
    weight: '1 kg',
    category: 'household',
    price: 210.00,
    mrp: 235.00,
    stock: 40,
    isLowStock: false,
    barcode: '8901030061108',
    sku: 'SRF-1KG',
    imageUrl: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.cleaning_services_outlined,
    themeColor: Color(0xFF0284C7),
  ),
  const SalesProductItem(
    id: 'sp_008',
    name: 'Dove Soap',
    weight: '100 g',
    category: 'personal_care',
    price: 48.00,
    mrp: 55.00,
    stock: 75,
    isLowStock: false,
    barcode: '8901030859152',
    sku: 'DOV-100G',
    imageUrl: 'https://images.unsplash.com/photo-1607006483224-114eb16e3ff5?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.soap_outlined,
    themeColor: Color(0xFF4F46E5),
  ),
  const SalesProductItem(
    id: 'sp_009',
    name: 'Colgate Toothpaste',
    weight: '200 g',
    category: 'personal_care',
    price: 105.00,
    mrp: 120.00,
    stock: 65,
    isLowStock: false,
    barcode: '8901314010014',
    sku: 'CLG-200G',
    imageUrl: 'https://images.unsplash.com/photo-1559591937-e1032c2545d6?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.brush_outlined,
    themeColor: Color(0xFFEF4444),
  ),
  const SalesProductItem(
    id: 'sp_010',
    name: 'Tata Salt',
    weight: '1 kg',
    category: 'grocery',
    price: 22.00,
    mrp: 25.00,
    stock: 180,
    isLowStock: false,
    barcode: '8901058852271',
    sku: 'TAT-SLT-1KG',
    imageUrl: 'https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.grain_outlined,
    themeColor: Color(0xFF6366F1),
  ),
  const SalesProductItem(
    id: 'sp_011',
    name: 'Aashirvaad Atta',
    weight: '1 kg',
    category: 'grocery',
    price: 55.00,
    mrp: 60.00,
    stock: 90,
    isLowStock: false,
    barcode: '8901725181207',
    sku: 'ASH-ATT-1KG',
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.shopping_bag_outlined,
    themeColor: Color(0xFFD97706),
  ),
  const SalesProductItem(
    id: 'sp_012',
    name: 'Dettol Liquid',
    weight: '500 ml',
    category: 'personal_care',
    price: 175.00,
    mrp: 195.00,
    stock: 55,
    isLowStock: false,
    barcode: '8901396112014',
    sku: 'DTL-500ML',
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300&auto=format&fit=crop&q=80',
    placeholderIcon: Icons.sanitizer_outlined,
    themeColor: Color(0xFF059669),
  ),
];

/// Helper returning initial reference test cart items matching financial assertions
List<SalesCartItem> createDefaultTestCartItems() => [
  SalesCartItem(
    product: kDefaultSalesProducts.firstWhere((p) => p.id == 'sp_002'),
    quantity: 2,
    rate: 28.00,
  ),
  SalesCartItem(
    product: kDefaultSalesProducts.firstWhere((p) => p.id == 'sp_003'),
    quantity: 1,
    rate: 62.00,
  ),
  SalesCartItem(
    product: kDefaultSalesProducts.firstWhere((p) => p.id == 'sp_004'),
    quantity: 3,
    rate: 15.00,
  ),
  SalesCartItem(
    product: kDefaultSalesProducts.firstWhere((p) => p.id == 'sp_001'),
    quantity: 1,
    rate: 40.00,
  ),
];

