import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import 'medicine_detail_page.dart';

final List<Medicine> mockMedicinesList = [
  Medicine(
    id: 'med-1',
    name: 'Paracetamol 500mg',
    genericName: 'Paracetamol',
    description: 'Obat pereda nyeri dan penurun demam umum',
    category: 'Umum',
    price: 15000,
    stock: 100,
    unit: 'Strip (10 tablet)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-2',
    name: 'Amlodipine 5mg',
    genericName: 'Amlodipine Besylate',
    description: 'Obat untuk menurunkan tekanan darah tinggi (hipertensi)',
    category: 'Jantung',
    price: 45000,
    stock: 50,
    unit: 'Strip (10 tablet)',
    requiresPrescription: true,
    image: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-3',
    name: 'Ibuprofen Sirup Anak',
    genericName: 'Ibuprofen',
    description: 'Obat penurun panas dan pereda nyeri khusus untuk anak-anak',
    category: 'Anak',
    price: 35000,
    stock: 75,
    unit: 'Botol (60 ml)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-4',
    name: 'Insto Regular 7.5ml',
    genericName: 'Tetrahydrozoline HCl',
    description: 'Obat tetes mata untuk mengatasi mata merah dan iritasi ringan',
    category: 'Mata',
    price: 15000,
    stock: 80,
    unit: 'Botol (7.5 ml)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-5',
    name: 'Neurobion Forte',
    genericName: 'Vitamin B Complex',
    description: 'Suplemen vitamin saraf untuk mengatasi kebas dan kesemutan',
    category: 'Saraf',
    price: 45000,
    stock: 120,
    unit: 'Strip (10 tablet)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-6',
    name: 'Betadine Antiseptik',
    genericName: 'Povidone Iodine',
    description: 'Cairan antiseptik untuk mencegah infeksi pada luka bedah atau sayatan',
    category: 'Bedah',
    price: 25000,
    stock: 90,
    unit: 'Botol (30 ml)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-7',
    name: 'Cooling 5 Plus',
    genericName: 'Benzocaine, Phenol',
    description: 'Obat semprot untuk meredakan sakit gigi dan radang gusi',
    category: 'Gigi',
    price: 35000,
    stock: 60,
    unit: 'Botol Spray (15 ml)',
    requiresPrescription: false,
    image: 'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
  Medicine(
    id: 'med-8',
    name: 'Iliadin Nasal Spray',
    genericName: 'Oxymetazoline HCl',
    description: 'Semprotan hidung untuk mengatasi hidung tersumbat',
    category: 'THT',
    price: 65000,
    stock: 40,
    unit: 'Botol Spray (10 ml)',
    requiresPrescription: true,
    image: 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=500&q=80',
    pharmacyId: 'pharm-1',
  ),
];

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua Kategori';

  final List<String> _categories = [
    'Semua Kategori',
    'Umum',
    'Jantung',
    'Anak',
    'Mata',
    'Saraf',
    'Bedah',
    'Gigi',
    'THT',
  ];

  @override
  Widget build(BuildContext context) {
    // Filtered medicines
    final filtered = mockMedicinesList.where((med) {
      final matchesSearch = med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.genericName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua Kategori' || med.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Apotek Online 💊'),
        actions: [
          Consumer<AppProvider>(
            builder: (ctx, app, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/patient/cart'),
                  ),
                  if (app.cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${app.cartCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Cari obat atau produk kesehatan...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.surfaceDim,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: AppTheme.primary.withOpacity(0.15),
                          backgroundColor: AppTheme.surfaceDim,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Medicines Grid
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Tidak ada produk ditemukan',
                    subtitle: 'Coba ubah kata kunci atau filter kategori Anda.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final med = filtered[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicineDetailPage(medicine: med),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: AppTheme.surfaceDim,
                                  child: Image.network(
                                    med.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.local_pharmacy,
                                        size: 40,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (med.requiresPrescription)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Resep Dokter',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      med.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      med.unit,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatPrice(med.price),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        Consumer<AppProvider>(
                                          builder: (ctx, app, _) {
                                            return SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(
                                                  Icons.add_shopping_cart,
                                                  size: 18,
                                                  color: AppTheme.primary,
                                                ),
                                                onPressed: () {
                                                  app.addToCart(med);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('${med.name} ditambahkan ke keranjang'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
