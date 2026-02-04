import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isUploading = false;

  void _sendComment() {
    if (_commentController.text.trim().isEmpty) return;

    final user = Provider.of<TaskProvider>(context, listen: false).userData;
    final currentUser = FirebaseAuth.instance.currentUser;

    final newComment = CommentModel(
      id: '',
      senderName: user?['email'] ?? currentUser?.email ?? 'Usuario',
      senderId: user?['uid'] ?? currentUser?.uid ?? '',
      message: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    DatabaseService().addComment(widget.task.id, newComment);
    _commentController.clear();
  }

  // Función para ver la imagen en pantalla completa con ZOOM
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(
                      color: Colors.greenAccent,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);

      String? imageUrl = await CloudinaryService().uploadImage(pickedFile);

      if (!mounted) return;

      if (imageUrl != null) {
        await Provider.of<TaskProvider>(
          context,
          listen: false,
        ).addEvidencia(widget.task.id, imageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Evidencia subida correctamente")),
        );
      }
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<TaskProvider>(context);
    final currentUserId = userProvider.userData?['uid'];
    final bool isEmployee = userProvider.userData?['role'] == 'empleado';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info de la tarea + Sección de Evidencia
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Instrucciones:",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.task.description,
                  style: const TextStyle(color: Colors.white70),
                ),

                // Sección de Evidencia Optimizada
                if (widget.task.evidenciaUrl != null) ...[
                  const SizedBox(height: 15),
                  const Text(
                    "Evidencia (Toca para ampliar):",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        _showFullImage(context, widget.task.evidenciaUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            widget.task.evidenciaUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          const Icon(
                            Icons.fullscreen,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (isEmployee && widget.task.status != 'completada') ...[
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(
                        _isUploading ? "SUBIENDO..." : "SUBIR EVIDENCIA",
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de Comentarios
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: DatabaseService().getComments(widget.task.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    bool isMe = c.senderId == currentUserId;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.greenAccent.withOpacity(0.15)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: Radius.circular(isMe ? 15 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 15),
                          ),
                          border: Border.all(
                            color: isMe
                                ? Colors.greenAccent.withOpacity(0.3)
                                : Colors.white10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.senderName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input de Comentarios
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Escribe un comentario...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.greenAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0D1B2A)),
                    onPressed: _sendComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
