/// Template universal untuk proyek baru.
///
/// Nama kategori HARUS sama dengan `ProjectsViewModel.categories`
/// supaya filter kategori di halaman Proyek tetap cocok.
class ProjectTemplate {
  final String category;
  final String summary;
  final List<String> defaultTasks;

  const ProjectTemplate({
    required this.category,
    required this.summary,
    required this.defaultTasks,
  });

  static const String software = 'Software / App Development';
  static const String business = 'Business Plan & Startup';
  static const String academic = 'Makalah, Proposal, & Riset Ilmiah';
  static const String creative = 'Creative, Media / Desain';
  static const String general = 'Catatan Bebas / General';

  static const List<ProjectTemplate> all = [
    ProjectTemplate(
      category: software,
      summary: 'Dari ide aplikasi sampai dokumentasi dan presentasi.',
      defaultTasks: [
        'Tentukan ide & target pengguna',
        'Rancang fitur & user flow',
        'Desain UI/UX (wireframe)',
        'Rancang database & arsitektur',
        'Implementasi fitur inti',
        'Pengujian & perbaikan bug',
        'Dokumentasi & presentasi',
      ],
    ),
    ProjectTemplate(
      category: business,
      summary: 'Riset pasar, model bisnis, sampai pitch deck.',
      defaultTasks: [
        'Riset masalah & pasar',
        'Rumuskan value proposition',
        'Analisis kompetitor',
        'Susun model bisnis (BMC)',
        'Susun rencana keuangan',
        'Rancang strategi pemasaran',
        'Siapkan pitch deck',
      ],
    ),
    ProjectTemplate(
      category: academic,
      summary: 'Kerangka tulisan ilmiah dari topik sampai daftar pustaka.',
      defaultTasks: [
        'Tentukan topik & rumusan masalah',
        'Kumpulkan referensi / literatur',
        'Susun kerangka tulisan',
        'Tulis pendahuluan',
        'Tulis pembahasan',
        'Tulis kesimpulan & daftar pustaka',
        'Revisi & proofreading',
      ],
    ),
    ProjectTemplate(
      category: creative,
      summary: 'Konsep, produksi aset, review, sampai finalisasi.',
      defaultTasks: [
        'Tentukan konsep & moodboard',
        'Riset referensi visual',
        'Buat sketsa / draft awal',
        'Produksi aset utama',
        'Review & revisi',
        'Finalisasi & ekspor',
      ],
    ),
    ProjectTemplate(
      category: general,
      summary: 'Catatan bebas dengan beberapa langkah awal.',
      defaultTasks: [
        'Catat ide utama',
        'Kumpulkan referensi',
        'Tentukan langkah selanjutnya',
      ],
    ),
  ];

  static ProjectTemplate byCategory(String category) {
    return all.firstWhere(
      (template) => template.category == category,
      orElse: () => all.last,
    );
  }
}
