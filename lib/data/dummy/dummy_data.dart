import '../../core/date_utils.dart';
import '../../domain/models/archive_model.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/course_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/group_member_model.dart';
import '../../domain/models/group_model.dart';
import '../../domain/models/note_model.dart';
import '../../domain/models/reference_model.dart';
import '../../domain/models/submission_model.dart';
import '../../domain/models/task_step_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/work_item_model.dart';
import '../../domain/models/workspace_model.dart';
import 'template_catalog.dart';

/// Data contoh yang saling berelasi (lewat ID). Dibuat sekali saat aplikasi pertama dijalankan
/// atau saat pengguna memilih "Reset ke Data Contoh" di Profil.
///
/// Berisi: 8 mata kuliah, 11 penugasan (individu + kelompok, aktif, selesai, terlambat, diarsipkan),
/// tahapan, catatan, dokumen, referensi, 3 kelompok beserta anggota, pekerjaan, dan pengumpulan hasil.
class DummyData {
  DummyData._();

  static Map<String, dynamic> build() {
    final now = DateTime.now();
    final today = dateOnly(now);
    DateTime day(int offset) => today.add(Duration(days: offset));
    DateTime at(int daysAgo) => now.subtract(Duration(days: daysAgo));

    const user = UserModel(
      id: 'user-1',
      name: 'Andi Pratama',
      nim: '2210512045',
      university: 'Universitas Teknologi Nusantara',
      faculty: 'Fakultas Ilmu Komputer',
      studyProgram: 'Teknik Informatika',
      semester: 5,
    );

    const courses = <CourseModel>[
      CourseModel(id: 'c1', name: 'Pemrograman Mobile', semester: 5, academicYear: '2026/2027'),
      CourseModel(id: 'c2', name: 'Machine Learning', semester: 5, academicYear: '2026/2027'),
      CourseModel(id: 'c3', name: 'Sistem Informasi Geografis', semester: 5, academicYear: '2026/2027'),
      CourseModel(id: 'c4', name: 'Kewirausahaan', semester: 5, academicYear: '2026/2027'),
      CourseModel(id: 'c5', name: 'Statistika', semester: 4, academicYear: '2025/2026'),
      CourseModel(id: 'c6', name: 'Basis Data', semester: 4, academicYear: '2025/2026'),
      CourseModel(id: 'c7', name: 'Interaksi Manusia dan Komputer', semester: 4, academicYear: '2025/2026'),
      CourseModel(id: 'c8', name: 'Jaringan Komputer', semester: 3, academicYear: '2024/2025'),
    ];

    final assignments = <AssignmentModel>[];
    final workspaces = <WorkspaceModel>[];
    final steps = <TaskStepModel>[];
    final notes = <NoteModel>[];
    final docs = <DocumentModel>[];
    final refs = <ReferenceModel>[];
    final groups = <GroupModel>[];
    final members = <GroupMemberModel>[];
    final items = <WorkItemModel>[];
    final subs = <SubmissionModel>[];
    final archives = <ArchiveModel>[];

    // ---------------------------------------------------------------- Pembantu

    void addAssignment({
      required String id,
      required String title,
      required String courseId,
      required String description,
      required AssignmentMode mode,
      required AssignmentPriority priority,
      required int deadlineDays,
      required AssignmentStatus status,
      required int createdDaysAgo,
      required int updatedDaysAgo,
      int? assignedDaysAgo,
      String? templateId,
      int? completedDaysAgo,
      int? archivedDaysAgo,
      String? groupId,
      String summary = '',
    }) {
      assignments.add(AssignmentModel(
        id: id,
        title: title,
        courseId: courseId,
        description: description,
        mode: mode,
        priority: priority,
        assignedDate: assignedDaysAgo == null ? null : day(-assignedDaysAgo),
        deadline: day(deadlineDays),
        templateId: templateId,
        templateTitle: templateId == null ? null : TemplateCatalog.byId(templateId)?.title,
        status: status,
        workspaceId: 'w-$id',
        groupId: groupId,
        createdAt: at(createdDaysAgo),
        updatedAt: at(updatedDaysAgo),
        completedAt: completedDaysAgo == null ? null : at(completedDaysAgo),
        archivedAt: archivedDaysAgo == null ? null : at(archivedDaysAgo),
      ));
      workspaces.add(WorkspaceModel(id: 'w-$id', assignmentId: id, finalSummary: summary, createdAt: at(createdDaysAgo)));
    }

    void addSteps(String id, List<String> titles, int done) {
      for (var i = 0; i < titles.length; i++) {
        steps.add(TaskStepModel(
          id: 's-$id-$i',
          workspaceId: 'w-$id',
          assignmentId: id,
          title: titles[i],
          isDone: i < done,
          order: i,
          createdAt: at(12),
          completedAt: i < done ? at(10 - i) : null,
        ));
      }
    }

    void addNote(String id, int n, String title, String content, {String author = 'Andi Pratama'}) {
      notes.add(NoteModel(
        id: 'n-$id-$n',
        workspaceId: 'w-$id',
        assignmentId: id,
        title: title,
        content: content,
        authorName: author,
        createdAt: at(9 - n),
        updatedAt: at(9 - n),
      ));
    }

    void addRef(String id, int n, String title, String url, ReferenceType type, {String note = ''}) {
      refs.add(ReferenceModel(
        id: 'r-$id-$n',
        workspaceId: 'w-$id',
        assignmentId: id,
        title: title,
        url: url,
        type: type,
        note: note,
        createdAt: at(8 - n),
      ));
    }

    void addTemplateDoc(String id, String templateId) {
      final t = TemplateCatalog.byId(templateId);
      if (t == null) return;
      docs.add(DocumentModel(
        id: 'd-$id-tpl',
        workspaceId: 'w-$id',
        assignmentId: id,
        title: t.title,
        fileName: t.fileName,
        extension: t.extension,
        kind: DocumentKind.draft,
        source: DocumentSource.template,
        assetPath: t.assetPath,
        templateId: t.id,
        createdAt: at(11),
        updatedAt: at(11),
      ));
    }

    void addTextDoc(String id, String key, String title, String text, DocumentKind kind, {int daysAgo = 5}) {
      docs.add(DocumentModel(
        id: 'd-$id-$key',
        workspaceId: 'w-$id',
        assignmentId: id,
        title: title,
        fileName: '$title.md',
        extension: 'md',
        kind: kind,
        source: DocumentSource.created,
        textContent: text,
        size: text.length,
        createdAt: at(daysAgo),
        updatedAt: at(daysAgo),
      ));
    }

    void addGroup(String id, String name, String code, List<List<Object>> people) {
      final gid = 'g-$id';
      groups.add(GroupModel(id: gid, assignmentId: id, name: name, inviteCode: code, createdAt: at(12)));
      // people: [nama, isOwner, isMe, diundang]
      for (var i = 0; i < people.length; i++) {
        members.add(GroupMemberModel(
          id: 'm-$id-${i + 1}',
          groupId: gid,
          name: people[i][0] as String,
          role: (people[i][1] as bool) ? MemberRole.pemilik : MemberRole.anggota,
          status: (people[i][3] as bool) ? MemberStatus.diundang : MemberStatus.aktif,
          isMe: people[i][2] as bool,
          joinedAt: at(12 - i),
        ));
      }
    }

    void addItem(String id, int n, String title, String desc, int assignee, int deadlineDays, WorkStatus status) {
      items.add(WorkItemModel(
        id: 'wi-$id-$n',
        groupId: 'g-$id',
        assignmentId: id,
        title: title,
        description: desc,
        assigneeId: 'm-$id-$assignee',
        deadline: day(deadlineDays),
        status: status,
        createdAt: at(10),
        updatedAt: at(2),
      ));
    }

    void addSub(String id, int itemNo, int member, String file, String note, ReviewStatus status, String reviewNote) {
      subs.add(SubmissionModel(
        id: 'sub-$id-$itemNo',
        workItemId: 'wi-$id-$itemNo',
        groupId: 'g-$id',
        memberId: 'm-$id-$member',
        fileName: file,
        note: note,
        submittedAt: at(3),
        reviewStatus: status,
        reviewNote: reviewNote,
      ));
    }

    void addArchive(String id, String courseId, String summary, List<String> memberNames, int completedDaysAgo, int archivedDaysAgo) {
      final a = assignments.firstWhere((e) => e.id == id);
      final c = courses.firstWhere((e) => e.id == courseId);
      archives.add(ArchiveModel(
        id: 'ar-$id',
        assignmentId: id,
        title: a.title,
        courseName: c.name,
        semester: c.semester,
        academicYear: c.academicYear,
        mode: a.mode,
        assignedDate: a.assignedDate,
        deadline: a.deadline,
        completedAt: at(completedDaysAgo),
        archivedAt: at(archivedDaysAgo),
        memberNames: memberNames,
        templateTitle: a.templateTitle,
        summary: summary,
        history: [
          ArchiveEvent(date: a.createdAt, text: 'Penugasan dibuat'),
          ArchiveEvent(date: at(completedDaysAgo + 3), text: 'Seluruh pekerjaan selesai'),
          ArchiveEvent(date: at(completedDaysAgo), text: 'Finalisasi dikonfirmasi, penugasan selesai'),
          ArchiveEvent(date: at(archivedDaysAgo), text: 'Dipindahkan ke Arsip'),
        ],
      ));
    }

    // ------------------------------------------------------ a1: individu, aktif

    addAssignment(
      id: 'a1',
      title: 'Aplikasi CollabNote (UTS)',
      courseId: 'c1',
      description: 'Bangun aplikasi mobile Flutter yang menarik, unik, dan memiliki arsitektur berlapis '
          '(View, ViewModel, Repository, Service). Kumpulkan source code dan dokumentasi singkat.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.tinggi,
      deadlineDays: 2,
      status: AssignmentStatus.sedangDikerjakan,
      createdDaysAgo: 12,
      updatedDaysAgo: 0,
      assignedDaysAgo: 12,
      templateId: 'it_srs',
    );
    addSteps('a1', [
      'Membaca instruksi UTS',
      'Menentukan ide dan fitur aplikasi',
      'Merancang desain UI/UX',
      'Menyusun arsitektur berlapis',
      'Implementasi fitur Flutter',
      'Pengujian dan dokumentasi',
    ], 3);
    addNote('a1', 1, 'Ide utama aplikasi', 'Aplikasi pengelola penugasan dan arsip akademik dengan dua mode: individu dan kelompok.');
    addNote('a1', 2, 'Hal yang perlu diperbaiki', 'Rapikan tampilan kartu penugasan dan pastikan progres terhubung ke Beranda.');
    addRef('a1', 1, 'Flutter: Architecture guidelines', 'https://docs.flutter.dev/app-architecture', ReferenceType.dokumentasi, note: 'Panduan resmi arsitektur berlapis.');
    addRef('a1', 2, 'Provider package', 'https://pub.dev/packages/provider', ReferenceType.dokumentasi);
    addRef('a1', 3, 'Material 3 Design', 'https://m3.material.io', ReferenceType.website);
    addTemplateDoc('a1', 'it_srs');
    addTextDoc('a1', 'cat', 'Catatan Rancangan',
        '# Catatan Rancangan CollabNote\n\n- Lapisan UI: View + ViewModel\n- Lapisan data: Repository + Service\n- Penyimpanan: Local Storage (JSON)\n', DocumentKind.draft);

    // ---------------------------------------------------- a2: kelompok, aktif

    addAssignment(
      id: 'a2',
      title: 'Presentasi Bisnis Startup',
      courseId: 'c4',
      description: 'Analisis studi kasus perusahaan rintisan dan presentasikan model bisnisnya. '
          'Sertakan Business Model Canvas, analisis kompetitor, dan proyeksi keuangan.',
      mode: AssignmentMode.kelompok,
      priority: AssignmentPriority.tinggi,
      deadlineDays: 5,
      status: AssignmentStatus.sedangDikerjakan,
      createdDaysAgo: 10,
      updatedDaysAgo: 1,
      assignedDaysAgo: 10,
      templateId: 'bz_bmc',
      groupId: 'g-a2',
    );
    addGroup('a2', 'Tim Wirausaha Muda', 'XF39L', [
      ['Andi Pratama', true, true, false],
      ['Budi Santoso', false, false, false],
      ['Citra Lestari', false, false, false],
      ['Dina Maharani', false, false, true],
    ]);
    addItem('a2', 1, 'Analisis Kompetitor', 'Riset mendalam terhadap lima kompetitor utama: produk, harga, dan strategi pemasaran.', 1, 3, WorkStatus.inProgress);
    addItem('a2', 2, 'Riset Pasar', 'Survei singkat kepada calon pelanggan dan ringkasan temuan.', 2, -1, WorkStatus.done);
    addItem('a2', 3, 'Model Bisnis Canvas', 'Isi sembilan blok Business Model Canvas.', 3, 2, WorkStatus.review);
    addItem('a2', 4, 'Proyeksi Keuangan', 'Proyeksi pendapatan dan biaya tiga bulan pertama.', 2, 4, WorkStatus.todo);
    addItem('a2', 5, 'Desain Slide', 'Susun slide presentasi sesuai gaya visual kelompok.', 3, 4, WorkStatus.inProgress);
    addItem('a2', 6, 'Naskah Presentasi', 'Tulis naskah presentasi 10 menit.', 1, 4, WorkStatus.todo);
    addItem('a2', 7, 'Struktur Presentasi', 'Tentukan alur dan pembagian bicara.', 1, -2, WorkStatus.done);
    addItem('a2', 8, 'Analisis SWOT', 'Ringkas kekuatan, kelemahan, peluang, dan ancaman.', 3, 3, WorkStatus.todo);
    addSub('a2', 1, 1, 'Kompetitor_V1.pdf', 'Draft awal analisis kompetitor.', ReviewStatus.revision, 'Tambahkan data kompetitor lokal.');
    addSub('a2', 2, 2, 'Riset_Pasar_Final.pdf', 'Hasil survei 30 responden.', ReviewStatus.approved, 'Sudah lengkap.');
    addSub('a2', 3, 3, 'BMC_Draft.pptx', 'Draft BMC versi pertama.', ReviewStatus.pending, '');
    addSub('a2', 7, 1, 'Struktur_Presentasi.docx', 'Alur presentasi.', ReviewStatus.approved, 'Disetujui.');
    addNote('a2', 1, 'Pembagian bicara', 'Andi: pembuka dan model bisnis. Budi: pasar. Citra: keuangan dan penutup.', author: 'Andi Pratama');
    addNote('a2', 2, 'Ide nama produk', 'Tiga kandidat nama produk akan divoting di pertemuan berikutnya.', author: 'Citra Lestari');
    addRef('a2', 1, 'Business Model Generation', 'https://www.strategyzer.com/library', ReferenceType.buku);
    addRef('a2', 2, 'Laporan industri startup', 'https://example.com/laporan-startup', ReferenceType.website);
    addTemplateDoc('a2', 'bz_bmc');
    addTextDoc('a2', 'out', 'Outline Presentasi', '# Outline\n\n1. Masalah\n2. Solusi\n3. Model bisnis\n4. Proyeksi keuangan\n', DocumentKind.draft);

    // ------------------------------------------- a3: individu, selesai (belum arsip)

    addAssignment(
      id: 'a3',
      title: 'Review Jurnal Statistika',
      courseId: 'c5',
      description: 'Review dua jurnal tentang analisis regresi dan tulis ringkasan satu halaman.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.sedang,
      deadlineDays: 7,
      status: AssignmentStatus.selesai,
      createdDaysAgo: 14,
      updatedDaysAgo: 1,
      assignedDaysAgo: 14,
      templateId: 'ac_makalah',
      completedDaysAgo: 1,
      summary: 'Dua jurnal regresi dibandingkan dari sisi metode dan hasil. Ringkasan satu halaman telah dikumpulkan.',
    );
    addSteps('a3', ['Membaca instruksi', 'Membaca dua jurnal', 'Menulis ringkasan', 'Merevisi dan mengumpulkan'], 4);
    addNote('a3', 1, 'Temuan utama', 'Jurnal pertama memakai regresi linear berganda, jurnal kedua regresi logistik.');
    addRef('a3', 1, 'Jurnal Regresi Linear', 'https://example.com/jurnal-regresi', ReferenceType.jurnal);
    addRef('a3', 2, 'Jurnal Regresi Logistik', 'https://example.com/jurnal-logistik', ReferenceType.jurnal);
    addRef('a3', 3, 'Buku Statistika Dasar', 'https://example.com/buku-statistika', ReferenceType.buku);
    addTextDoc('a3', 'final', 'Review Jurnal Final', '# Review Jurnal\n\nRingkasan perbandingan dua jurnal regresi.\n', DocumentKind.finalDoc, daysAgo: 1);

    // -------------------------------- a4: kelompok, menunggu pemeriksaan (anggota)

    addAssignment(
      id: 'a4',
      title: 'Analisis Klasifikasi Diabetes',
      courseId: 'c2',
      description: 'Bangun model klasifikasi diabetes dari dataset publik, bandingkan minimal dua algoritma, dan tulis laporan.',
      mode: AssignmentMode.kelompok,
      priority: AssignmentPriority.sedang,
      deadlineDays: 9,
      status: AssignmentStatus.menungguPemeriksaan,
      createdDaysAgo: 9,
      updatedDaysAgo: 2,
      assignedDaysAgo: 9,
      templateId: 'ac_penelitian',
      groupId: 'g-a4',
    );
    addGroup('a4', 'Tim ML Diabetes', 'K7M2P', [
      ['Rafi Ahmad', true, false, false],
      ['Andi Pratama', false, true, false],
      ['Sari Wulandari', false, false, false],
    ]);
    addItem('a4', 1, 'Pengumpulan Dataset', 'Unduh dan bersihkan dataset Pima Indians Diabetes.', 3, -3, WorkStatus.done);
    addItem('a4', 2, 'Preprocessing Data', 'Tangani nilai kosong dan lakukan normalisasi.', 2, -1, WorkStatus.done);
    addItem('a4', 3, 'Pelatihan Model', 'Latih Decision Tree dan Random Forest.', 1, 3, WorkStatus.review);
    addItem('a4', 4, 'Evaluasi Model', 'Hitung akurasi, presisi, dan recall.', 2, 4, WorkStatus.review);
    addItem('a4', 5, 'Penyusunan Laporan', 'Susun laporan penelitian lima bab.', 3, 6, WorkStatus.review);
    addSub('a4', 3, 1, 'Pelatihan_Model.ipynb', 'Notebook pelatihan model.', ReviewStatus.pending, '');
    addSub('a4', 4, 2, 'Evaluasi_Model.pdf', 'Tabel evaluasi dua model.', ReviewStatus.pending, '');
    addSub('a4', 5, 3, 'Draft_Laporan.docx', 'Draft laporan bab 1 sampai 3.', ReviewStatus.pending, '');
    addNote('a4', 1, 'Catatan metode', 'Gunakan pembagian data 80:20 dan validasi silang 5 lipat.', author: 'Rafi Ahmad');
    addRef('a4', 1, 'Dataset Pima Indians Diabetes', 'https://www.kaggle.com/datasets/uciml/pima-indians-diabetes-database', ReferenceType.website);
    addTemplateDoc('a4', 'ac_penelitian');

    // ---------------------------------------------- a5: individu, terlambat

    addAssignment(
      id: 'a5',
      title: 'Pemetaan Kepadatan Penduduk',
      courseId: 'c3',
      description: 'Buat peta tematik kepadatan penduduk kecamatan menggunakan QGIS beserta legenda dan interpretasi.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.sedang,
      deadlineDays: -2,
      status: AssignmentStatus.sedangDikerjakan,
      createdDaysAgo: 15,
      updatedDaysAgo: 4,
      assignedDaysAgo: 15,
    );
    addSteps('a5', ['Mengunduh data batas wilayah', 'Menggabungkan data penduduk', 'Membuat peta tematik', 'Menyusun legenda', 'Menulis interpretasi'], 1);
    addNote('a5', 1, 'Sumber data', 'Data penduduk dari BPS, batas wilayah dari Geoportal.');
    addRef('a5', 1, 'Dokumentasi QGIS', 'https://docs.qgis.org', ReferenceType.dokumentasi);

    // ------------------------------------------------- a6: individu, belum dimulai

    addAssignment(
      id: 'a6',
      title: 'Proposal Penelitian Skripsi',
      courseId: 'c2',
      description: 'Susun proposal penelitian awal: latar belakang, rumusan masalah, tujuan, dan metode.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.rendah,
      deadlineDays: 21,
      status: AssignmentStatus.belumDimulai,
      createdDaysAgo: 3,
      updatedDaysAgo: 3,
      assignedDaysAgo: 3,
      templateId: 'ac_proposal',
    );
    addSteps('a6', ['Membaca instruksi', 'Menentukan topik', 'Mengumpulkan referensi', 'Menyusun draft proposal', 'Revisi', 'Hasil akhir'], 0);
    addTemplateDoc('a6', 'ac_proposal');

    // --------------------------------------------------------- Arsip (5 penugasan)

    addAssignment(
      id: 'a7',
      title: 'Analisis Regresi Linear',
      courseId: 'c5',
      description: 'Analisis hubungan jam belajar dan nilai ujian dengan regresi linear sederhana.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.sedang,
      deadlineDays: -150,
      status: AssignmentStatus.diarsipkan,
      createdDaysAgo: 170,
      updatedDaysAgo: 152,
      assignedDaysAgo: 170,
      templateId: 'ac_praktikum',
      completedDaysAgo: 153,
      archivedDaysAgo: 152,
      summary: 'Model regresi linear sederhana menunjukkan hubungan positif antara jam belajar dan nilai ujian (R kuadrat 0,72).',
    );
    addSteps('a7', ['Mengumpulkan data', 'Menghitung regresi', 'Menulis laporan'], 3);
    addNote('a7', 1, 'Rumus', 'y = a + bx, parameter dihitung dengan metode kuadrat terkecil.');
    addRef('a7', 1, 'Modul Statistika', 'https://example.com/modul-statistika', ReferenceType.materi);
    addRef('a7', 2, 'Regresi Linear Sederhana', 'https://example.com/regresi', ReferenceType.website);
    addTextDoc('a7', 'final', 'Laporan Regresi Linear', '# Laporan Regresi Linear\n\nHasil analisis dan interpretasi.\n', DocumentKind.finalDoc, daysAgo: 153);
    addArchive('a7', 'c5', 'Model regresi linear sederhana menunjukkan hubungan positif antara jam belajar dan nilai ujian (R kuadrat 0,72).', [], 153, 152);

    addAssignment(
      id: 'a8',
      title: 'Perancangan ERD Toko Online',
      courseId: 'c6',
      description: 'Rancang ERD dan skema basis data untuk toko online beserta normalisasi sampai 3NF.',
      mode: AssignmentMode.kelompok,
      priority: AssignmentPriority.tinggi,
      deadlineDays: -140,
      status: AssignmentStatus.diarsipkan,
      createdDaysAgo: 165,
      updatedDaysAgo: 142,
      assignedDaysAgo: 165,
      templateId: 'it_erd',
      completedDaysAgo: 143,
      archivedDaysAgo: 142,
      groupId: 'g-a8',
      summary: 'ERD toko online berisi 8 entitas dan telah dinormalisasi sampai 3NF.',
    );
    addGroup('a8', 'Tim Basis Data', 'B8D45', [
      ['Andi Pratama', true, true, false],
      ['Eko Prasetyo', false, false, false],
      ['Fitri Anggraini', false, false, false],
    ]);
    addItem('a8', 1, 'Identifikasi Entitas', 'Tentukan entitas dan atribut.', 2, -155, WorkStatus.done);
    addItem('a8', 2, 'Gambar ERD', 'Gambar diagram ERD lengkap.', 3, -150, WorkStatus.done);
    addItem('a8', 3, 'Normalisasi', 'Normalisasi sampai 3NF.', 1, -145, WorkStatus.done);
    addSub('a8', 2, 3, 'ERD_Toko_Online.png', 'Diagram ERD final.', ReviewStatus.approved, 'Sudah sesuai.');
    addNote('a8', 1, 'Aturan relasi', 'Satu pelanggan dapat memiliki banyak pesanan.', author: 'Eko Prasetyo');
    addRef('a8', 1, 'Normalisasi Basis Data', 'https://example.com/normalisasi', ReferenceType.materi);
    addTextDoc('a8', 'final', 'Dokumen ERD Toko Online', '# Dokumen ERD\n\nDaftar entitas, atribut, dan relasi.\n', DocumentKind.finalDoc, daysAgo: 143);
    addArchive('a8', 'c6', 'ERD toko online berisi 8 entitas dan telah dinormalisasi sampai 3NF.', ['Andi Pratama', 'Eko Prasetyo', 'Fitri Anggraini'], 143, 142);

    addAssignment(
      id: 'a9',
      title: 'Evaluasi Heuristik Aplikasi',
      courseId: 'c7',
      description: 'Evaluasi antarmuka sebuah aplikasi menggunakan sepuluh heuristik Nielsen.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.sedang,
      deadlineDays: -120,
      status: AssignmentStatus.diarsipkan,
      createdDaysAgo: 140,
      updatedDaysAgo: 122,
      assignedDaysAgo: 140,
      completedDaysAgo: 123,
      archivedDaysAgo: 122,
      summary: 'Ditemukan 12 masalah usability, tiga di antaranya berkeparahan tinggi.',
    );
    addSteps('a9', ['Memilih aplikasi', 'Mengevaluasi heuristik', 'Menyusun rekomendasi'], 3);
    addNote('a9', 1, 'Temuan', 'Umpan balik sistem kurang jelas pada proses unggah.');
    addNote('a9', 2, 'Rekomendasi', 'Tambahkan indikator progres dan pesan sukses.');
    addRef('a9', 1, '10 Usability Heuristics', 'https://www.nngroup.com/articles/ten-usability-heuristics', ReferenceType.website);
    addTextDoc('a9', 'final', 'Laporan Evaluasi Heuristik', '# Laporan Evaluasi\n\nDaftar temuan dan rekomendasi.\n', DocumentKind.finalDoc, daysAgo: 123);
    addArchive('a9', 'c7', 'Ditemukan 12 masalah usability, tiga di antaranya berkeparahan tinggi.', [], 123, 122);

    addAssignment(
      id: 'a10',
      title: 'Studi Kelayakan Bisnis',
      courseId: 'c4',
      description: 'Susun studi kelayakan usaha kuliner kecil: pasar, teknis, dan keuangan.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.tinggi,
      deadlineDays: -25,
      status: AssignmentStatus.diarsipkan,
      createdDaysAgo: 50,
      updatedDaysAgo: 21,
      assignedDaysAgo: 50,
      templateId: 'bz_plan',
      completedDaysAgo: 22,
      archivedDaysAgo: 21,
      summary: 'Usaha dinyatakan layak dengan estimasi balik modal 9 bulan.',
    );
    addSteps('a10', ['Analisis pasar', 'Analisis teknis', 'Analisis keuangan', 'Kesimpulan'], 4);
    addNote('a10', 1, 'Asumsi keuangan', 'Modal awal 15 juta rupiah, margin 40 persen.');
    addRef('a10', 1, 'Panduan Studi Kelayakan', 'https://example.com/studi-kelayakan', ReferenceType.materi);
    addRef('a10', 2, 'Data pasar kuliner', 'https://example.com/pasar-kuliner', ReferenceType.website);
    addTextDoc('a10', 'final', 'Studi Kelayakan Final', '# Studi Kelayakan\n\nUsaha layak dijalankan.\n', DocumentKind.finalDoc, daysAgo: 22);
    addArchive('a10', 'c4', 'Usaha dinyatakan layak dengan estimasi balik modal 9 bulan.', [], 22, 21);

    addAssignment(
      id: 'a11',
      title: 'Laporan Praktikum Jaringan',
      courseId: 'c8',
      description: 'Laporan praktikum konfigurasi subnetting dan routing statis.',
      mode: AssignmentMode.individu,
      priority: AssignmentPriority.rendah,
      deadlineDays: -300,
      status: AssignmentStatus.diarsipkan,
      createdDaysAgo: 330,
      updatedDaysAgo: 302,
      assignedDaysAgo: 330,
      templateId: 'ac_praktikum',
      completedDaysAgo: 303,
      archivedDaysAgo: 302,
      summary: 'Konfigurasi subnetting dan routing statis berhasil diuji dengan ping antar-subnet.',
    );
    addSteps('a11', ['Menyiapkan topologi', 'Konfigurasi routing', 'Menulis laporan'], 3);
    addNote('a11', 1, 'Tabel subnet', 'Gunakan 192.168.10.0/26 untuk jaringan A.');
    addRef('a11', 1, 'Modul Jaringan Komputer', 'https://example.com/modul-jarkom', ReferenceType.materi);
    addTextDoc('a11', 'final', 'Laporan Praktikum Jaringan', '# Laporan Praktikum\n\nHasil pengujian konfigurasi.\n', DocumentKind.finalDoc, daysAgo: 303);
    addArchive('a11', 'c8', 'Konfigurasi subnetting dan routing statis berhasil diuji dengan ping antar-subnet.', [], 303, 302);

    List<Map<String, dynamic>> js<T>(List<T> list, Map<String, dynamic> Function(T) f) => list.map(f).toList();

    return {
      'user': [user.toJson()],
      'courses': js(courses, (e) => e.toJson()),
      'assignments': js(assignments, (e) => e.toJson()),
      'workspaces': js(workspaces, (e) => e.toJson()),
      'steps': js(steps, (e) => e.toJson()),
      'notes': js(notes, (e) => e.toJson()),
      'documents': js(docs, (e) => e.toJson()),
      'references': js(refs, (e) => e.toJson()),
      'groups': js(groups, (e) => e.toJson()),
      'members': js(members, (e) => e.toJson()),
      'workItems': js(items, (e) => e.toJson()),
      'submissions': js(subs, (e) => e.toJson()),
      'archives': js(archives, (e) => e.toJson()),
      'customTemplates': <Map<String, dynamic>>[],
      'templatePrefs': [
        {'favorites': ['it_srs', 'bz_bmc'], 'recent': ['it_srs']}
      ],
    };
  }
}
