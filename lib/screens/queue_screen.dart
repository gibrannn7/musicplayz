import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/queue_provider.dart';
import '../core/audio_handler.dart';
import '../providers/audio_state_provider.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueProvider);
    final currentItemAsync = ref.watch(currentMediaItemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
      ),
      body: queueAsync.when(
        data: (queue) {
          if (queue.isEmpty) {
            return const Center(child: Text('Queue is empty'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: queue.length,
            onReorder: (oldIndex, newIndex) {
              // Implementation of reorder logic would go here
              // For now we just show how it would look
            },
            itemBuilder: (context, index) {
              final item = queue[index];
              final isCurrent = currentItemAsync.value?.id == item.id;

              return Dismissible(
                key: ValueKey(item.id + index.toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  ref.read(audioHandlerProvider).removeQueueItemAt(index);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  key: ValueKey(item.id + index.toString()),
                  leading: Text('${index + 1}', style: const TextStyle(color: Colors.grey)),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(item.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.drag_handle),
                  onTap: () {
                    ref.read(audioHandlerProvider).skipToQueueItem(index);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
