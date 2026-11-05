import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// 5. Assets & Links Hub (Pusat Tautan Proyek)
class AssetsLinksHubScreen extends StatelessWidget {
  final String projectId;
  const AssetsLinksHubScreen({super.key, required this.projectId});

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    // Menggunakan plugin url_launcher untuk membuka langsung di browser / aplikasi terkait
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('project_links')
          .stream(primaryKey: ['id'])
          .eq('project_id', projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final links = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final item = links[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF7C3AED),
                ),
                title: Text(item['title'] ?? 'Tautan'),
                subtitle: Text(
                  item['url'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _launchURL(item['url']),
              ),
            );
          },
        );
      },
    );
  }
}
