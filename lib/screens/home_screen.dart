import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargamos los datos del usuario (rol) al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadUser(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final user = provider.userData;

    // Pantalla de carga mientras obtenemos el rol de Firestore
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Definimos si es jefe para aplicar estilos
    final bool isJefe = user.role == 'jefe';

    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de ${user.role.toUpperCase()}'),
        backgroundColor: isJefe
            ? Colors.indigo
            : Colors.teal, // Color distintivo por rol
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Optimización para Web
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Conectado como: ${user.email}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Formulario para añadir tareas
              _buildTaskInput(provider),
              const SizedBox(height: 10),
              const Divider(),

              // Lista de tareas en tiempo real
              Expanded(
                child: StreamBuilder(
                  stream: provider.tasksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No hay tareas registradas.'),
                      );
                    }

                    final tasks = snapshot.data!;
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          TaskTile(task: tasks[index]),
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

  // Widget para el campo de entrada de texto
  Widget _buildTaskInput(TaskProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Escribe una nueva tarea...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _handleAddTask(provider),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.add_circle),
          iconSize: 40,
          color: provider.userData?.role == 'jefe'
              ? Colors.indigo
              : Colors.teal,
          onPressed: () => _handleAddTask(provider),
        ),
      ],
    );
  }

  // Lógica para limpiar el controlador al agregar
  void _handleAddTask(TaskProvider provider) {
    if (_controller.text.isNotEmpty) {
      provider.addTask(_controller.text);
      _controller.clear();
    }
  }
}
