import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../models/task_model.dart';

class HomeScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Portafolio - Task Manager')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Optimizado para Web
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nueva tarea...',
                      ),
                      onSubmitted: (val) => _addTask(provider),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTask(provider),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: provider.tasksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No hay tareas pendientes.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) =>
                          TaskTile(task: snapshot.data![index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTask(TaskProvider provider) {
    if (_controller.text.isNotEmpty) {
      provider.addTask(_controller.text);
      _controller.clear();
    }
  }
}
