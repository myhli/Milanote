import 'package:flutter/material.dart';
import '../../cards/models/base_card.dart';
import '../../cards/models/color_card.dart';
import '../../cards/models/connector_arrow.dart';
import '../../cards/models/image_card.dart';
import '../../cards/models/note_card.dart';

/// Data structure defining an artistic starter template designed for art students and visual creators.
class ArtisticTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String category;
  final String badge;
  final (List<BaseCard>, List<ConnectorArrow>) Function(String boardId) builder;

  const ArtisticTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.badge,
    required this.builder,
  });
}

/// Factory and repository of the 4 artistic starter templates (PRD US-002).
class ArtisticStarterTemplates {
  static final List<ArtisticTemplate> all = [
    _characterMoodboardTemplate,
    _styleAndColorStudyTemplate,
    _storyboard6PanelTemplate,
    _brainstormingTemplate,
  ];

  static ArtisticTemplate? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // 1. Moodboard Karakter
  static final ArtisticTemplate _characterMoodboardTemplate = ArtisticTemplate(
    id: 'character_moodboard',
    name: 'Moodboard Karakter',
    description:
        'Slot referensi pose anatomi, kostum, palet warna kulit & pakaian, serta catatan profil arketipe.',
    icon: Icons.person_rounded,
    category: 'Desain Karakter',
    badge: '5 Elemen',
    builder: (boardId) {
      final now = DateTime.now();
      final cards = <BaseCard>[
        NoteCard(
          id: '${boardId}_char_profile',
          x: 120,
          y: 100,
          width: 320,
          height: 260,
          zIndex: 1,
          title: '👤 Profil & Arketipe Karakter',
          content:
              'Nama: Lyra Vance\nArketipe: Penjelajah Kosmik & Teknisi Magis\nKepribadian: Teliti, berani, sedikit sinis\nSiluet Utama: Jubah panjang dengan sabuk perkakas berat.',
          colorHex: '#FEF9C3', // Warm yellow pastel
          createdAt: now,
          updatedAt: now,
        ),
        NoteCard(
          id: '${boardId}_char_checklist',
          x: 120,
          y: 390,
          width: 320,
          height: 220,
          zIndex: 2,
          title: '🎒 Perlengkapan & Kostum',
          content: '',
          colorHex: '#F0FDF4', // Green pastel
          checklists: const [
            ChecklistItem(id: 'c1', text: 'Sketsa siluet 3 pose utama', isDone: true),
            ChecklistItem(id: 'c2', text: 'Tentukan tekstur jubah & pelindung bahu', isDone: true),
            ChecklistItem(id: 'c3', text: 'Desain senjata / alat navigasi tangan', isDone: false),
            ChecklistItem(id: 'c4', text: 'Uji palet warna pada pencahayaan malam', isDone: false),
          ],
          isChecklistMode: true,
          createdAt: now,
          updatedAt: now,
        ),
        ColorCard(
          id: '${boardId}_char_colors',
          x: 480,
          y: 100,
          width: 340,
          height: 140,
          zIndex: 3,
          title: 'Palet Kulit & Kostum',
          colorsHex: const ['#F5D0C5', '#2B3A42', '#BD5338', '#EFA94A', '#7D8A88'],
          createdAt: now,
          updatedAt: now,
        ),
        ImageCard(
          id: '${boardId}_char_pose_ref',
          x: 480,
          y: 270,
          width: 340,
          height: 220,
          zIndex: 4,
          assetUuid: '',
          caption: 'Referensi Pose & Anatomi Tubuh',
          createdAt: now,
          updatedAt: now,
        ),
        ImageCard(
          id: '${boardId}_char_prop_ref',
          x: 480,
          y: 520,
          width: 340,
          height: 200,
          zIndex: 5,
          assetUuid: '',
          caption: 'Detail Senjata & Aksesoris Tangan',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final arrows = <ConnectorArrow>[
        ConnectorArrow(
          id: '${boardId}_arr_profile_to_color',
          startCardId: '${boardId}_char_profile',
          endCardId: '${boardId}_char_colors',
          startAnchor: CardAnchor.right,
          endAnchor: CardAnchor.left,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#BD5338',
        ),
        ConnectorArrow(
          id: '${boardId}_arr_checklist_to_prop',
          startCardId: '${boardId}_char_checklist',
          endCardId: '${boardId}_char_prop_ref',
          startAnchor: CardAnchor.right,
          endAnchor: CardAnchor.left,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.0,
          colorHex: '#7D8A88',
        ),
      ];

      return (cards, arrows);
    },
  );

  // 2. Studi Gaya & Warna
  static final ArtisticTemplate _styleAndColorStudyTemplate = ArtisticTemplate(
    id: 'style_and_color_study',
    name: 'Studi Gaya & Warna',
    description:
        'Susun arah estetika, referensi pencahayaan, material tekstur, serta 8 swatch warna harmoni.',
    icon: Icons.palette_rounded,
    category: 'Eksplorasi Gaya',
    badge: '5 Elemen',
    builder: (boardId) {
      final now = DateTime.now();
      final cards = <BaseCard>[
        NoteCard(
          id: '${boardId}_style_concept',
          x: 100,
          y: 100,
          width: 340,
          height: 200,
          zIndex: 1,
          title: '✨ Arah Estetika & Konsep Gaya',
          content:
              'Gaya Visual: Neo-Noir Retro-Futurism\nSuasana: Gelap temaram dengan aksen neon berpendar lembut.\nInspirasi: Poster film fiksi ilmiah 80-an dengan grain film analog.',
          colorHex: '#EFF6FF', // Blue pastel
          createdAt: now,
          updatedAt: now,
        ),
        ColorCard(
          id: '${boardId}_style_swatches',
          x: 480,
          y: 100,
          width: 480,
          height: 140,
          zIndex: 2,
          title: 'Palet Warna Harmoni (8 Swatch)',
          colorsHex: const [
            '#0F172A',
            '#1E293B',
            '#334155',
            '#06B6D4',
            '#3B82F6',
            '#8B5CF6',
            '#EC4899',
            '#F43F5E'
          ],
          createdAt: now,
          updatedAt: now,
        ),
        ImageCard(
          id: '${boardId}_style_light_ref',
          x: 100,
          y: 330,
          width: 340,
          height: 250,
          zIndex: 3,
          assetUuid: '',
          caption: 'Referensi Pencahayaan & Rim Light',
          createdAt: now,
          updatedAt: now,
        ),
        ImageCard(
          id: '${boardId}_style_texture_ref',
          x: 480,
          y: 270,
          width: 340,
          height: 250,
          zIndex: 4,
          assetUuid: '',
          caption: 'Referensi Material Logam & Kaca Retak',
          createdAt: now,
          updatedAt: now,
        ),
        NoteCard(
          id: '${boardId}_style_typography',
          x: 850,
          y: 270,
          width: 300,
          height: 230,
          zIndex: 5,
          title: '🔤 Catatan Tipografi & Bentuk',
          content:
              'Font Utama: Sans-Serif Geometris tegas\nBentuk Geometri: Sudut tajam 45 derajat berpadu kurva mulus\nEfek Finishing: Chromatic aberration halus di tepi objek.',
          colorHex: '#FDF4FF', // Lavender pastel
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final arrows = <ConnectorArrow>[
        ConnectorArrow(
          id: '${boardId}_arr_style_to_swatches',
          startCardId: '${boardId}_style_concept',
          endCardId: '${boardId}_style_swatches',
          startAnchor: CardAnchor.right,
          endAnchor: CardAnchor.left,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#3B82F6',
        ),
      ];

      return (cards, arrows);
    },
  );

  // 3. Storyboard 6-Panel
  static final ArtisticTemplate _storyboard6PanelTemplate = ArtisticTemplate(
    id: 'storyboard_6_panel',
    name: 'Storyboard 6-Panel',
    description:
        'Alur sekuensial 6 bingkai adegan lengkap dengan kotak deskripsi aksi, jenis shot, dan dialog.',
    icon: Icons.movie_creation_rounded,
    category: 'Animasi & Komik',
    badge: '12 Elemen',
    builder: (boardId) {
      final now = DateTime.now();
      final cards = <BaseCard>[];
      final arrows = <ConnectorArrow>[];

      final shots = [
        ('Shot 1: Extreme Wide', 'Kota berkabut di fajar hari. Pesawat kecil mendekat.', '#FEF9C3'),
        ('Shot 2: Medium Shot', 'Karakter utama keluar dari kokpit menatap kompas tua.', '#F0FDF4'),
        ('Shot 3: Close-Up', 'Reaksi wajah terkejut saat sinyal misterius menyala.', '#EFF6FF'),
        ('Shot 4: Over-Shoulder', 'Sosok bayangan tinggi muncul di ambang pintu reruntuhan.', '#FFF1F2'),
        ('Shot 5: Action Wide', 'Ledakan cahaya biru saat kunci relik diaktifkan.', '#FDF4FF'),
        ('Shot 6: Final Shot', 'Kamera menjauh memperlihatkan kota kuno mulai bangkit.', '#F8FAFC'),
      ];

      for (int i = 0; i < 6; i++) {
        final row = i < 3 ? 0 : 1;
        final col = i % 3;
        final posX = 80.0 + col * 360.0;
        final posY = 80.0 + row * 430.0;

        final imageId = '${boardId}_sb_frame_${i + 1}';
        final noteId = '${boardId}_sb_desc_${i + 1}';

        cards.add(ImageCard(
          id: imageId,
          x: posX,
          y: posY,
          width: 320,
          height: 190,
          zIndex: (i * 2) + 1,
          assetUuid: '',
          caption: 'Panel ${i + 1}: ${shots[i].$1}',
          createdAt: now,
          updatedAt: now,
        ));

        cards.add(NoteCard(
          id: noteId,
          x: posX,
          y: posY + 205,
          width: 320,
          height: 150,
          zIndex: (i * 2) + 2,
          title: shots[i].$1,
          content: 'Aksi: ${shots[i].$2}\nDialog: "..."\nKamera: Pan perlahan mengikuti arah gerak.',
          colorHex: shots[i].$3,
          createdAt: now,
          updatedAt: now,
        ));

        if (i < 5) {
          // Connect consecutive frame notes
          final nextNoteId = '${boardId}_sb_desc_${i + 2}';
          arrows.add(ConnectorArrow(
            id: '${boardId}_arr_sb_${i + 1}_to_${i + 2}',
            startCardId: noteId,
            endCardId: nextNoteId,
            startAnchor: (i % 3 == 2) ? CardAnchor.bottom : CardAnchor.right,
            endAnchor: (i % 3 == 2) ? CardAnchor.top : CardAnchor.left,
            style: ArrowStyle.curved,
            head: ArrowHead.end,
            strokeWidth: 2.0,
            colorHex: '#94A3B8',
          ));
        }
      }

      return (cards, arrows);
    },
  );

  // 4. Brainstorming Proyek
  static final ArtisticTemplate _brainstormingTemplate = ArtisticTemplate(
    id: 'brainstorming_project',
    name: 'Brainstorming Proyek',
    description:
        'Pusat ide konseptual dengan cabang panah melengkung ke premis, dunia, audiens, dan batas visual.',
    icon: Icons.hub_rounded,
    category: 'Perencanaan Seni',
    badge: '6 Elemen',
    builder: (boardId) {
      final now = DateTime.now();
      const centerId = 'bs_center';
      const branchPremise = 'bs_branch_premise';
      const branchWorld = 'bs_branch_world';
      const branchAudience = 'bs_branch_audience';
      const branchLimits = 'bs_branch_limits';
      const colorsId = 'bs_palette';

      final cards = <BaseCard>[
        // Central Core Concept
        NoteCard(
          id: '${boardId}_$centerId',
          x: 480,
          y: 260,
          width: 300,
          height: 180,
          zIndex: 10,
          title: '🌟 Konsep Utama & Tema Besar',
          content:
              'Apa pesan inti karya ini?\nTema: Kerapuhan waktu & ingatan yang memudar.\nKata Kunci: Jam pasir, lumut, relik kuno, keheningan.',
          colorHex: '#FEF9C3', // Yellow
          createdAt: now,
          updatedAt: now,
        ),
        // Branch 1: Premis (Top Left)
        NoteCard(
          id: '${boardId}_$branchPremise',
          x: 100,
          y: 80,
          width: 280,
          height: 170,
          zIndex: 2,
          title: '🎭 Premis & Narasi',
          content:
              'Siapa tokoh utama?\nKonflik apa yang dihadapi?\nBagaimana klimaks emosional diselesaikan?',
          colorHex: '#EFF6FF', // Blue
          createdAt: now,
          updatedAt: now,
        ),
        // Branch 2: Latar Dunia (Top Right)
        NoteCard(
          id: '${boardId}_$branchWorld',
          x: 880,
          y: 80,
          width: 280,
          height: 170,
          zIndex: 3,
          title: '🌍 Latar Dunia & Nuansa',
          content:
              'Di mana peristiwa berlangsung?\nArsitektur apa yang dominan?\nBagaimana kondisi cuaca dan pencahayaannya?',
          colorHex: '#F0FDF4', // Green
          createdAt: now,
          updatedAt: now,
        ),
        // Branch 3: Audiens (Bottom Left)
        NoteCard(
          id: '${boardId}_$branchAudience',
          x: 100,
          y: 460,
          width: 280,
          height: 170,
          zIndex: 4,
          title: '👥 Target Audiens & Emosi',
          content:
              'Siapa yang ingin disentuh oleh karya ini?\nEmosi apa yang ingin dibangkitkan saat pertama melihatnya?',
          colorHex: '#FFF1F2', // Rose
          createdAt: now,
          updatedAt: now,
        ),
        // Branch 4: Batasan Visual (Bottom Right)
        NoteCard(
          id: '${boardId}_$branchLimits',
          x: 880,
          y: 460,
          width: 280,
          height: 170,
          zIndex: 5,
          title: '📐 Batasan Visual & Media',
          content:
              'Format: Poster vertikal 3:4\nPalet warna dibatasi 4 warna utama.\nFokus pada permainan siluet dan ruang negatif.',
          colorHex: '#FDF4FF', // Lavender
          createdAt: now,
          updatedAt: now,
        ),
        // Color Palette (Center Bottom)
        ColorCard(
          id: '${boardId}_$colorsId',
          x: 480,
          y: 480,
          width: 300,
          height: 140,
          zIndex: 6,
          title: 'Mood Emosional & Nada Visual',
          colorsHex: const ['#1E1B4B', '#4338CA', '#818CF8', '#C7D2FE'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final arrows = <ConnectorArrow>[
        ConnectorArrow(
          id: '${boardId}_arr_center_to_premise',
          startCardId: '${boardId}_$centerId',
          endCardId: '${boardId}_$branchPremise',
          startAnchor: CardAnchor.left,
          endAnchor: CardAnchor.right,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#3B82F6',
        ),
        ConnectorArrow(
          id: '${boardId}_arr_center_to_world',
          startCardId: '${boardId}_$centerId',
          endCardId: '${boardId}_$branchWorld',
          startAnchor: CardAnchor.right,
          endAnchor: CardAnchor.left,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#10B981',
        ),
        ConnectorArrow(
          id: '${boardId}_arr_center_to_audience',
          startCardId: '${boardId}_$centerId',
          endCardId: '${boardId}_$branchAudience',
          startAnchor: CardAnchor.left,
          endAnchor: CardAnchor.right,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#F43F5E',
        ),
        ConnectorArrow(
          id: '${boardId}_arr_center_to_limits',
          startCardId: '${boardId}_$centerId',
          endCardId: '${boardId}_$branchLimits',
          startAnchor: CardAnchor.right,
          endAnchor: CardAnchor.left,
          style: ArrowStyle.curved,
          head: ArrowHead.end,
          strokeWidth: 2.5,
          colorHex: '#A855F7',
        ),
      ];

      return (cards, arrows);
    },
  );
}
