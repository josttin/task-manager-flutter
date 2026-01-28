import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _filter = 'Todas';
  String _searchQuery = '';

  DateTime? _selectedDate;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadUser(widget.uid);
    });
  }

  void _showAddTaskSheet(TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF101820),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "NUEVA TAREA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 25),
                _buildModalField(
                  _titleController,
                  "Título de la tarea",
                  Icons.title,
                ),
                const SizedBox(height: 15),
                _buildModalField(
                  _descController,
                  "Instrucciones",
                  Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: _selectedDate == null
                            ? "Fecha"
                            : "${_selectedDate!.day}/${_selectedDate!.month}",
                        icon: Icons.calendar_month,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null)
                            setModalState(() => _selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildEmployeeDropdown(setModalState)),
                  ],
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_titleController.text.isEmpty ||
                        _selectedEmployeeId == null)
                      return;
                    provider.addTask(
                      title: _titleController.text,
                      description: _descController.text,
                      dueDate: _selectedDate ?? DateTime.now(),
                      assignedTo: _selectedEmployeeId!,
                      assignedToName: _selectedEmployeeName!,
                    );
                    _titleController.clear();
                    _descController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "GUARDAR TAREA",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final user = provider.userData;

    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final String role = user['role'] ?? 'empleado';
    final List<Color> bgColors = role == 'jefe'
        ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
        : [const Color(0xFF002117), const Color(0xFF004433)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'PANEL ${role.toUpperCase()}',
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
      floatingActionButton: role == 'jefe'
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTaskSheet(provider),
              backgroundColor: Colors.greenAccent,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                "Nueva Tarea",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<TaskModel>>(
                stream: provider.tasksStream,
                builder: (context, snapshot) {
                  final allTasks = snapshot.data ?? [];
                  return Column(
                    children: [
                      _buildProgressHeader(allTasks),
                      _buildSearchBar(),
                      const SizedBox(height: 15),
                      _buildFilterSection(role),
                      const Divider(color: Colors.white12, height: 30),
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
        ],
      ),
    );
  }

  Widget _buildFilterSection(String role) {
    // El jefe tiene el filtro de "Revisión" adicional
    List<String> filters = role == 'jefe'
        ? ['Todas', 'Pendientes', 'Revisión', 'Hechas']
        : ['Todas', 'Pendientes', 'Hechas'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((f) {
          bool isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (s) => setState(() => _filter = f),
              selectedColor: f == 'Revisión'
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
              backgroundColor: Colors.black45,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnimatedTaskList(
    List<TaskModel> allTasks,
    ConnectionState state,
  ) {
    if (state == ConnectionState.waiting)
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );

    var tasks = allTasks.where((t) {
      bool matchesSearch = t.title.toLowerCase().contains(_searchQuery);
      if (_filter == 'Todas') return matchesSearch;
      if (_filter == 'Pendientes')
        return matchesSearch && t.status == 'pendiente';
      if (_filter == 'Revisión') return matchesSearch && t.status == 'revision';
      if (_filter == 'Hechas') return matchesSearch && t.status == 'completada';
      return matchesSearch;
    }).toList();

    if (tasks.isEmpty)
      return const Center(
        child: Text(
          "No hay tareas aquí",
          style: TextStyle(color: Colors.white38),
        ),
      );

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: FadeInAnimation(
            child: ScaleAnimation(child: TaskTile(task: tasks[index])),
          ),
        ),
      ),
    );
  }

  // --- MANTENEMOS LOS DEMÁS WIDGETS AUXILIARES (SearchBar, Progress, ModalField, etc) ---
  Widget _buildModalField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown(Function setModalState) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getEmployees(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedEmployeeId,
              hint: const Text(
                "Para...",
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              dropdownColor: const Color(0xFF101820),
              items: snapshot.data
                  ?.map(
                    (e) => DropdownMenuItem(
                      value: e['uid'].toString(),
                      child: Text(
                        e['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => _selectedEmployeeName = e['name'],
                    ),
                  )
                  .toList(),
              onChanged: (v) => setModalState(() => _selectedEmployeeId = v),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar tareas...',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.greenAccent),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(List<TaskModel> tasks) {
    final completed = tasks.where((t) => t.status == 'completada').length;
    final total = tasks.length;
    final percent = total > 0 ? completed / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progreso General",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                "${(percent * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
