import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'Todas';
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadUser(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final user = provider.userData;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Color> bgColors = user.role == 'jefe'
        ? [Colors.indigo.shade900, Colors.blue.shade800]
        : [Colors.teal.shade900, Colors.green.shade800];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Panel ${user.role.toUpperCase()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<List<TaskModel>>(
                  stream: provider.tasksStream,
                  builder: (context, snapshot) {
                    final allTasks = snapshot.data ?? [];
                    return Column(
                      children: [
                        _buildProgressHeader(allTasks),
                        _buildInputSection(provider, user.role),
                        const SizedBox(height: 15),
                        _buildSearchBar(),
                        const SizedBox(height: 15),
                        _buildFilterSection(),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white24),
                        Expanded(
                          child: _buildAnimatedTaskList(
                            allTasks,
                            snapshot.connectionState,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black26,
        hintText: 'Buscar por nombre...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildInputSection(TaskProvider provider, String role) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nueva tarea...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          // Botón de Calendario
          IconButton(
            icon: Icon(
              Icons.event,
              color: _selectedDate == null
                  ? Colors.white60
                  : Colors.greenAccent,
            ),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(width: 5),
          FloatingActionButton.small(
            backgroundColor: role == 'jefe' ? Colors.white : Colors.greenAccent,
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                provider.addTask(_taskController.text, dueDate: _selectedDate);
                _taskController.clear();
                setState(() => _selectedDate = null);
              }
            },
            child: Icon(
              Icons.add,
              color: role == 'jefe' ? Colors.indigo.shade900 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Todas', 'Pendientes', 'Hechas'].map((f) {
          bool isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (s) => setState(() => _filter = f),
              selectedColor: Colors.white,
              backgroundColor: Colors.black26,
              labelStyle: TextStyle(
                color: isSelected ? Colors.indigo.shade900 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressHeader(List<TaskModel> tasks) {
    final completed = tasks.where((t) => t.isDone).length;
    final total = tasks.length;
    final percent = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cumplimiento",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "${(percent * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTaskList(
    List<TaskModel> allTasks,
    ConnectionState state,
  ) {
    if (state == ConnectionState.waiting)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );

    var tasks = allTasks.where((t) {
      bool matchesFilter = true;
      if (_filter == 'Pendientes') matchesFilter = !t.isDone;
      if (_filter == 'Hechas') matchesFilter = t.isDone;
      bool matchesSearch = t.title.toLowerCase().contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: FadeInAnimation(
              child: ScaleAnimation(child: TaskTile(task: tasks[index])),
            ),
          );
        },
      ),
    );
  }
}
